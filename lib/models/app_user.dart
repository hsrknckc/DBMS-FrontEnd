import 'permission.dart';

enum UserRole {
  superAdmin,
  user,
}

extension UserRoleExtension on UserRole {
  String get code {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.user:
        return 'USER';
    }
  }

  static UserRole fromCode(String code) {
    switch (code) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final Set<String> departments;
  final Set<Permission> permissions;
  final bool isActive;
  final bool isDeleted;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastLogoutAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departments,
    required this.permissions,
    required this.isActive,
    this.isDeleted = false,
    this.mustChangePassword = false,
    this.createdAt,
    this.lastLoginAt,
    this.lastLogoutAt,
    this.deletedAt,
    this.deletedBy,
  });

  // ── Computed Properties ────────────────────────────────────────────────────

  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool hasPermission(Permission permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool canAccessDepartment(String department) {
    if (isSuperAdmin) return true;
    return departments.contains(department);
  }

  /// "Ahmet Yılmaz" → "AY"
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case UserRole.superAdmin:
        return 'Süper Admin';
      case UserRole.user:
        return 'Kullanıcı';
    }
  }

  String get departmentLabel {
    if (departments.isEmpty) return 'Atanmamış';
    return departments.join(', ');
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// MongoDB dökümanından oluştur. `_id` → `id` dönüşümü dahil.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawPermissions =
        (json['permissions'] as List<dynamic>? ?? []).cast<String>();
    final rawDepartments =
        (json['departments'] as List<dynamic>? ?? []).cast<String>();

    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRoleExtension.fromCode(json['role'] as String? ?? ''),
      departments: rawDepartments.toSet(),
      permissions: rawPermissions
          .map((code) => PermissionExtension.fromCode(code))
          .whereType<Permission>()
          .toSet(),
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      lastLogoutAt: json['lastLogoutAt'] != null
          ? DateTime.parse(json['lastLogoutAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.code,
      'departments': departments.toList(),
      'permissions': permissions.map((p) => p.code).toList(),
      'isActive': isActive,
      'isDeleted': isDeleted,
      'mustChangePassword': mustChangePassword,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
      if (lastLogoutAt != null)
        'lastLogoutAt': lastLogoutAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deletedBy': deletedBy,
    };
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    Set<String>? departments,
    Set<Permission>? permissions,
    bool? isActive,
    bool? isDeleted,
    bool? mustChangePassword,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastLogoutAt,
    DateTime? deletedAt,
    String? deletedBy,
    bool clearDeletedAt = false,
    bool clearDeletedBy = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      departments: departments ?? this.departments,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLogoutAt: lastLogoutAt ?? this.lastLogoutAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletedBy: clearDeletedBy ? null : (deletedBy ?? this.deletedBy),
    );
  }
}
