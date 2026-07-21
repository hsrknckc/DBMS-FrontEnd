import 'package:dio/dio.dart';
import '../../models/dashboard_stats.dart';
import 'dashboard_repository.dart';

/// Gerçek backend için HTTP dashboard implementasyonu.
class HttpDashboardRepository implements DashboardRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpDashboardRepository(this._dio);

  @override
  Future<DashboardStats> getStats() async {
    // TODO: GET /dashboard/stats
    // Yanıt: {"totalDatabases": 8, "totalCollections": 24, ...}
    throw UnimplementedError('HttpDashboardRepository.getStats');
  }

  @override
  Future<List<RecentActivity>> getRecentActivities({int limit = 5}) async {
    // TODO: GET /dashboard/recent-activities?limit=5
    // Yanıt: [{"title": "...", "description": "...", "occurredAt": "...", "actionType": "..."}]
    throw UnimplementedError('HttpDashboardRepository.getRecentActivities');
  }

  @override
  Future<SystemStatus> getSystemStatus() async {
    // TODO: GET /dashboard/system-status
    // Yanıt: {"isMongoConnected": true, "isApiOnline": true, "lastBackupAt": "...", "lastCheckedAt": "..."}
    throw UnimplementedError('HttpDashboardRepository.getSystemStatus');
  }
}
