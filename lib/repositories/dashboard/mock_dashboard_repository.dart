import '../../models/dashboard_stats.dart';
import 'dashboard_repository.dart';

/// Sahte dashboard verisi — dashboard_page.dart'taki hard-coded sayılar ve aktiviteler buraya taşındı.
class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const DashboardStats(
      totalDatabases: 8,
      totalCollections: 24,
      totalRecords: 128450,
      activeUsers: 16,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivities({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final activities = [
      RecentActivity(
        title: 'Yeni collection oluşturuldu',
        description: 'sensor_data collection oluşturuldu.',
        occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        actionType: 'collection_created',
      ),
      RecentActivity(
        title: 'Kullanıcı yetkisi güncellendi',
        description: 'Mehmet Kaya, Sensor Admin olarak atandı.',
        occurredAt: DateTime.now().subtract(const Duration(minutes: 22)),
        actionType: 'permission_updated',
      ),
      RecentActivity(
        title: 'Veri dışa aktarıldı',
        description: 'signal_data verileri CSV olarak indirildi.',
        occurredAt: DateTime.now().subtract(const Duration(hours: 1)),
        actionType: 'data_exported',
      ),
      RecentActivity(
        title: 'Database oluşturuldu',
        description: 'acoustic_archive database oluşturuldu.',
        occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
        actionType: 'database_created',
      ),
      RecentActivity(
        title: 'Kullanıcı eklendi',
        description: 'Yeni kullanıcı sisteme eklendi.',
        occurredAt: DateTime.now().subtract(const Duration(hours: 5)),
        actionType: 'user_created',
      ),
    ];
    return activities.take(limit).toList();
  }

  @override
  Future<SystemStatus> getSystemStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SystemStatus(
      isMongoConnected: true,
      isApiOnline: false, // Backend henüz hazır değil
      lastBackupAt: DateTime(2026, 7, 20, 9, 30),
      lastCheckedAt: DateTime.now(),
    );
  }
}
