import 'permission.dart';

enum UserRole {
  superAdmin,
  user,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Kullanıcının erişebildiği departmanlar.
  final Set<String> departments;

  /// Super Admin tarafından verilen işlem yetkileri.
  final Set<Permission> permissions;

  final bool isActive;

  final DateTime? lastLoginAt;
  final DateTime? lastLogoutAt;

  /// Kullanıcı ilk girişte şifresini değiştirmeli mi?
  final bool mustChangePassword;

  /// Kullanıcı soft delete ile silindi mi?
  final bool isDeleted;

  /// Kullanıcının silinme zamanı.
  final DateTime? deletedAt;

  /// Kullanıcıyı silen Super Admin'in ID'si.
  final String? deletedBy;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departments,
    required this.permissions,
    required this.isActive,
    this.lastLoginAt,
    this.lastLogoutAt,
    this.mustChangePassword = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  bool get isSuperAdmin {
    return role == UserRole.superAdmin;
  }

  bool hasPermission(Permission permission) {
    if (isSuperAdmin) {
      return true;
    }

    return permissions.contains(permission);
  }

  bool canAccessDepartment(String department) {
    if (isSuperAdmin) {
      return true;
    }

    return departments.contains(department);
  }

  String get roleLabel {
    return isSuperAdmin ? 'Super Admin' : 'User';
  }

  String get departmentLabel {
    if (isSuperAdmin) {
      return 'Tüm Departmanlar';
    }

    if (departments.isEmpty) {
      return 'Departman atanmadı';
    }

    return departments.join(', ');
  }

  String get initials {
    final nameParts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return 'U';
    }

    if (nameParts.length == 1) {
      return nameParts.first.substring(0, 1).toUpperCase();
    }

    final firstInitial = nameParts.first.substring(0, 1);
    final lastInitial = nameParts.last.substring(0, 1);

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    Set<String>? departments,
    Set<Permission>? permissions,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? lastLogoutAt,
    bool? mustChangePassword,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,

    /// Bu alanlar nullable değerleri bilinçli şekilde temizlemek için kullanılır.
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
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLogoutAt: lastLogoutAt ?? this.lastLogoutAt,
      mustChangePassword:
          mustChangePassword ?? this.mustChangePassword,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt
          ? null
          : deletedAt ?? this.deletedAt,
      deletedBy: clearDeletedBy
          ? null
          : deletedBy ?? this.deletedBy,
    );
  }
}