import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../models/db_request.dart';
import '../../models/db_response.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TCP Bağlantı Durumu
// ═══════════════════════════════════════════════════════════════════════════

enum TcpConnectionState { disconnected, connecting, connected }

// ═══════════════════════════════════════════════════════════════════════════
// Sunucu Yapılandırması
// ═══════════════════════════════════════════════════════════════════════════

class TcpConfig {
  final String host;
  final int port;
  final Duration connectTimeout;
  final Duration requestTimeout;

  const TcpConfig({
    this.host = '54.154.220.190',
    this.port = 5150,
    this.connectTimeout = const Duration(seconds: 3),
    this.requestTimeout = const Duration(seconds: 4),
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TCP Soket Servisi (Persist & Multiplexed Async Requests)
// ═══════════════════════════════════════════════════════════════════════════

class TcpSocketService {
  final TcpConfig config;
  static const _uuid = Uuid();

  Socket? _socket;
  bool _disposed = false;
  bool _reconnecting = false;
  int _reconnectAttempt = 0;
  static const int _maxBackoffSeconds = 15;

  /// Bekleyen istekler: requestId ➔ Completer<DbResponse>
  final Map<String, Completer<DbResponse>> _pendingRequests = {};

  /// Gelen parçalı TCP mesajlarını newline ('\n') ile birleştiren buffer
  final StringBuffer _buffer = StringBuffer();

  /// Bağlantı durumu dinleyici akışı (Stream)
  final StreamController<TcpConnectionState> _stateController =
      StreamController<TcpConnectionState>.broadcast();

  TcpSocketService({TcpConfig? config}) : config = config ?? const TcpConfig();

  /// Bağlantı durumu akışı
  Stream<TcpConnectionState> get connectionState => _stateController.stream;

  TcpConnectionState _currentState = TcpConnectionState.disconnected;

  /// Mevcut bağlantı durumu
  TcpConnectionState get currentState => _currentState;

  void _setState(TcpConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  // ── Bağlantı Yönetimi ──────────────────────────────────────────────────

  /// Ham TCP Soket bağlantısı açar. Bağlıysa işlem yapmaz.
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

      _reconnectAttempt = 0;

      _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            _onDataReceived,
            onError: _onSocketError,
            onDone: _onSocketDone,
            cancelOnError: false,
          );

      _setState(TcpConnectionState.connected);
    } catch (e) {
      _setState(TcpConnectionState.disconnected);
      rethrow;
    }
  }

  /// Soket bağlantısını güvenli biçimde kapatır.
  Future<void> disconnect() async {
    _disposed = true;
    _reconnecting = false;
    _failAllPending('Bağlantı kullanıcı tarafından kapatıldı.');
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

  // ── Veri Alma & Çerçeveleme (Framing: '\n') ────────────────────────────

  void _onDataReceived(String chunk) {
    _buffer.write(chunk);
    final content = _buffer.toString();

    // Newline ('\n') ile ayrılmış mesajları böl
    final lines = content.split('\n');

    // Son eleman henüz tamamlanmamış olabilir, buffer'da tut
    _buffer.clear();
    _buffer.write(lines.last);

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        _processIncomingLine(line);
      }
    }
  }

  void _processIncomingLine(String line) {
    try {
      final decoded = jsonDecode(line);
      Map<String, dynamic> jsonMap = {};

      if (decoded is Map<String, dynamic>) {
        jsonMap = decoded;
      } else if (decoded is List) {
        jsonMap = {'data': decoded, 'status': 'OK', 'ok': true};
      } else if (decoded is Map) {
        jsonMap = Map<String, dynamic>.from(decoded);
      } else {
        jsonMap = {'data': decoded, 'status': 'OK', 'ok': true};
      }

      final response = DbResponse.fromJson(jsonMap);

      Completer<DbResponse>? completer;
      if (response.requestId.isNotEmpty && _pendingRequests.containsKey(response.requestId)) {
        completer = _pendingRequests.remove(response.requestId);
      } else if (_pendingRequests.isNotEmpty) {
        final firstKey = _pendingRequests.keys.first;
        completer = _pendingRequests.remove(firstKey);
      }

      if (completer != null && !completer.isCompleted) {
        completer.complete(response);
      }
    } catch (e) {
      print('[TcpSocketService] Yanıt ayrıştırma hatası: $e | Ham Satır: $line');
      if (_pendingRequests.isNotEmpty) {
        final firstKey = _pendingRequests.keys.first;
        final completer = _pendingRequests.remove(firstKey);
        if (completer != null && !completer.isCompleted) {
          completer.complete(DbResponse(
            requestId: firstKey,
            ok: true,
            status: 'OK',
            data: line,
          ));
        }
      }
    }
  }

  void _onSocketError(Object error) {
    print('[TcpSocketService] Soket hatası: $error');
    _failAllPending('Soket hatası meydana geldi: $error');
    _scheduleReconnect();
  }

  void _onSocketDone() {
    _setState(TcpConnectionState.disconnected);
    _failAllPending('Sunucu bağlantıyı sonlandırdı.');
    _scheduleReconnect();
  }

  void _failAllPending(String reason) {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(TcpException(reason));
      }
    }
    _pendingRequests.clear();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnecting) return;
    _reconnecting = true;
    _setState(TcpConnectionState.disconnected);
    _socket = null;

    final delaySeconds = (1 << _reconnectAttempt).clamp(1, _maxBackoffSeconds);
    print('[TcpSocketService] $delaySeconds saniye sonra yeniden bağlanılacak...');

    Future.delayed(Duration(seconds: delaySeconds), () async {
      if (_disposed) return;
      _reconnecting = false;
      _reconnectAttempt++;

      try {
        await connect();
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  // ── İstek Gönderme Mimarisi (Completer + Multiplexed) ───────────────────

  /// Bir [DbRequest] paketini tek satırlık JSON + '\n' formatında sunucuya gönderir.
  Future<DbResponse> sendRequest(DbRequest request) async {
    if (_currentState != TcpConnectionState.connected) {
      await connect();
    }

    final jsonPayload = jsonEncode(request.toJson());
    final completer = Completer<DbResponse>();

    _pendingRequests[request.requestId] = completer;

    try {
      _socket!.write('$jsonPayload\n');
    } catch (e) {
      _pendingRequests.remove(request.requestId);
      rethrow;
    }

    // Zaman aşımı süresi 4 saniyeye düşürüldü (Kullanıcı yüklemede takılmasın)
    return completer.future.timeout(
      config.requestTimeout,
      onTimeout: () {
        _pendingRequests.remove(request.requestId);
        throw TcpException(
          'Zaman aşımı (${config.requestTimeout.inSeconds}s): ${request.action}',
        );
      },
    );
  }

  /// Esnek İstek Metodu
  Future<Map<String, dynamic>> send({
    required String action,
    String? username,
    String? password,
    String? database,
    String? collection,
    Map<String, dynamic>? filter,
    Map<String, dynamic>? document,
    String? token,
    Map<String, dynamic>? payload,
  }) async {
    final req = DbRequest(
      requestId: _uuid.v4(),
      action: action,
      username: username,
      password: password,
      database: database,
      collection: collection,
      filter: filter,
      document: document,
      token: token,
      payload: payload,
    );

    final res = await sendRequest(req);

    if (!res.isOk) {
      throw TcpException(
        res.error ?? res.message ?? 'Sunucu hatası: $action başarısız oldu.',
        res,
      );
    }

    return {
      'requestId': res.requestId,
      'ok': res.isOk,
      'status': res.status ?? (res.isOk ? 'OK' : 'ERROR'),
      'message': res.message ?? res.error,
      'error': res.error,
      'data': res.data,
    };
  }
}

class TcpException implements Exception {
  final String message;
  final DbResponse? response;

  const TcpException(this.message, [this.response]);

  @override
  String toString() => 'TcpException: $message';
}
