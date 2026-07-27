import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tcp_socket_service.dart';

/// TCP Sunucu yapılandırması sağlayıcısı
final tcpConfigProvider = Provider<TcpConfig>((ref) {
  return const TcpConfig(
    host: '54.154.220.190', // ← AWS Ortak Sunucusu IP
    port: 5150,            // ← Soket Portu
  );
});

/// `TcpSocketService` tekil nesne sağlayıcısı (Singleton Provider)
///
/// Uygulama kapanırken veya provider dispose edildiğinde TCP bağlantısını otomatik kapatır.
final socketServiceProvider = Provider<TcpSocketService>((ref) {
  final config = ref.watch(tcpConfigProvider);
  final service = TcpSocketService(config: config);

  // Provider sonlandığında soketi kapat
  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

/// TCP Bağlantı durumunu canlı dinleyen StreamProvider (disconnected, connecting, connected)
final tcpConnectionStateProvider = StreamProvider<TcpConnectionState>((ref) {
  final service = ref.watch(socketServiceProvider);
  return service.connectionState;
});
