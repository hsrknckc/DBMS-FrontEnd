import '../../core/services/tcp_socket_service.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'user_repository.dart';

/// TCP/IP soket üzerinden kullanıcı CRUD işlemleri.
///
/// Protokol aksiyonları:
///   users.list             → {includeDeleted}
///   users.getById          → {id}
///   users.create           → {name, email, password, departments, permissions}
///   users.update           → {user}
///   users.softDelete       → {id}
///   users.restore          → {id}
///   users.permanentDelete  → {id}
///   users.updatePermissions→ {userId, departments, permissions}
///   users.forceReset       → {userId}
class TcpUserRepository implements UserRepository {
  final TcpSocketService _tcp;
  final String? Function() _tokenProvider;

  TcpUserRepository(this._tcp, this._tokenProvider);

  @override
  Future<List<AppUser>> getUsers({bool includeDeleted = false}) async {
    final response = await _tcp.send(
      action: 'users.list',
      payload: {'includeDeleted': includeDeleted},
      token: _tokenProvider(),
    );
    final list = (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(_parseUser).toList();
  }

  @override
  Future<AppUser> getUserById(String id) async {
    final response = await _tcp.send(
      action: 'users.getById',
      payload: {'id': id},
      token: _tokenProvider(),
    );
    return _parseUser(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    Set<String> departments = const {},
    Set<Permission> permissions = const {},
  }) async {
    final response = await _tcp.send(
      action: 'users.create',
      payload: {
        'name': name,
        'email': email,
        'password': password,
        'departments': departments.toList(),
        'permissions': permissions.map((p) => p.name).toList(),
      },
      token: _tokenProvider(),
    );
    return _parseUser(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    final response = await _tcp.send(
      action: 'users.update',
      payload: _serializeUser(user),
      token: _tokenProvider(),
    );
    return _parseUser(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> softDeleteUser(String id) async {
    await _tcp.send(
      action: 'users.softDelete',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<void> restoreUser(String id) async {
    await _tcp.send(
      action: 'users.restore',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<void> permanentlyDeleteUser(String id) async {
    await _tcp.send(
      action: 'users.permanentDelete',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<AppUser> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
  }) async {
    final response = await _tcp.send(
      action: 'users.updatePermissions',
      payload: {
        'userId': userId,
        'departments': departments.toList(),
        'permissions': permissions.map((p) => p.name).toList(),
      },
      token: _tokenProvider(),
    );
    return _parseUser(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> forcePasswordReset(String userId) async {
    await _tcp.send(
      action: 'users.forceReset',
      payload: {'userId': userId},
      token: _tokenProvider(),
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
