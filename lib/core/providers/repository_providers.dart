import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/mock_auth_repository.dart';
// import '../../repositories/auth/http_auth_repository.dart'; // Backend hazır olunca aç

import '../../repositories/user/user_repository.dart';
import '../../repositories/user/mock_user_repository.dart';
// import '../../repositories/user/http_user_repository.dart';

import '../../repositories/database/database_repository.dart';
import '../../repositories/database/mock_database_repository.dart';
// import '../../repositories/database/http_database_repository.dart';

import '../../repositories/data_explorer/data_explorer_repository.dart';
import '../../repositories/data_explorer/mock_data_explorer_repository.dart';
// import '../../repositories/data_explorer/http_data_explorer_repository.dart';

import '../../repositories/audit_log/audit_log_repository.dart';
import '../../repositories/audit_log/mock_audit_log_repository.dart';
// import '../../repositories/audit_log/http_audit_log_repository.dart';

import '../../repositories/dashboard/dashboard_repository.dart';
import '../../repositories/dashboard/mock_dashboard_repository.dart';
// import '../../repositories/dashboard/http_dashboard_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HTTP Client (Dio)
// Backend hazır olduğunda temel URL'i buradan güncelle.
// ═══════════════════════════════════════════════════════════════════════════════

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // İsteğe bağlı: interceptor ekle (logging, token enjeksiyonu, vb.)
  // dio.interceptors.add(AuthInterceptor(ref));

  return dio;
});

// ═══════════════════════════════════════════════════════════════════════════════
// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║          ⚡ TEK GEÇİŞ NOKTASI — MOCK → HTTP                               ║
// ║  Backend hazır olduğunda yorum satırlarını değiştir, uygulama çalışır.    ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
// ═══════════════════════════════════════════════════════════════════════════════

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
  // return HttpAuthRepository(ref.read(dioProvider));  // ← backend için
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository();
  // return HttpUserRepository(ref.read(dioProvider));
});

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return MockDatabaseRepository();
  // return HttpDatabaseRepository(ref.read(dioProvider));
});

final dataExplorerRepositoryProvider = Provider<DataExplorerRepository>((ref) {
  return MockDataExplorerRepository();
  // return HttpDataExplorerRepository(ref.read(dioProvider));
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return MockAuditLogRepository();
  // return HttpAuditLogRepository(ref.read(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository();
  // return HttpDashboardRepository(ref.read(dioProvider));
});
