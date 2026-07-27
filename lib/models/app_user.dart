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
  final Map<String, List<String>> allowedCollections;

  /// Global (eski) izinler — geriye dönük uyumluluk için tutulur.
  final Set<Permission> permissions;

  /// Departman (database) başına database yetkileri.
  /// { 'Sensor': {Permission.databaseView, Permission.databaseCreate}, ... }
  final Map<String, Set<Permission>> databasePermissions;

  /// Koleksiyon başına veri yetkileri.
  /// { 'sensor_readings': {Permission.dataView, Permission.dataCreate}, ... }
  final Map<String, Set<Permission>> collectionPermissions;

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
    this.allowedCollections = const {},
    required this.permissions,
    this.databasePermissions = const {},
    this.collectionPermissions = const {},
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

  /// Belirli bir departmanın (database) belirli yetkisini kontrol eder.
  bool hasDatabasePermission(String department, Permission permission) {
    if (isSuperAdmin) return true;
    return databasePermissions[department]?.contains(permission) ?? false;
  }

  /// Belirli bir koleksiyonun belirli yetkisini kontrol eder.
  bool hasCollectionPermission(String collection, Permission permission) {
    if (isSuperAdmin) return true;
    return collectionPermissions[collection]?.contains(permission) ?? false;
  }

  bool canAccessDepartment(String department) {
    if (isSuperAdmin) return true;
    return departments.contains(department);
  }

  bool canAccessCollection(String department, String collection) {
    if (isSuperAdmin) return true;
    if (!departments.contains(department)) return false;

    final allowed = allowedCollections[department];
    if (allowed == null) return false;
    return allowed.contains(collection);
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

    final rawAllowed = json['allowedCollections'] as Map<String, dynamic>? ?? {};
    final parsedAllowed = <String, List<String>>{};
    rawAllowed.forEach((key, value) {
      if (value is List) {
        parsedAllowed[key] = value.cast<String>();
      }
    });

    // Departman bazında database yetkileri
    final rawDbPerms =
        json['databasePermissions'] as Map<String, dynamic>? ?? {};
    final parsedDbPerms = <String, Set<Permission>>{};
    rawDbPerms.forEach((dept, codes) {
      if (codes is List) {
        parsedDbPerms[dept] = codes
            .cast<String>()
            .map((code) => PermissionExtension.fromCode(code))
            .whereType<Permission>()
            .toSet();
      }
    });

    // Koleksiyon bazında veri yetkileri
    final rawColPerms =
        json['collectionPermissions'] as Map<String, dynamic>? ?? {};
    final parsedColPerms = <String, Set<Permission>>{};
    rawColPerms.forEach((col, codes) {
      if (codes is List) {
        parsedColPerms[col] = codes
            .cast<String>()
            .map((code) => PermissionExtension.fromCode(code))
            .whereType<Permission>()
            .toSet();
      }
    });

    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRoleExtension.fromCode(json['role'] as String? ?? ''),
      departments: rawDepartments.toSet(),
      allowedCollections: parsedAllowed,
      permissions: rawPermissions
          .map((code) => PermissionExtension.fromCode(code))
          .whereType<Permission>()
          .toSet(),
      databasePermissions: parsedDbPerms,
      collectionPermissions: parsedColPerms,
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
      'allowedCollections': allowedCollections,
      'permissions': permissions.map((p) => p.code).toList(),
      'databasePermissions': databasePermissions.map(
        (dept, perms) => MapEntry(dept, perms.map((p) => p.code).toList()),
      ),
      'collectionPermissions': collectionPermissions.map(
        (col, perms) => MapEntry(col, perms.map((p) => p.code).toList()),
      ),
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
    Map<String, List<String>>? allowedCollections,
    Set<Permission>? permissions,
    Map<String, Set<Permission>>? databasePermissions,
    Map<String, Set<Permission>>? collectionPermissions,
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
      allowedCollections: allowedCollections ?? this.allowedCollections,
      permissions: permissions ?? this.permissions,
      databasePermissions: databasePermissions ?? this.databasePermissions,
      collectionPermissions:
          collectionPermissions ?? this.collectionPermissions,
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
