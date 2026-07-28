import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/auth/auth_repository.dart';
// import '../../repositories/auth/mock_auth_repository.dart';
import '../../repositories/auth/tcp_auth_repository.dart';
// import '../../repositories/auth/http_auth_repository.dart'; // HTTP için

import '../../repositories/user/user_repository.dart';
// import '../../repositories/user/mock_user_repository.dart';
import '../../repositories/user/tcp_user_repository.dart';
// import '../../repositories/user/http_user_repository.dart';

import '../../repositories/database/database_repository.dart';
// import '../../repositories/database/mock_database_repository.dart';
import '../../repositories/database/tcp_database_repository.dart';
// import '../../repositories/database/http_database_repository.dart';

import '../../repositories/data_explorer/data_explorer_repository.dart';
// import '../../repositories/data_explorer/mock_data_explorer_repository.dart';
import '../../repositories/data_explorer/tcp_data_explorer_repository.dart';
// import '../../repositories/data_explorer/http_data_explorer_repository.dart';

import '../../repositories/audit_log/audit_log_repository.dart';
// import '../../repositories/audit_log/mock_audit_log_repository.dart';
import '../../repositories/audit_log/tcp_audit_log_repository.dart';
// import '../../repositories/audit_log/http_audit_log_repository.dart';

import '../../repositories/dashboard/dashboard_repository.dart';
// import '../../repositories/dashboard/mock_dashboard_repository.dart';
import '../../repositories/dashboard/tcp_dashboard_repository.dart';
// import '../../repositories/dashboard/http_dashboard_repository.dart';

import 'socket_provider.dart';

export 'socket_provider.dart';

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

final tcpSocketServiceProvider = socketServiceProvider;

// ═══════════════════════════════════════════════════════════════════════════════
// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║        ⚡ TEK GEÇİŞ NOKTASI — MOCK / TCP / HTTP                            ║
// ║                                                                              ║
// ║  Şu an: TCP  (Canlı AWS Sunucusu: 54.154.220.190:5150)                       ║
// ║  MOCK'a geç: Yorum satırlarını değiştir → MockXxxRepository(...)          ║
// ║  HTTP'ye geç: Yorum satırlarını değiştir → HttpXxxRepository(...)          ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
// ═══════════════════════════════════════════════════════════════════════════════

// ── Credentials (Giriş Bilgileri) ─────────────────────────────────────────────

/// Giriş yapan kullanıcının kimliği — TCP isteklerinde kullanıcı adı (tam e-posta) ve şifre gönderilir
class Credentials {
  final String username;
  final String password;
  const Credentials(this.username, this.password);
}

final credentialsProvider = StateProvider<Credentials?>((ref) => null);

// ── Auth ─────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return TcpAuthRepository(
    ref.read(tcpSocketServiceProvider),
    credentialsNotifier: ref.read(credentialsProvider.notifier),
  );
});

// ── Kullanıcılar ─────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return TcpUserRepository(
    ref.read(tcpSocketServiceProvider),
    () => ref.read(credentialsProvider),
  );
});

// ── Database ─────────────────────────────────────────────────────────────────

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return TcpDatabaseRepository(
    ref.read(tcpSocketServiceProvider),
    () => ref.read(credentialsProvider),
  );
});

// ── Data Explorer ─────────────────────────────────────────────────────────────

final dataExplorerRepositoryProvider = Provider<DataExplorerRepository>((ref) {
  return TcpDataExplorerRepository(
    ref.read(tcpSocketServiceProvider),
    () => ref.read(credentialsProvider),
  );
});

// ── Audit Log ─────────────────────────────────────────────────────────────────

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return TcpAuditLogRepository(
    ref.read(tcpSocketServiceProvider),
    () => ref.read(credentialsProvider),
  );
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return TcpDashboardRepository(
    ref.read(tcpSocketServiceProvider),
    () => ref.read(credentialsProvider),
  );
});
