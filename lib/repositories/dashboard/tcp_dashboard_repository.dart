import '../../core/services/tcp_socket_service.dart';
import '../../models/dashboard_stats.dart';
import 'dashboard_repository.dart';

/// TCP/IP soket üzerinden dashboard istatistik ve durum sorgulama.
///
/// Protokol aksiyonları:
///   dashboard.stats          → {}
///   dashboard.recentActivities → {limit}
///   dashboard.systemStatus   → {}
class TcpDashboardRepository implements DashboardRepository {
  final TcpSocketService _tcp;
  final String? Function() _tokenProvider;

  TcpDashboardRepository(this._tcp, this._tokenProvider);

  @override
  Future<DashboardStats> getStats() async {
    final response = await _tcp.send(
      action: 'dashboard.stats',
      payload: {},
      token: _tokenProvider(),
    );
    return DashboardStats.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<RecentActivity>> getRecentActivities({int limit = 5}) async {
    final response = await _tcp.send(
      action: 'dashboard.recentActivities',
      payload: {'limit': limit},
      token: _tokenProvider(),
    );
    final list =
        (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(RecentActivity.fromJson).toList();
  }

  @override
  Future<SystemStatus> getSystemStatus() async {
    final response = await _tcp.send(
      action: 'dashboard.systemStatus',
      payload: {},
      token: _tokenProvider(),
    );
    return SystemStatus.fromJson(response['data'] as Map<String, dynamic>);
  }
}
