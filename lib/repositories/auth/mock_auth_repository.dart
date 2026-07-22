import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'auth_repository.dart';

/// Sahte kimlik doğrulama — backend hazır olana kadar kullanılır.
///
/// Geçerli e-posta / şifre kombinasyonları:
///   ahmet.yilmaz@company.com / password123  → superAdmin
///   [diğer herhangi bir e-posta] / password123 → user
class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  static final _mockSuperAdmin = AppUser(
    id: 'super-admin-1',
    name: 'Ahmet Yılmaz',
    email: 'ahmet.yilmaz@company.com',
    role: UserRole.superAdmin,
    departments: const {'IT', 'Database Admin'},
    permissions: Permission.values.toSet(),
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  static final _mockUser = AppUser(
    id: 'user-1',
    name: 'Mehmet Kaya',
    email: 'mehmet.kaya@company.com',
    role: UserRole.user,
    departments: const {'Sensor', 'Signal'},
    // TEST: Tüm yetkiler açık — backend bağlandığında API'den gelecek
    permissions: Permission.values.toSet(),
    isActive: true,
    createdAt: DateTime(2026, 2, 15),
  );

  @override
  Future<AppUser> login(String email, String password) async {
    // Simüle edilmiş ağ gecikmesi
    await Future.delayed(const Duration(milliseconds: 800));

    if (password != 'password123') {
      throw Exception('Geçersiz e-posta veya şifre.');
    }

    final user = email == _mockSuperAdmin.email ? _mockSuperAdmin : _mockUser;
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Mock: her zaman başarılı
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }
}
