import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_user.dart';
import '../../../core/providers/repository_providers.dart';

/// Auth state notifier'ı.
/// Kullanım: ⁠ ref.watch(authNotifierProvider) ⁠
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  // GEÇİCİ: Super Admin olarak otomatik başlat
  /* return AppUser(
  id: 'super-admin-test',
  name: 'Super Admin',
  email: 'admin@company.com',
  role: UserRole.superAdmin,
  departments: const {'IT', 'Database Admin'},
  permissions: Permission.values.toSet(),
  isActive: true,
  createdAt: DateTime.now(),
); */

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> requestPasswordReset(String email) async {
    await ref.read(authRepositoryProvider).requestPasswordReset(email);
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .confirmPasswordReset(
          email: email,
          resetCode: resetCode,
          newPassword: newPassword,
        );
  }

  /// Giriş yapılmış mı?
  bool get isLoggedIn => state.valueOrNull != null;

  /// Mevcut kullanıcı (null-safe)
  AppUser? get currentUser => state.valueOrNull;
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(
  AuthNotifier.new,
);
