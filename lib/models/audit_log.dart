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
        return 'Şifre Sıfırlama İstendi';
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
      case AuditAction.dataExported:
        return 'DATA_EXPORTED';
      case AuditAction.databaseCreated:
        return 'DATABASE_CREATED';
    }
  }

  static AuditAction fromCode(String code) {
    return AuditAction.values.firstWhere(
      (a) => a.code == code,
      orElse: () => AuditAction.userUpdated,
    );
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
    return AuditLog(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      action: AuditActionExtension.fromCode(json['action'] as String? ?? ''),
      performedById: json['performedById'] as String? ?? '',
      performedByName: json['performedByName'] as String? ?? '',
      targetUserId: json['targetUserId'] as String?,
      targetUserName: json['targetUserName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      description: json['description'] as String? ?? '',
      oldValues:
          (json['oldValues'] as Map<String, dynamic>?) ?? const {},
      newValues:
          (json['newValues'] as Map<String, dynamic>?) ?? const {},
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
