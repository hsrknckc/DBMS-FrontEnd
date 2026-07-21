import '../../models/audit_log.dart';
import 'audit_log_repository.dart';

/// Sahte audit log verisi — audit_log_page.dart'taki hard-coded log listesi buraya taşındı.
class MockAuditLogRepository implements AuditLogRepository {
  final List<AuditLog> _logs = [
    AuditLog(
      id: 'log-1',
      action: AuditAction.permissionsUpdated,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-1',
      targetUserName: 'Mehmet Kaya',
      createdAt: DateTime(2026, 7, 15, 14, 40),
      description:
          'Mehmet Kaya kullanıcısının departman ve işlem yetkileri güncellendi.',
      oldValues: const {
        'Departmanlar': ['Sensor'],
        'Yetkiler': ['Database görüntüleme', 'Veri görüntüleme'],
      },
      newValues: const {
        'Departmanlar': ['Sensor', 'Signal'],
        'Yetkiler': [
          'Database görüntüleme',
          'Veri görüntüleme',
          'Veri dışa aktarma',
        ],
      },
    ),
    AuditLog(
      id: 'log-2',
      action: AuditAction.userSoftDeleted,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-3',
      targetUserName: 'Ahmet Yıldız',
      createdAt: DateTime(2026, 7, 15, 13, 20),
      description: 'Ahmet Yıldız silinen kullanıcılar bölümüne taşındı.',
      oldValues: const {'Silindi': false, 'Aktif': true},
      newValues: const {'Silindi': true, 'Aktif': false},
    ),
    AuditLog(
      id: 'log-3',
      action: AuditAction.passwordResetRequested,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-2',
      targetUserName: 'Zeynep Demir',
      createdAt: DateTime(2026, 7, 15, 11, 15),
      description: 'Zeynep Demir için şifre yenileme anahtarı oluşturuldu.',
    ),
    AuditLog(
      id: 'log-4',
      action: AuditAction.userStatusChanged,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-4',
      targetUserName: 'Elif Arslan',
      createdAt: DateTime(2026, 7, 14, 16, 50),
      description: 'Elif Arslan kullanıcısı pasif duruma getirildi.',
      oldValues: const {'Aktif': true},
      newValues: const {'Aktif': false},
    ),
    AuditLog(
      id: 'log-5',
      action: AuditAction.dataExported,
      performedById: 'user-1',
      performedByName: 'Mehmet Kaya',
      targetUserId: 'user-1',
      targetUserName: 'Mehmet Kaya',
      createdAt: DateTime(2026, 7, 14, 15, 10),
      description: 'Signal departmanındaki veriler CSV olarak dışa aktarıldı.',
      newValues: const {
        'Format': 'CSV',
        'Departman': 'Signal',
        'Kayıt sayısı': 1240,
      },
    ),
    AuditLog(
      id: 'log-6',
      action: AuditAction.databaseCreated,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      createdAt: DateTime(2026, 7, 14, 10, 30),
      description: 'sensor_archive isimli yeni bir database oluşturuldu.',
      newValues: const {
        'Database adı': 'sensor_archive',
        'Departman': 'Sensor',
      },
    ),
  ];

  @override
  Future<List<AuditLog>> getLogs({
    AuditAction? action,
    bool? onlyRevertible,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = List<AuditLog>.from(_logs);

    if (action != null) {
      results = results.where((l) => l.action == action).toList();
    }
    if (onlyRevertible == true) {
      results = results.where((l) => l.canBeReverted).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<AuditLog> revertLog(String logId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _logs.indexWhere((l) => l.id == logId);
    if (index == -1) throw Exception('Log bulunamadı: $logId');

    final original = _logs[index];
    final revertedAt = DateTime.now();

    // Orijinal logu reverted olarak işaretle
    _logs[index] = original.copyWith(
      isReverted: true,
      revertedAt: revertedAt,
      revertedByName: 'Ayşe Yılmaz',
    );

    // Geri alma için yeni log oluştur
    final revertLog = AuditLog(
      id: revertedAt.millisecondsSinceEpoch.toString(),
      action: AuditAction.permissionsReverted,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: original.targetUserId,
      targetUserName: original.targetUserName,
      createdAt: revertedAt,
      description: '${original.action.label} işlemi geri alındı.',
      oldValues: original.newValues,
      newValues: original.oldValues,
    );
    _logs.insert(0, revertLog);

    return revertLog;
  }
}
