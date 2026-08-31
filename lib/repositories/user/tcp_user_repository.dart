import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'user_repository.dart';

/// TCP/IP soket üzerinden kullanıcı CRUD işlemleri (PROTOKOL.md Tek Protokol).
class TcpUserRepository implements UserRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  final List<AppUser> _localUsers = [];

  TcpUserRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null || c.username.isEmpty || c.password.isEmpty) {
      throw const TcpException('Oturum açılmamış (kullanıcı kimliği eksik).');
    }
    return c;
  }

  @override
  Future<List<AppUser>> getUsers({bool includeDeleted = false}) async {
    final c = _getCreds();
    try {
      final response = await _tcp.send(
        action: 'LIST_USERS',
        username: c.username,
        password: c.password,
      );

      final rawData = response['data'];
      if (rawData is List) {
        final fetched = rawData.map((item) {
          if (item is Map<String, dynamic>) return _parseUser(item);
          if (item is Map) return _parseUser(Map<String, dynamic>.from(item));
          return AppUser(
            id: item.toString(),
            name: item.toString(),
            email: item.toString(),
            role: UserRole.user,
            departments: const {},
            permissions: const {},
            isActive: true,
          );
        }).toList();

        _replaceLocalUsers(fetched);
      }
    } catch (_) {}

    final users = _dedupeUsers(_localUsers);
    if (includeDeleted) return users;
    return users.where((u) => u.isActive).toList();
  }

  @override
  Future<AppUser> getUserById(String id) async {
    final users = await getUsers(includeDeleted: true);
    return users.firstWhere(
      (u) => u.id == id || u.email == id,
      orElse: () => AppUser(
        id: id,
        name: id,
        email: id,
        role: UserRole.user,
        departments: const {},
        permissions: const {},
        isActive: true,
      ),
    );
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    Set<String> departments = const {},
    Set<Permission> permissions = const {},
  }) async {
    final c = _getCreds();

    final response = await _tcp.send(
      action: 'CREATE_USER',
      username: c.username,
      password: c.password,
      document: {
        'name': name,
        'email': email,
        'password': password,
        'departments': departments.toList(),
        'permissions': permissions.map((p) => p.name).toList(),
      },
    );

    final rawData = response['data'];
    AppUser newU;
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) {
        newU = _parseUser(first);
      } else if (first is Map) {
        newU = _parseUser(Map<String, dynamic>.from(first));
      } else {
        newU = AppUser(
          id: email,
          name: name,
          email: email,
          role: UserRole.user,
          departments: departments.isEmpty ? {'General'} : departments,
          permissions: permissions.isEmpty
              ? Permission.values.toSet()
              : permissions,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
    } else {
      newU = AppUser(
        id: email,
        name: name,
        email: email,
        role: UserRole.user,
        departments: departments.isEmpty ? {'General'} : departments,
        permissions: permissions.isEmpty
            ? Permission.values.toSet()
            : permissions,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    _upsertLocalUser(newU);
    return newU;
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'UPDATE_USER',
      username: c.username,
      password: c.password,
      filter: {'id': user.id},
      document: _serializeUser(user),
    );

    final index = _localUsers.indexWhere(
      (u) => u.id == user.id || u.email == user.email,
    );
    if (index != -1) {
      _localUsers[index] = user;
    }

    return user;
  }

  @override
  Future<void> softDeleteUser(String id) async {
    final c = _getCreds();
    _localUsers.removeWhere((u) => u.id == id || u.email == id);

    await _tcp.send(
      action: 'DELETE_USER',
      username: c.username,
      password: c.password,
      filter: {'id': id},
    );
  }

  @override
  Future<void> restoreUser(String id) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'RESTORE_USER',
      username: c.username,
      password: c.password,
      filter: {'id': id},
    );

    final index = _localUsers.indexWhere((u) => u.id == id || u.email == id);
    if (index != -1) {
      _localUsers[index] = _localUsers[index].copyWith(isActive: true);
    }
  }

  @override
  Future<void> permanentlyDeleteUser(String id) async {
    final c = _getCreds();
    _localUsers.removeWhere((u) => u.id == id || u.email == id);

    await _tcp.send(
      action: 'DROP_USER',
      username: c.username,
      password: c.password,
      filter: {'id': id},
    );
  }

  @override
  Future<AppUser> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
    Map<String, List<String>> allowedCollections = const {},
    Map<String, Set<Permission>> databasePermissions = const {},
    Map<String, Set<Permission>> collectionPermissions = const {},
  }) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'UPDATE_USER_PERMISSIONS',
      username: c.username,
      password: c.password,
      filter: {'id': userId},
      document: {
        'departments': departments.toList(),
        'allowedCollections': allowedCollections,
        'permissions': permissions.map((p) => p.name).toList(),
        'databasePermissions': _serializePermissionMap(databasePermissions),
        'collectionPermissions': _serializePermissionMap(collectionPermissions),
      },
    );

    final index = _localUsers.indexWhere(
      (u) => u.id == userId || u.email == userId,
    );

    AppUser updated;
      if (index != -1) {
      updated = _localUsers[index].copyWith(
        departments: departments,
        allowedCollections: allowedCollections,
        permissions: permissions,
        databasePermissions: databasePermissions,
        collectionPermissions: collectionPermissions,
      );
      _upsertLocalUser(updated);
    } else {
      updated = AppUser(
        id: userId,
        name: userId.split('@').first,
        email: userId,
        role: UserRole.user,
        departments: departments,
        allowedCollections: allowedCollections,
        permissions: permissions,
        databasePermissions: databasePermissions,
        collectionPermissions: collectionPermissions,
        isActive: true,
      );
      _upsertLocalUser(updated);
    }

    return updated;
  }

  @override
  Future<void> forcePasswordReset(String userId) async {
    final c = _getCreds();
    await _tcp.send(
      action: 'RESET_USER_PASSWORD',
      username: c.username,
      password: c.password,
      filter: {'id': userId},
    );
  }

  Set<Permission> _parsePermissions(dynamic raw) {
    if (raw is! List) return {};

    return raw.map((item) => item.toString()).map((value) {
      return Permission.values.firstWhere(
        (p) => p.name == value || p.code == value,
        orElse: () => Permission.databaseView,
      );
    }).toSet();
  }

  Map<String, List<String>> _parseStringListMap(dynamic raw) {
    final result = <String, List<String>>{};
    if (raw is! Map) return result;

    raw.forEach((key, value) {
      if (value is List) {
        result[key.toString()] = value.map((item) => item.toString()).toList();
      }
    });

    return result;
  }

  Map<String, Set<Permission>> _parsePermissionMap(dynamic raw) {
    final result = <String, Set<Permission>>{};
    if (raw is! Map) return result;

    raw.forEach((key, value) {
      result[key.toString()] = _parsePermissions(value);
    });

    return result;
  }

  Map<String, List<String>> _serializePermissionMap(
    Map<String, Set<Permission>> permissions,
  ) {
    return permissions.map(
      (key, value) =>
          MapEntry(key, value.map((permission) => permission.name).toList()),
    );
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  AppUser _parseUser(Map<String, dynamic> data) {
    final roleStr = data['role']?.toString() ?? 'user';
    final role = roleStr == 'superAdmin' || roleStr == 'SUPER_ADMIN'
        ? UserRole.superAdmin
        : UserRole.user;

    final permissions = _parsePermissions(data['permissions']);
    final deptList = (data['departments'] as List<dynamic>? ?? [])
        .cast<String>();

    final allowedCollections = _parseStringListMap(data['allowedCollections']);
    final databasePermissions = _parsePermissionMap(
      data['databasePermissions'],
    );
    final collectionPermissions = _parsePermissionMap(
      data['collectionPermissions'],
    );

    return AppUser(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      departments: deptList.isEmpty ? {'General'} : deptList.toSet(),
      allowedCollections: allowedCollections,
      databasePermissions: databasePermissions,
      collectionPermissions: collectionPermissions,
      permissions: permissions,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> _serializeUser(AppUser user) => {
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'role': user.role.name,
    'departments': user.departments.toList(),
    'allowedCollections': user.allowedCollections,
    'permissions': user.permissions.map((p) => p.name).toList(),
    'databasePermissions': _serializePermissionMap(user.databasePermissions),
    'collectionPermissions': _serializePermissionMap(
      user.collectionPermissions,
    ),
    'isActive': user.isActive,
  };

  void _replaceLocalUsers(List<AppUser> users) {
    _localUsers
      ..clear()
      ..addAll(_dedupeUsers(users));
  }

  void _upsertLocalUser(AppUser user) {
    final index = _localUsers.indexWhere((item) => _sameUser(item, user));
    if (index == -1) {
      _localUsers.add(user);
    } else {
      _localUsers[index] = user;
    }
  }

  List<AppUser> _dedupeUsers(Iterable<AppUser> users) {
    final result = <AppUser>[];
    for (final user in users) {
      final index = result.indexWhere((item) => _sameUser(item, user));
      if (index == -1) {
        result.add(user);
      } else {
        result[index] = user;
      }
    }
    return result;
  }

  bool _sameUser(AppUser first, AppUser second) {
    final firstId = first.id.trim();
    final secondId = second.id.trim();
    if (firstId.isNotEmpty && secondId.isNotEmpty && firstId == secondId) {
      return true;
    }

    final firstEmail = first.email.trim().toLowerCase();
    final secondEmail = second.email.trim().toLowerCase();
    return firstEmail.isNotEmpty &&
        secondEmail.isNotEmpty &&
        firstEmail == secondEmail;
  }
}
