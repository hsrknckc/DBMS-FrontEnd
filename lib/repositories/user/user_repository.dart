import '../../models/app_user.dart';
import '../../models/permission.dart';

/// Kullanıcı CRUD işlemleri için soyut arayüz.
abstract class UserRepository {
  /// Tüm kullanıcıları getirir.
  /// [includeDeleted] true ise soft-deleted kullanıcılar da dahil edilir.
  Future<List<AppUser>> getUsers({bool includeDeleted = false});

  /// Tek kullanıcıyı ID ile getirir.
  Future<AppUser> getUserById(String id);

  /// Yeni kullanıcı oluşturur.
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    Set<String> departments = const {},
    Set<Permission> permissions = const {},
  });

  /// Kullanıcı bilgilerini günceller.
  Future<AppUser> updateUser(AppUser user);

  /// Kullanıcıyı soft-delete yapar (geri yüklenebilir).
  Future<void> softDeleteUser(String id);

  /// Soft-deleted kullanıcıyı geri yükler.
  Future<void> restoreUser(String id);

  /// Kullanıcıyı kalıcı olarak siler (geri alınamaz).
  Future<void> permanentlyDeleteUser(String id);

  /// Kullanıcının departman ve yetkilerini günceller.
  Future<AppUser> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
    Map<String, List<String>> allowedCollections = const {},
    Map<String, Set<Permission>> databasePermissions = const {},
    Map<String, Set<Permission>> collectionPermissions = const {},
  });

  /// Kullanıcı için şifre sıfırlama zorlar.
  Future<void> forcePasswordReset(String userId);
}
