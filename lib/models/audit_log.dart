enum AuditAction {
  userCreated,
  userUpdated,
  userStatusChanged,
  userSoftDeleted,
  userRestored,
  userPermanentlyDeleted,
  permissionsUpdated,
  permissionsReverted,
  passwordResetRequested,
  dataExported,
  databaseCreated,
}

extension AuditActionExtension on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.userCreated:
        return 'Kullanıcı oluşturuldu';

      case AuditAction.userUpdated:
        return 'Kullanıcı güncellendi';

      case AuditAction.userStatusChanged:
        return 'Kullanıcı durumu değiştirildi';

      case AuditAction.userSoftDeleted:
        return 'Kullanıcı silindi';

      case AuditAction.userRestored:
        return 'Kullanıcı geri yüklendi';

      case AuditAction.userPermanentlyDeleted:
        return 'Kullanıcı kalıcı olarak silindi';

      case AuditAction.permissionsUpdated:
        return 'Yetkiler güncellendi';

      case AuditAction.permissionsReverted:
        return 'Yetki değişikliği geri alındı';

      case AuditAction.passwordResetRequested:
        return 'Şifre yenileme anahtarı oluşturuldu';

      case AuditAction.dataExported:
        return 'Veri dışa aktarıldı';

      case AuditAction.databaseCreated:
        return 'Database oluşturuldu';
    }
  }

  bool get canBeReverted {
    switch (this) {
      case AuditAction.userUpdated:
      case AuditAction.userStatusChanged:
      case AuditAction.userSoftDeleted:
      case AuditAction.userRestored:
      case AuditAction.permissionsUpdated:
        return true;

      case AuditAction.userCreated:
      case AuditAction.userPermanentlyDeleted:
      case AuditAction.permissionsReverted:
      case AuditAction.passwordResetRequested:
      case AuditAction.dataExported:
      case AuditAction.databaseCreated:
        return false;
    }
  }
}

class AuditLog {
  final String id;
  final AuditAction action;

  final String performedById;
  final String performedByName;

  final String? targetUserId;
  final String? targetUserName;

  final DateTime createdAt;
  final String description;

  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;

  final bool isReverted;
  final DateTime? revertedAt;
  final String? revertedByName;

  const AuditLog({
    required this.id,
    required this.action,
    required this.performedById,
    required this.performedByName,
    required this.createdAt,
    required this.description,
    this.targetUserId,
    this.targetUserName,
    this.oldValues = const {},
    this.newValues = const {},
    this.isReverted = false,
    this.revertedAt,
    this.revertedByName,
  });

  bool get canBeReverted {
    return action.canBeReverted && !isReverted;
  }

  AuditLog copyWith({
    String? id,
    AuditAction? action,
    String? performedById,
    String? performedByName,
    String? targetUserId,
    String? targetUserName,
    DateTime? createdAt,
    String? description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    bool? isReverted,
    DateTime? revertedAt,
    String? revertedByName,
  }) {
    return AuditLog(
      id: id ?? this.id,
      action: action ?? this.action,
      performedById: performedById ?? this.performedById,
      performedByName: performedByName ?? this.performedByName,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      isReverted: isReverted ?? this.isReverted,
      revertedAt: revertedAt ?? this.revertedAt,
      revertedByName: revertedByName ?? this.revertedByName,
    );
  }
}