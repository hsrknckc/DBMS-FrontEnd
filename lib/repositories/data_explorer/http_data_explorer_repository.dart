import 'package:dio/dio.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// Gerçek backend için HTTP data explorer implementasyonu.
class HttpDataExplorerRepository implements DataExplorerRepository {
  // ignore: unused_field
  final Dio _dio;

  HttpDataExplorerRepository(this._dio);

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    // TODO: GET /databases/:databaseId/collections/:collectionName/records
    //       ?search=<searchQuery>
    // Yanıt: [{"_id": "...", "data": {...}, ...}]
    throw UnimplementedError('HttpDataExplorerRepository.getRecords');
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    // TODO: GET /records/:id
    throw UnimplementedError('HttpDataExplorerRepository.getRecordById');
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    // TODO: POST /databases/:databaseId/collections/:collectionName/records
    // İstek gövdesi: {"data": {...}}
    throw UnimplementedError('HttpDataExplorerRepository.createRecord');
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    // TODO: PUT /records/:id
    // İstek gövdesi: {"data": record.data}
    throw UnimplementedError('HttpDataExplorerRepository.updateRecord');
  }

  @override
  Future<void> deleteRecord(String id) async {
    // TODO: DELETE /records/:id
    throw UnimplementedError('HttpDataExplorerRepository.deleteRecord');
  }

  @override
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  }) async {
    // TODO: GET /databases/:databaseId/collections/:collectionName/export?format=json|csv
    // Yanıt: download URL veya raw content
    throw UnimplementedError('HttpDataExplorerRepository.exportRecords');
  }

  @override
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  }) async {
    // TODO: POST /databases/:databaseId/collections/:collectionName/import
    // İstek gövdesi: {"records": [...]}
    // Yanıt: {"importedCount": 42}
    throw UnimplementedError('HttpDataExplorerRepository.importRecords');
  }
}
