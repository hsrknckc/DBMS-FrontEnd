/// Dashboard için özet istatistik modelleri.
/// Backend: GET /dashboard/stats

class DashboardStats {
  final int totalDatabases;
  final int totalCollections;
  final int totalRecords;
  final int activeUsers;

  const DashboardStats({
    required this.totalDatabases,
    required this.totalCollections,
    required this.totalRecords,
    required this.activeUsers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDatabases: (json['totalDatabases'] as num?)?.toInt() ?? 0,
      totalCollections: (json['totalCollections'] as num?)?.toInt() ?? 0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalDatabases': totalDatabases,
        'totalCollections': totalCollections,
        'totalRecords': totalRecords,
        'activeUsers': activeUsers,
      };
}

/// Son işlem listesi için veri modeli.
/// Backend: GET /dashboard/recent-activities
class RecentActivity {
  final String title;
  final String description;
  final DateTime occurredAt;
  final String actionType; // 'collection_created', 'permission_updated', vb.

  const RecentActivity({
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.actionType,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : DateTime.now(),
      actionType: json['actionType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'occurredAt': occurredAt.toIso8601String(),
        'actionType': actionType,
      };
}

/// Sistem durumu kartı için model.
/// Backend: GET /dashboard/system-status
class SystemStatus {
  final bool isMongoConnected;
  final bool isApiOnline;
  final DateTime? lastBackupAt;
  final DateTime lastCheckedAt;

  const SystemStatus({
    required this.isMongoConnected,
    required this.isApiOnline,
    this.lastBackupAt,
    required this.lastCheckedAt,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      isMongoConnected: json['isMongoConnected'] as bool? ?? false,
      isApiOnline: json['isApiOnline'] as bool? ?? false,
      lastBackupAt: json['lastBackupAt'] != null
          ? DateTime.parse(json['lastBackupAt'] as String)
          : null,
      lastCheckedAt: json['lastCheckedAt'] != null
          ? DateTime.parse(json['lastCheckedAt'] as String)
          : DateTime.now(),
    );
  }
}
