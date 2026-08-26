import '../../models/app_user.dart';

/// Kimlik doğrulama işlemleri için soyut arayüz.
///
/// Backend hazır olduğunda [MockAuthRepository] yerine
/// [HttpAuthRepository] kullanılacak — sadece provider değişir.
abstract class AuthRepository {
  /// Kullanıcı girişi. Başarılı olursa [AppUser] döner.
  /// Hata durumunda exception fırlatır.
  Future<AppUser> login(String email, String password);

  /// Oturumu kapatır. Token varsa geçersiz kılar.
  Future<void> logout();

  /// Şifre sıfırlama bağlantısı/kodu gönderir.
  Future<void> requestPasswordReset(String email);

  Future<void> confirmPasswordReset({
    required String email,
    required String resetCode,
    required String newPassword,
  });
  
  /// Kayıtlı token ile mevcut kullanıcıyı getirir.
  /// Token yoksa veya geçersizse null döner.
  Future<AppUser?> getCurrentUser();
}
