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
  passwordResetConfirmed,
  passwordResetApprovalRequired,
  passwordResetApproved,
  passwordResetByAdmin,
  dataExported,
  databaseCreated,
}

extension AuditActionExtension on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.userCreated:
        return 'Kullanıcı Oluşturuldu';
      case AuditAction.userUpdated:
        return 'Kullanıcı Güncellendi';
      case AuditAction.userStatusChanged:
        return 'Kullanıcı Durumu Değiştirildi';
      case AuditAction.userSoftDeleted:
        return 'Kullanıcı Silindi';
      case AuditAction.userRestored:
        return 'Kullanıcı Geri Yüklendi';
      case AuditAction.userPermanentlyDeleted:
        return 'Kullanıcı Kalıcı Silindi';
      case AuditAction.permissionsUpdated:
        return 'Yetkiler Güncellendi';
      case AuditAction.permissionsReverted:
        return 'Yetkiler Geri Alındı';
      case AuditAction.passwordResetRequested:
        return 'Şifre Değişikliği Talep Edildi';
      case AuditAction.passwordResetConfirmed:
        return 'Şifre Değiştirildi';
      case AuditAction.passwordResetApprovalRequired:
        return 'Şifre Onayı Bekliyor';
      case AuditAction.passwordResetApproved:
        return 'Şifre Değişikliği Onaylandı';
      case AuditAction.passwordResetByAdmin:
        return 'Şifre Admin Tarafından Sıfırlandı';
      case AuditAction.dataExported:
        return 'Veri Dışa Aktarıldı';
      case AuditAction.databaseCreated:
        return 'Database Oluşturuldu';
    }
  }

  String get code {
    switch (this) {
      case AuditAction.userCreated:
        return 'USER_CREATED';
      case AuditAction.userUpdated:
        return 'USER_UPDATED';
      case AuditAction.userStatusChanged:
        return 'USER_STATUS_CHANGED';
      case AuditAction.userSoftDeleted:
        return 'USER_SOFT_DELETED';
      case AuditAction.userRestored:
        return 'USER_RESTORED';
      case AuditAction.userPermanentlyDeleted:
        return 'USER_PERMANENTLY_DELETED';
      case AuditAction.permissionsUpdated:
        return 'PERMISSIONS_UPDATED';
      case AuditAction.permissionsReverted:
        return 'PERMISSIONS_REVERTED';
      case AuditAction.passwordResetRequested:
        return 'PASSWORD_RESET_REQUESTED';
      case AuditAction.passwordResetConfirmed:
        return 'PASSWORD_RESET_CONFIRMED';
      case AuditAction.passwordResetApprovalRequired:
        return 'PASSWORD_RESET_APPROVAL_REQUIRED';
      case AuditAction.passwordResetApproved:
        return 'PASSWORD_RESET_APPROVED';
      case AuditAction.passwordResetByAdmin:
        return 'PASSWORD_RESET_BY_ADMIN';
      case AuditAction.dataExported:
        return 'DATA_EXPORTED';
      case AuditAction.databaseCreated:
        return 'DATABASE_CREATED';
    }
  }

  static AuditAction fromCode(String code) {
    switch (code.trim()) {
      case 'USER_CREATED':
      case 'userCreated':
        return AuditAction.userCreated;
      case 'USER_UPDATED':
      case 'userUpdated':
        return AuditAction.userUpdated;
      case 'USER_STATUS_CHANGED':
      case 'userStatusChanged':
        return AuditAction.userStatusChanged;
      case 'USER_SOFT_DELETED':
      case 'userSoftDeleted':
        return AuditAction.userSoftDeleted;
      case 'USER_RESTORED':
      case 'userRestored':
        return AuditAction.userRestored;
      case 'USER_PERMANENTLY_DELETED':
      case 'userPermanentlyDeleted':
        return AuditAction.userPermanentlyDeleted;
      case 'PERMISSIONS_UPDATED':
      case 'permissionsUpdated':
        return AuditAction.permissionsUpdated;
      case 'PERMISSIONS_REVERTED':
      case 'permissionsReverted':
        return AuditAction.permissionsReverted;
      case 'PASSWORD_RESET_REQUESTED':
      case 'passwordResetRequested':
        return AuditAction.passwordResetRequested;
      case 'PASSWORD_RESET_CONFIRMED':
      case 'passwordResetCompleted':
      case 'passwordResetConfirmed':
        return AuditAction.passwordResetConfirmed;
      case 'PASSWORD_RESET_APPROVAL_REQUIRED':
      case 'passwordResetAdminApprovalRequired':
      case 'passwordResetApprovalRequired':
        return AuditAction.passwordResetApprovalRequired;
      case 'PASSWORD_RESET_APPROVED':
      case 'passwordResetAdminApproved':
      case 'passwordResetApproved':
        return AuditAction.passwordResetApproved;
      case 'PASSWORD_RESET_BY_ADMIN':
      case 'passwordResetByAdmin':
        return AuditAction.passwordResetByAdmin;
      case 'DATA_EXPORTED':
      case 'dataExported':
        return AuditAction.dataExported;
      case 'DATABASE_CREATED':
      case 'databaseCreated':
        return AuditAction.databaseCreated;
      default:
        return AuditAction.userUpdated;
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
    this.targetUserId,
    this.targetUserName,
    required this.createdAt,
    required this.description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    this.isReverted = false,
    this.revertedAt,
    this.revertedByName,
  })  : oldValues = oldValues ?? const {},
        newValues = newValues ?? const {};

  bool get canBeReverted {
    return !isReverted &&
        (action == AuditAction.permissionsUpdated ||
            action == AuditAction.userStatusChanged);
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// MongoDB dökümanından oluştur. `_id` → `id` dönüşümü dahil.
  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['occurredAt'];

    return AuditLog(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      action: AuditActionExtension.fromCode(json['action'] as String? ?? ''),
      performedById: json['performedById'] as String? ?? '',
      performedByName: json['performedByName'] as String? ?? '',
      targetUserId: json['targetUserId'] as String?,
      targetUserName: json['targetUserName'] as String?,
      createdAt: rawCreatedAt != null
          ? DateTime.parse(rawCreatedAt as String)
          : DateTime.now(),
      description: json['description'] as String? ?? '',
      oldValues: json['oldValues'] is Map
          ? Map<String, dynamic>.from(json['oldValues'] as Map)
          : const {},
      newValues: json['newValues'] is Map
          ? Map<String, dynamic>.from(json['newValues'] as Map)
          : const {},
      isReverted: json['isReverted'] as bool? ?? false,
      revertedAt: json['revertedAt'] != null
          ? DateTime.parse(json['revertedAt'] as String)
          : null,
      revertedByName: json['revertedByName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.code,
      'performedById': performedById,
      'performedByName': performedByName,
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (targetUserName != null) 'targetUserName': targetUserName,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'oldValues': oldValues,
      'newValues': newValues,
      'isReverted': isReverted,
      if (revertedAt != null) 'revertedAt': revertedAt!.toIso8601String(),
      if (revertedByName != null) 'revertedByName': revertedByName,
    };
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

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
