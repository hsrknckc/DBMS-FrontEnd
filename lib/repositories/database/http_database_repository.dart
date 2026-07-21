import 'package:dio/dio.dart';
import '../../models/database_item.dart';
import 'database_repository.dart';

/// Gerçek backend için HTTP database implementasyonu.
class HttpDatabaseRepository implements DatabaseRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpDatabaseRepository(this._dio);

  @override
  Future<List<DatabaseItem>> getDatabases({bool includeDeleted = false}) async {
    // TODO: GET /databases?includeDeleted=true|false
    // Yanıt: [{"_id": "...", "name": "...", ...}]
    // DatabaseItem.fromJson ile dönüştür.
    throw UnimplementedError('HttpDatabaseRepository.getDatabases');
  }

  @override
  Future<DatabaseItem> getDatabaseById(String id) async {
    // TODO: GET /databases/:id
    throw UnimplementedError('HttpDatabaseRepository.getDatabaseById');
  }

  @override
  Future<DatabaseItem> createDatabase({
    required String name,
    required String department,
    required String description,
  }) async {
    // TODO: POST /databases
    // İstek gövdesi: {"name", "department", "description"}
    throw UnimplementedError('HttpDatabaseRepository.createDatabase');
  }

  @override
  Future<DatabaseItem> updateDatabase(DatabaseItem item) async {
    // TODO: PUT /databases/:id
    throw UnimplementedError('HttpDatabaseRepository.updateDatabase');
  }

  @override
  Future<void> softDeleteDatabase(String id) async {
    // TODO: DELETE /databases/:id  (soft-delete)
    throw UnimplementedError('HttpDatabaseRepository.softDeleteDatabase');
  }

  @override
  Future<void> restoreDatabase(String id) async {
    // TODO: PATCH /databases/:id/restore
    throw UnimplementedError('HttpDatabaseRepository.restoreDatabase');
  }

  @override
  Future<void> permanentlyDeleteDatabase(String id) async {
    // TODO: DELETE /databases/:id/permanent
    throw UnimplementedError('HttpDatabaseRepository.permanentlyDeleteDatabase');
  }
}
