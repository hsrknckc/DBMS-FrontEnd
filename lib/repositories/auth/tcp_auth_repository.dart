import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'auth_repository.dart';

/// TCP/IP soket üzerinden kimlik doğrulama işlemleri (Yeni Tek Protokol).
///
/// Protokol aksiyonu:
///   LOGIN → {username, password}
class TcpAuthRepository implements AuthRepository {
  final TcpSocketService _tcp;
  final StateController<Credentials?>? _credentialsNotifier;

  Credentials? _activeCredentials;

  TcpAuthRepository(
    this._tcp, {
    StateController<Credentials?>? credentialsNotifier,
  }) : _credentialsNotifier = credentialsNotifier;

  @override
  Future<AppUser> login(String email, String password) async {
    final response = await _tcp.send(
      action: 'LOGIN',
      username: email,
      password: password,
    );

    final credentials = Credentials(email, password);
    _activeCredentials = credentials;
    if (_credentialsNotifier != null) {
      _credentialsNotifier.state = credentials;
    }

    final rawData = response['data'];
    Map<String, dynamic> userMap = {};

    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) {
        userMap = first;
      } else if (first is Map) {
        userMap = Map<String, dynamic>.from(first);
      }
    } else if (rawData is Map<String, dynamic>) {
      userMap = rawData;
    }

    // E-posta dönmediyse istekle gönderilen email'i yedekle
    if (!userMap.containsKey('email') || userMap['email'] == null) {
      userMap['email'] = email;
    }

    return _parseUser(userMap);
  }

  @override
  Future<void> logout() async {
    _activeCredentials = null;
    if (_credentialsNotifier != null) {
      _credentialsNotifier.state = null;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // Sunucu tarafında parola sıfırlama endpoint'i bulunmuyor.
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final creds = _activeCredentials ?? _credentialsNotifier?.state;
    if (creds == null) return null;

    try {
      final response = await _tcp.send(
        action: 'LOGIN',
        username: creds.username,
        password: creds.password,
      );

      final rawData = response['data'];
      Map<String, dynamic> userMap = {};
      if (rawData is List && rawData.isNotEmpty) {
        final first = rawData.first;
        if (first is Map<String, dynamic>) {
          userMap = first;
        } else if (first is Map) {
          userMap = Map<String, dynamic>.from(first);
        }
      } else if (rawData is Map<String, dynamic>) {
        userMap = rawData;
      }

      if (!userMap.containsKey('email') || userMap['email'] == null) {
        userMap['email'] = creds.username;
      }

      return _parseUser(userMap);
    } catch (_) {
      await logout();
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
      name: data['name'] as String? ?? (data['email'] as String? ?? '').split('@').first,
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
