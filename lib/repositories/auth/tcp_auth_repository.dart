import '../../core/services/tcp_socket_service.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'auth_repository.dart';

/// TCP/IP soket üzerinden kimlik doğrulama işlemleri.
///
/// Backend hazır olduğunda [MockAuthRepository] yerine bu sınıfı kullan:
///   `repository_providers.dart` içinde tek satır değiştir.
///
/// Protokol aksiyonları:
///   auth.login             → {email, password}
///   auth.logout            → {token}
///   auth.requestReset      → {email}
///   auth.me                → {token}
class TcpAuthRepository implements AuthRepository {
  final TcpSocketService _tcp;

  /// Oturum tokeni — login sonrası saklanır, diğer isteklerde kullanılır.
  String? _token;

  String? get token => _token;

  TcpAuthRepository(this._tcp);

  @override
  Future<AppUser> login(String email, String password) async {
    final response = await _tcp.send(
      action: 'auth.login',
      payload: {'email': email, 'password': password},
    );

    _token = response['data']?['token'] as String?;
    return _parseUser(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _tcp.send(
      action: 'auth.logout',
      payload: {},
      token: _token,
    );
    _token = null;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _tcp.send(
      action: 'auth.requestReset',
      payload: {'email': email},
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_token == null) return null;

    try {
      final response = await _tcp.send(
        action: 'auth.me',
        payload: {},
        token: _token,
      );
      return _parseUser(response['data'] as Map<String, dynamic>);
    } catch (_) {
      _token = null;
      return null;
    }
  }

  // ── Yardımcı ──────────────────────────────────────────────────────────

  AppUser _parseUser(Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'user';
    final role = roleStr == 'superAdmin'
        ? UserRole.superAdmin
        : UserRole.user;

    final permList =
        (data['permissions'] as List<dynamic>? ?? []).cast<String>();
    final permissions = permList
        .map((p) => Permission.values.firstWhere(
              (e) => e.name == p,
              orElse: () => Permission.databaseView,
            ))
        .toSet();

    final deptList =
        (data['departments'] as List<dynamic>? ?? []).cast<String>();

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
}
