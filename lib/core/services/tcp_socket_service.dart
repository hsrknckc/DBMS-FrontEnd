import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════════════════
// TCP Bağlantı Durumu
// ═══════════════════════════════════════════════════════════════════════════

enum TcpConnectionState { disconnected, connecting, connected }

// ═══════════════════════════════════════════════════════════════════════════
// Sunucu Yapılandırması
// Backend hazır olduğunda bu değerleri güncelle.
// ═══════════════════════════════════════════════════════════════════════════

class TcpConfig {
  final String host;
  final int port;
  final Duration connectTimeout;
  final Duration requestTimeout;

  const TcpConfig({
    this.host = '192.168.1.100',
    this.port = 8080,
    this.connectTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 30),
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TCP Soket Servisi
//
// Protokol: Newline-Delimited JSON
//   İSTEK  → {"requestId":"<uuid>","action":"<action>","payload":{...}}\n
//   YANIT  ← {"requestId":"<uuid>","ok":true|false,"data":{...},"error":"..."}\n
//
// Özellikler:
//   • Tek kalıcı TCP bağlantısı (Socket.connect)
//   • Exponential backoff ile otomatik yeniden bağlanma
//   • requestId bazlı Completer eşleştirme (request → response)
//   • Bağlantı durumu Stream'i
// ═══════════════════════════════════════════════════════════════════════════

class TcpSocketService {
  final TcpConfig config;

  TcpSocketService({TcpConfig? config}) : config = config ?? const TcpConfig();

  // ── İç durum ────────────────────────────────────────────────────────────
  Socket? _socket;
  bool _disposed = false;
  bool _reconnecting = false;

  /// Bekleyen istekler: requestId → Completer<Map<String,dynamic>>
  final _pending = <String, Completer<Map<String, dynamic>>>{};

  /// Ham mesaj buffer'ı — TCP akışı birden fazla mesajı birleştirebilir.
  final _buffer = StringBuffer();

  // ── Bağlantı durumu yayını ──────────────────────────────────────────────
  final _stateController = StreamController<TcpConnectionState>.broadcast();

  Stream<TcpConnectionState> get connectionState => _stateController.stream;

  TcpConnectionState _currentState = TcpConnectionState.disconnected;

  void _setState(TcpConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  TcpConnectionState get currentState => _currentState;

  // ── Bağlantı ────────────────────────────────────────────────────────────

  /// Sunucuya bağlan. Zaten bağlıysa işlem yapmaz.
  Future<void> connect() async {
    if (_currentState == TcpConnectionState.connected) return;
    if (_disposed) throw StateError('TcpSocketService dispose edildi.');

    _setState(TcpConnectionState.connecting);

    try {
      _socket = await Socket.connect(
        config.host,
        config.port,
        timeout: config.connectTimeout,
      );

      _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            _onData,
            onError: _onError,
            onDone: _onDone,
            cancelOnError: false,
          );

      _setState(TcpConnectionState.connected);
    } catch (e) {
      _setState(TcpConnectionState.disconnected);
      rethrow;
    }
  }

  /// Bağlantıyı kapat ve kaynakları serbest bırak.
  Future<void> disconnect() async {
    _disposed = true;
    _reconnecting = false;
    await _closeSocket();
    await _stateController.close();
  }

  Future<void> _closeSocket() async {
    try {
      await _socket?.flush();
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  // ── Veri Alma (Framing) ─────────────────────────────────────────────────

  void _onData(String chunk) {
    _buffer.write(chunk);
    final raw = _buffer.toString();

    // Newline ile ayrılmış mesajları işle
    final lines = raw.split('\n');

    // Son eleman tamamlanmamış olabilir — buffer'da tut
    _buffer.clear();
    _buffer.write(lines.last);

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      _processMessage(line);
    }
  }

  void _processMessage(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final requestId = json['requestId'] as String?;

      if (requestId != null && _pending.containsKey(requestId)) {
        final completer = _pending.remove(requestId)!;

        if (json['ok'] == true) {
          completer.complete(json);
        } else {
          final errorMsg =
              json['error']?.toString() ?? 'Sunucudan hata yanıtı alındı.';
          completer.completeError(TcpException(errorMsg, json));
        }
      }
    } catch (e) {
      // Ayrıştırılamayan mesaj — yoksay, log'la
      // ignore: avoid_print
      print('[TcpSocketService] Ayrıştırılamayan mesaj: $raw');
    }
  }

  void _onError(Object error, StackTrace stack) {
    // ignore: avoid_print
    print('[TcpSocketService] Soket hatası: $error');
    _failAllPending('Soket hatası: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    _setState(TcpConnectionState.disconnected);
    _failAllPending('Sunucu bağlantıyı kapattı.');
    _scheduleReconnect();
  }

  void _failAllPending(String reason) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(TcpException(reason));
      }
    }
    _pending.clear();
  }

  // ── Otomatik Yeniden Bağlanma (Exponential Backoff) ────────────────────

  int _reconnectAttempt = 0;
  static const _maxBackoffSeconds = 30;

  void _scheduleReconnect() {
    if (_disposed || _reconnecting) return;
    _reconnecting = true;
    _setState(TcpConnectionState.disconnected);
    _socket = null;

    final delaySeconds = _backoffDelay();
    // ignore: avoid_print
    print('[TcpSocketService] $delaySeconds s sonra yeniden bağlanılıyor...');

    Future.delayed(Duration(seconds: delaySeconds), () async {
      if (_disposed) return;
      _reconnecting = false;
      _reconnectAttempt++;

      try {
        await connect();
        _reconnectAttempt = 0;
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  int _backoffDelay() {
    final delay = 1 << _reconnectAttempt; // 1, 2, 4, 8, 16 ...
    return delay > _maxBackoffSeconds ? _maxBackoffSeconds : delay;
  }

  // ── İstek Gönderme ──────────────────────────────────────────────────────

  /// Sunucuya bir JSON isteği gönderir ve yanıtı bekler.
  ///
  /// [action] : İşlem adı — ör. "auth.login", "users.list"
  /// [payload]: İstek gövdesi
  /// [token]  : Varsa Bearer token (her istek taşır)
  Future<Map<String, dynamic>> send({
    required String action,
    Map<String, dynamic> payload = const {},
    String? token,
  }) async {
    if (_currentState != TcpConnectionState.connected) {
      // Bağlı değilse bağlan
      await connect();
    }

    final requestId = _generateId();
    final message = {
      'requestId': requestId,
      'action': action,
      if (token != null) 'token': token,
      'payload': payload,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pending[requestId] = completer;

    // Gönder — newline ile bitir (framing)
    try {
      _socket!.write('${jsonEncode(message)}\n');
    } catch (e) {
      _pending.remove(requestId);
      rethrow;
    }

    // Zaman aşımı
    return completer.future.timeout(
      config.requestTimeout,
      onTimeout: () {
        _pending.remove(requestId);
        throw TcpException('İstek zaman aşımına uğradı: $action');
      },
    );
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter = (_idCounter + 1) % 0xFFFFFF;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$ts-${_idCounter.toRadixString(16)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TCP Özel Hata Sınıfı
// ═══════════════════════════════════════════════════════════════════════════

class TcpException implements Exception {
  final String message;
  final Map<String, dynamic>? serverResponse;

  const TcpException(this.message, [this.serverResponse]);

  @override
  String toString() => 'TcpException: $message';
}
