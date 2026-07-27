import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/mock_auth_repository.dart';
import '../../repositories/auth/tcp_auth_repository.dart';
// import '../../repositories/auth/http_auth_repository.dart'; // HTTP için

import '../../repositories/user/user_repository.dart';
import '../../repositories/user/mock_user_repository.dart';
import '../../repositories/user/tcp_user_repository.dart';
// import '../../repositories/user/http_user_repository.dart';

import '../../repositories/database/database_repository.dart';
import '../../repositories/database/mock_database_repository.dart';
import '../../repositories/database/tcp_database_repository.dart';
// import '../../repositories/database/http_database_repository.dart';

import '../../repositories/data_explorer/data_explorer_repository.dart';
import '../../repositories/data_explorer/mock_data_explorer_repository.dart';
import '../../repositories/data_explorer/tcp_data_explorer_repository.dart';
// import '../../repositories/data_explorer/http_data_explorer_repository.dart';

import '../../repositories/audit_log/audit_log_repository.dart';
import '../../repositories/audit_log/mock_audit_log_repository.dart';
import '../../repositories/audit_log/tcp_audit_log_repository.dart';
// import '../../repositories/audit_log/http_audit_log_repository.dart';

import '../../repositories/dashboard/dashboard_repository.dart';
import '../../repositories/dashboard/mock_dashboard_repository.dart';
import '../../repositories/dashboard/tcp_dashboard_repository.dart';
// import '../../repositories/dashboard/http_dashboard_repository.dart';

import '../services/tcp_socket_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HTTP Client (Dio) — HTTP katmanı için hazır, şimdilik yorum satırında.
// ═══════════════════════════════════════════════════════════════════════════════

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  return dio;
});

// ═══════════════════════════════════════════════════════════════════════════════
// TCP Soket Servisi
//
// Sunucu adresini değiştirmek için TcpConfig'i güncelle:
//   TcpConfig(host: '192.168.1.100', port: 8080)
// ═══════════════════════════════════════════════════════════════════════════════

final tcpSocketServiceProvider = Provider<TcpSocketService>((ref) {
  final service = TcpSocketService(
    config: const TcpConfig(
      host: '54.154.220.190', // ← Sunucu IP'si (AWS)
      port: 5150,            // ← Sunucu portu
    ),
  );

  // Provider dispose edildiğinde soketi kapat
  ref.onDispose(service.disconnect);

  return service;
});

// ═══════════════════════════════════════════════════════════════════════════════
// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║        ⚡ TEK GEÇİŞ NOKTASI — MOCK / TCP / HTTP                            ║
// ║                                                                              ║
// ║  Şu an: MOCK  (geliştirme için, sahte veri)                                 ║
// ║  TCP'ye geç : Yorum satırlarını değiştir → TcpXxxRepository(...)           ║
// ║  HTTP'ye geç: Yorum satırlarını değiştir → HttpXxxRepository(...)          ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
// ═══════════════════════════════════════════════════════════════════════════════

// ── Auth ─────────────────────────────────────────────────────────────────────

/// TCP moduna geçmek için bu provider'ı değiştir:
///   return TcpAuthRepository(ref.read(tcpSocketServiceProvider));
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository(); // MOCK
  // return TcpAuthRepository(ref.read(tcpSocketServiceProvider)); // TCP ←
  // return HttpAuthRepository(ref.read(dioProvider));             // HTTP ←
});

// ── Kullanıcılar ─────────────────────────────────────────────────────────────

/// TCP moduna geçmek için:
///   TcpUserRepository(tcp, () => _currentToken)
///   Token yönetimi için AuthNotifier'dan token almayı tercih et.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository(); // MOCK
  // return TcpUserRepository(               // TCP ←
  //   ref.read(tcpSocketServiceProvider),
  //   () => null, // ← Buraya token sağlayıcı fonksiyon ekle
  // );
  // return HttpUserRepository(ref.read(dioProvider)); // HTTP ←
});

// ── Database ─────────────────────────────────────────────────────────────────

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return MockDatabaseRepository(); // MOCK
  // return TcpDatabaseRepository(               // TCP ←
  //   ref.read(tcpSocketServiceProvider),
  //   () => null,
  // );
  // return HttpDatabaseRepository(ref.read(dioProvider)); // HTTP ←
});

// ── Data Explorer ─────────────────────────────────────────────────────────────

final dataExplorerRepositoryProvider = Provider<DataExplorerRepository>((ref) {
  return MockDataExplorerRepository(); // MOCK
  // return TcpDataExplorerRepository(           // TCP ←
  //   ref.read(tcpSocketServiceProvider),
  //   () => null,
  // );
  // return HttpDataExplorerRepository(ref.read(dioProvider)); // HTTP ←
});

// ── Audit Log ─────────────────────────────────────────────────────────────────

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return MockAuditLogRepository(); // MOCK
  // return TcpAuditLogRepository(               // TCP ←
  //   ref.read(tcpSocketServiceProvider),
  //   () => null,
  // );
  // return HttpAuditLogRepository(ref.read(dioProvider)); // HTTP ←
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository(); // MOCK
  // return TcpDashboardRepository(              // TCP ←
  //   ref.read(tcpSocketServiceProvider),
  //   () => null,
  // );
  // return HttpDashboardRepository(ref.read(dioProvider)); // HTTP ←
});
