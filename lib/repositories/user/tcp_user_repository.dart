import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'user_repository.dart';

/// TCP/IP soket üzerinden kullanıcı CRUD işlemleri (Yeni Tek Protokol).
///
/// Aksiyonlar:
///   LIST_USERS    → Super admin yetkisi gerekir
///   CREATE_USER   → document: {name, email, password, departments, permissions}
class TcpUserRepository implements UserRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  TcpUserRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null) {
      throw const TcpException('Oturum açılmamış (kimlik bilgisi eksik).');
    }
    return c;
  }

  @override
  Future<List<AppUser>> getUsers({bool includeDeleted = false}) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'LIST_USERS',
      username: c.username,
      password: c.password,
    );

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }

    return rawData.map((item) {
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
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return _parseUser(first);
      if (first is Map) return _parseUser(Map<String, dynamic>.from(first));
    }

    return AppUser(
      id: email,
      name: name,
      email: email,
      role: UserRole.user,
      departments: departments,
      permissions: permissions,
      isActive: true,
    );
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'UPDATE_USER',
      username: c.username,
      password: c.password,
      filter: {'id': user.id},
      document: _serializeUser(user),
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return _parseUser(first);
      if (first is Map) return _parseUser(Map<String, dynamic>.from(first));
    }

    return user;
  }

  @override
  Future<void> softDeleteUser(String id) async {
    final c = _getCreds();
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
  }

  @override
  Future<void> permanentlyDeleteUser(String id) async {
    final c = _getCreds();
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
  }) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'UPDATE_USER_PERMISSIONS',
      username: c.username,
      password: c.password,
      filter: {'id': userId},
      document: {
        'departments': departments.toList(),
        'permissions': permissions.map((p) => p.name).toList(),
      },
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return _parseUser(first);
      if (first is Map) return _parseUser(Map<String, dynamic>.from(first));
    }

    final existing = await getUserById(userId);
    return existing.copyWith(
      departments: departments,
      permissions: permissions,
    );
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

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  AppUser _parseUser(Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'user';
    final role = roleStr == 'superAdmin' ? UserRole.superAdmin : UserRole.user;
    final permList = (data['permissions'] as List<dynamic>? ?? []).cast<String>();
    final permissions = permList
        .map((p) => Permission.values.firstWhere(
              (e) => e.name == p,
              orElse: () => Permission.databaseView,
            ))
        .toSet();
    final deptList = (data['departments'] as List<dynamic>? ?? []).cast<String>();

    return AppUser(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      departments: deptList.toSet(),
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
        'permissions': user.permissions.map((p) => p.name).toList(),
        'isActive': user.isActive,
      };
}
