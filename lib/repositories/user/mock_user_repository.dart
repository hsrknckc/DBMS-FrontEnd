import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'user_repository.dart';

/// Sahte kullanıcı verisi — mevcut page'lerdeki hard-coded listeler buraya taşındı.
class MockUserRepository implements UserRepository {
  final List<AppUser> _users = [
    AppUser(
      id: 'user-1',
      name: 'Mehmet Kaya',
      email: 'mehmet.kaya@company.com',
      role: UserRole.user,
      departments: const {'Sensor', 'Signal'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: true,
      lastLoginAt: DateTime(2026, 7, 15, 8, 45),
      lastLogoutAt: DateTime(2026, 7, 14, 17, 20),
    ),
    AppUser(
      id: 'user-2',
      name: 'Zeynep Demir',
      email: 'zeynep.demir@company.com',
      role: UserRole.user,
      departments: const {'Acoustic'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataCreate,
        Permission.dataUpdate,
      },
      isActive: true,
      lastLoginAt: DateTime(2026, 7, 15, 9, 10),
      lastLogoutAt: DateTime(2026, 7, 14, 18, 5),
    ),
    AppUser(
      id: 'user-3',
      name: 'Ahmet Yıldız',
      email: 'ahmet.yildiz@company.com',
      role: UserRole.user,
      departments: const {'Signal'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
      },
      isActive: false,
      lastLoginAt: DateTime(2026, 7, 8, 10, 30),
      lastLogoutAt: DateTime(2026, 7, 8, 16, 55),
    ),
    AppUser(
      id: 'user-4',
      name: 'Elif Arslan',
      email: 'elif.arslan@company.com',
      role: UserRole.user,
      departments: const {'Sensor', 'Acoustic'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: true,
      mustChangePassword: true,
    ),
    AppUser(
      id: 'user-5',
      name: 'Burak Çetin',
      email: 'burak.cetin@company.com',
      role: UserRole.user,
      departments: const {'Sonar'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
      },
      isActive: false,
      isDeleted: true,
      deletedAt: DateTime(2026, 7, 13, 15, 30),
      deletedBy: 'super-admin-1',
    ),
  ];

  @override
  Future<List<AppUser>> getUsers({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (includeDeleted) return List.unmodifiable(_users);
    return _users.where((u) => !u.isDeleted).toList();
  }

  @override
  Future<AppUser> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _users.firstWhere(
      (u) => u.id == id,
      orElse: () => throw Exception('Kullanıcı bulunamadı: $id'),
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
    await Future.delayed(const Duration(milliseconds: 400));
    final newUser = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: UserRole.user,
      departments: departments,
      permissions: permissions,
      isActive: true,
      mustChangePassword: true,
      createdAt: DateTime.now(),
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) throw Exception('Kullanıcı bulunamadı: ${user.id}');
    _users[index] = user;
    return user;
  }

  @override
  Future<void> softDeleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('Kullanıcı bulunamadı: $id');
    _users[index] = _users[index].copyWith(
      isDeleted: true,
      isActive: false,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> restoreUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('Kullanıcı bulunamadı: $id');
    _users[index] = _users[index].copyWith(
      isDeleted: false,
      isActive: true,
      clearDeletedAt: true,
      clearDeletedBy: true,
    );
  }

  @override
  Future<void> permanentlyDeleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _users.removeWhere((u) => u.id == id);
  }

  @override
  Future<AppUser> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw Exception('Kullanıcı bulunamadı: $userId');
    _users[index] = _users[index].copyWith(
      departments: departments,
      permissions: permissions,
    );
    return _users[index];
  }

  @override
  Future<void> forcePasswordReset(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw Exception('Kullanıcı bulunamadı: $userId');
    _users[index] = _users[index].copyWith(mustChangePassword: true);
  }
}
