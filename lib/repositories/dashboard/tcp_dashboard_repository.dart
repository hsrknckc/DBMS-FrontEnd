import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/dashboard_stats.dart';
import 'dashboard_repository.dart';

/// TCP/IP soket üzerinden dashboard istatistik ve durum sorgulama (Yeni Tek Protokol).
class TcpDashboardRepository implements DashboardRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  TcpDashboardRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null) {
      throw const TcpException('Oturum açılmamış (kimlik bilgisi eksik).');
    }
    return c;
  }

  @override
  Future<DashboardStats> getStats() async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'STATS',
      username: c.username,
      password: c.password,
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return DashboardStats.fromJson(first);
      if (first is Map) return DashboardStats.fromJson(Map<String, dynamic>.from(first));
    }

    return const DashboardStats(
      totalDatabases: 0,
      totalCollections: 0,
      totalRecords: 0,
      activeUsers: 0,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivities({int limit = 5}) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'RECENT_ACTIVITIES',
      username: c.username,
      password: c.password,
      filter: {'limit': limit},
    );

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }

    return rawData.map((item) {
      if (item is Map<String, dynamic>) return RecentActivity.fromJson(item);
      if (item is Map) return RecentActivity.fromJson(Map<String, dynamic>.from(item));
      return RecentActivity(
        title: item.toString(),
        description: item.toString(),
        occurredAt: DateTime.now(),
        actionType: 'system',
      );
    }).toList();
  }

  @override
  Future<SystemStatus> getSystemStatus() async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'SYSTEM_STATUS',
      username: c.username,
      password: c.password,
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return SystemStatus.fromJson(first);
      if (first is Map) return SystemStatus.fromJson(Map<String, dynamic>.from(first));
    }

    return SystemStatus(
      isMongoConnected: false,
      isApiOnline: false,
      lastCheckedAt: DateTime.now(),
    );
  }
}
