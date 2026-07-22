import '../../core/services/tcp_socket_service.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// TCP/IP soket üzerinden data explorer CRUD + export/import işlemleri.
///
/// Protokol aksiyonları:
///   records.list    → {databaseId, collectionName, searchQuery?}
///   records.getById → {id}
///   records.create  → {databaseId, collectionName, data}
///   records.update  → {record}
///   records.delete  → {id}
///   records.export  → {databaseId, collectionName, format}
///   records.import  → {databaseId, collectionName, records:[...]}
class TcpDataExplorerRepository implements DataExplorerRepository {
  final TcpSocketService _tcp;
  final String? Function() _tokenProvider;

  TcpDataExplorerRepository(this._tcp, this._tokenProvider);

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    final response = await _tcp.send(
      action: 'records.list',
      payload: {
        'databaseId': databaseId,
        'collectionName': collectionName,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'searchQuery': searchQuery,
      },
      token: _tokenProvider(),
    );
    final list =
        (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(DataRecord.fromJson).toList();
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    final response = await _tcp.send(
      action: 'records.getById',
      payload: {'id': id},
      token: _tokenProvider(),
    );
    return DataRecord.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    final response = await _tcp.send(
      action: 'records.create',
      payload: {
        'databaseId': databaseId,
        'collectionName': collectionName,
        'data': data,
      },
      token: _tokenProvider(),
    );
    return DataRecord.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    final response = await _tcp.send(
      action: 'records.update',
      payload: record.toJson(),
      token: _tokenProvider(),
    );
    return DataRecord.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _tcp.send(
      action: 'records.delete',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  }) async {
    final response = await _tcp.send(
      action: 'records.export',
      payload: {
        'databaseId': databaseId,
        'collectionName': collectionName,
        'format': format,
      },
      token: _tokenProvider(),
    );
    // Sunucu dosya içeriği veya indirme URL'i döner
    return response['data']?.toString() ?? '';
  }

  @override
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _tcp.send(
      action: 'records.import',
      payload: {
        'databaseId': databaseId,
        'collectionName': collectionName,
        'records': records,
      },
      token: _tokenProvider(),
    );
    return (response['data']?['importedCount'] as num?)?.toInt() ??
        records.length;
  }
}
