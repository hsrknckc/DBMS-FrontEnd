import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/tcp_auth_repository.dart';

import '../../repositories/user/user_repository.dart';
import '../../repositories/user/tcp_user_repository.dart';

import '../../repositories/database/database_repository.dart';
import '../../repositories/database/tcp_database_repository.dart';

import '../../repositories/data_explorer/data_explorer_repository.dart';
import '../../repositories/data_explorer/tcp_data_explorer_repository.dart';

import '../../repositories/audit_log/audit_log_repository.dart';
import '../../repositories/audit_log/tcp_audit_log_repository.dart';

import '../../repositories/dashboard/dashboard_repository.dart';
import '../../repositories/dashboard/tcp_dashboard_repository.dart';

import '../../repositories/schema/schema_repository.dart';
import '../../repositories/schema/tcp_schema_repository.dart';

import 'socket_provider.dart';

export 'socket_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  return dio;
});

final tcpSocketServiceProvider = socketServiceProvider;

// ── Credentials (Giriş Bilgileri) ─────────────────────────────────────────────

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
  final creds = ref.watch(credentialsProvider);
  return TcpUserRepository(ref.read(tcpSocketServiceProvider), () => creds);
});

// ── Database ─────────────────────────────────────────────────────────────────

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final creds = ref.watch(credentialsProvider);
  return TcpDatabaseRepository(ref.read(tcpSocketServiceProvider), () => creds);
});

// ── Data Explorer ─────────────────────────────────────────────────────────────

final dataExplorerRepositoryProvider = Provider<DataExplorerRepository>((ref) {
  final creds = ref.watch(credentialsProvider);
  return TcpDataExplorerRepository(
    ref.read(tcpSocketServiceProvider),
    () => creds,
  );
});

// ── Audit Log ─────────────────────────────────────────────────────────────────

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final creds = ref.watch(credentialsProvider);
  return TcpAuditLogRepository(ref.read(tcpSocketServiceProvider), () => creds);
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final creds = ref.watch(credentialsProvider);
  return TcpDashboardRepository(
    ref.read(tcpSocketServiceProvider),
    () => creds,
  );
});

// ── Schema ────────────────────────────────────────────────────────────────────

final schemaRepositoryProvider = Provider<SchemaRepository>((ref) {
  final creds = ref.watch(credentialsProvider);
  return TcpSchemaRepository(ref.read(tcpSocketServiceProvider), () => creds);
});
