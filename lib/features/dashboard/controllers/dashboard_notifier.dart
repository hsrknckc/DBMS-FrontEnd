import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dashboard_stats.dart';
import '../../../core/providers/repository_providers.dart';

// ── Stats ──────────────────────────────────────────────────────────────────────

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() {
    return ref.read(dashboardRepositoryProvider).getStats();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getStats(),
    );
  }
}

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
        DashboardStatsNotifier.new);

// ── Recent Activities ──────────────────────────────────────────────────────────

class RecentActivitiesNotifier extends AsyncNotifier<List<RecentActivity>> {
  @override
  Future<List<RecentActivity>> build() {
    return ref
        .read(dashboardRepositoryProvider)
        .getRecentActivities(limit: 5);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(dashboardRepositoryProvider)
          .getRecentActivities(limit: 5),
    );
  }
}

final recentActivitiesProvider =
    AsyncNotifierProvider<RecentActivitiesNotifier, List<RecentActivity>>(
        RecentActivitiesNotifier.new);

// ── System Status ──────────────────────────────────────────────────────────────

class SystemStatusNotifier extends AsyncNotifier<SystemStatus> {
  @override
  Future<SystemStatus> build() {
    return ref.read(dashboardRepositoryProvider).getSystemStatus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getSystemStatus(),
    );
  }
}

final systemStatusProvider =
    AsyncNotifierProvider<SystemStatusNotifier, SystemStatus>(
        SystemStatusNotifier.new);
