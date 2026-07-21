import 'package:dio/dio.dart';
import '../../models/app_user.dart';
import '../../models/permission.dart';
import 'user_repository.dart';

/// Gerçek backend için HTTP user implementasyonu.
class HttpUserRepository implements UserRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpUserRepository(this._dio);

  @override
  Future<List<AppUser>> getUsers({bool includeDeleted = false}) async {
    // TODO: GET /users?includeDeleted=true|false
    // Yanıt: [{"_id": "...", "name": "...", ...}]
    // AppUser.fromJson ile dönüştür.
    throw UnimplementedError('HttpUserRepository.getUsers');
  }

  @override
  Future<AppUser> getUserById(String id) async {
    // TODO: GET /users/:id
    throw UnimplementedError('HttpUserRepository.getUserById');
  }

  @override
  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    Set<String> departments = const {},
    Set<Permission> permissions = const {},
  }) async {
    // TODO: POST /users
    // İstek gövdesi: {"name", "email", "password", "departments", "permissions"}
    throw UnimplementedError('HttpUserRepository.createUser');
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    // TODO: PUT /users/:id
    // İstek gövdesi: user.toJson()
    throw UnimplementedError('HttpUserRepository.updateUser');
  }

  @override
  Future<void> softDeleteUser(String id) async {
    // TODO: DELETE /users/:id  (soft-delete)
    // Backend isDeleted=true yapar, kalıcı silmez.
    throw UnimplementedError('HttpUserRepository.softDeleteUser');
  }

  @override
  Future<void> restoreUser(String id) async {
    // TODO: PATCH /users/:id/restore
    throw UnimplementedError('HttpUserRepository.restoreUser');
  }

  @override
  Future<void> permanentlyDeleteUser(String id) async {
    // TODO: DELETE /users/:id/permanent
    throw UnimplementedError('HttpUserRepository.permanentlyDeleteUser');
  }

  @override
  Future<AppUser> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
  }) async {
    // TODO: PATCH /users/:id/permissions
    // İstek gövdesi: {"departments": [...], "permissions": [...]}
    throw UnimplementedError('HttpUserRepository.updatePermissions');
  }

  @override
  Future<void> forcePasswordReset(String userId) async {
    // TODO: POST /users/:id/force-password-reset
    throw UnimplementedError('HttpUserRepository.forcePasswordReset');
  }
}
