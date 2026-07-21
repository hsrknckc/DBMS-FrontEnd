import '../../models/dashboard_stats.dart';

/// Dashboard özet verileri için soyut arayüz.
abstract class DashboardRepository {
  /// İstatistik kartları için sayısal özetleri getirir.
  /// Backend: GET /dashboard/stats
  Future<DashboardStats> getStats();

  /// Son sistem işlemlerini getirir.
  /// Backend: GET /dashboard/recent-activities?limit=[limit]
  Future<List<RecentActivity>> getRecentActivities({int limit = 5});

  /// MongoDB ve API bağlantı durumunu getirir.
  /// Backend: GET /dashboard/system-status
  Future<SystemStatus> getSystemStatus();
}
