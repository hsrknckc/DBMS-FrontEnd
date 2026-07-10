import 'permission.dart';

enum UserRole {
  superAdmin,
  user,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final Set<Permission> permissions;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? lastLogoutAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.lastLoginAt,
    this.lastLogoutAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool hasPermission(Permission permission) {
    if (isSuperAdmin) {
      return true;
    }

    return permissions.contains(permission);
  }

  String get roleLabel {
    if (isSuperAdmin) {
      return 'Super Admin';
    }

    return department;
  }

  String get initials {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    UserRole? role,
    Set<Permission>? permissions,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? lastLogoutAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLogoutAt: lastLogoutAt ?? this.lastLogoutAt,
    );
  }
}