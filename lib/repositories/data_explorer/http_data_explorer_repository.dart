import 'package:dio/dio.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// Gerçek backend için HTTP data explorer implementasyonu.
class HttpDataExplorerRepository implements DataExplorerRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpDataExplorerRepository(this._dio);

  @override
  Future<List<String>> getCollections(String databaseName) async {
    return [];
  }

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    throw UnimplementedError('HttpDataExplorerRepository.getRecords');
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    throw UnimplementedError('HttpDataExplorerRepository.getRecordById');
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    throw UnimplementedError('HttpDataExplorerRepository.createRecord');
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    throw UnimplementedError('HttpDataExplorerRepository.updateRecord');
  }

  @override
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  }) async {
    throw UnimplementedError('HttpDataExplorerRepository.deleteRecord');
  }

  @override
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  }) async {
    throw UnimplementedError('HttpDataExplorerRepository.exportRecords');
  }

  @override
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  }) async {
    throw UnimplementedError('HttpDataExplorerRepository.importRecords');
  }
}
