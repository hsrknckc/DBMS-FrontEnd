import 'package:dio/dio.dart';
import '../../models/app_user.dart';
import 'auth_repository.dart';

/// Gerçek backend için HTTP auth implementasyonu.
///
/// Backend hazır olduğunda [MockAuthRepository] yerine bu sınıf kullanılır.
/// Sadece [repository_providers.dart]'taki tek satırı değiştirmek yeterlidir.
class HttpAuthRepository implements AuthRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpAuthRepository(this._dio);

  @override
  Future<AppUser> login(String email, String password) async {
    // TODO: POST /auth/login
    // Beklenen istek gövdesi: {"email": email, "password": password}
    // Beklenen yanıt: {"token": "...", "user": {...}}
    // Token'ı shared_preferences'a kaydet.
    throw UnimplementedError('HttpAuthRepository.login — backend bağlantısı bekleniyor.');
  }

  @override
  Future<void> logout() async {
    // TODO: POST /auth/logout
    // Header: Authorization: Bearer <token>
    // Token'ı shared_preferences'tan sil.
    throw UnimplementedError('HttpAuthRepository.logout — backend bağlantısı bekleniyor.');
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // TODO: POST /auth/password-reset
    // Beklenen istek gövdesi: {"email": email}
    throw UnimplementedError('HttpAuthRepository.requestPasswordReset — backend bağlantısı bekleniyor.');
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    // TODO: GET /auth/me
    // Header: Authorization: Bearer <token>
    // Token shared_preferences'tan okunur.
    // 401 yanıtında null döner.
    throw UnimplementedError('HttpAuthRepository.getCurrentUser — backend bağlantısı bekleniyor.');
  }
}
