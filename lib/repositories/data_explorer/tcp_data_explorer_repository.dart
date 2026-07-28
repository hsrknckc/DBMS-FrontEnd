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
    Map<String, dynamic> response;
    try {
      response = await _tcp.send(
        action: 'READ',
        payload: {
          'database': databaseId,
          'databaseId': databaseId,
          'collection': collectionName,
          'collectionName': collectionName,
          'filter': searchQuery != null && searchQuery.isNotEmpty
              ? {'searchQuery': searchQuery}
              : {},
        },
        token: _tokenProvider(),
      );
    } catch (_) {
      response = await _tcp.send(
        action: 'records.list',
        payload: {
          'database': databaseId,
          'databaseId': databaseId,
          'collection': collectionName,
          'collectionName': collectionName,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'searchQuery': searchQuery,
        },
        token: _tokenProvider(),
      );
    }

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }
    final list = rawData.cast<Map<String, dynamic>>();
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
    Map<String, dynamic> response;
    try {
      response = await _tcp.send(
        action: 'WRITE',
        payload: {
          'database': databaseId,
          'databaseId': databaseId,
          'collection': collectionName,
          'collectionName': collectionName,
          'document': data,
          'data': data,
        },
        token: _tokenProvider(),
      );
    } catch (_) {
      response = await _tcp.send(
        action: 'records.create',
        payload: {
          'database': databaseId,
          'databaseId': databaseId,
          'collection': collectionName,
          'collectionName': collectionName,
          'document': data,
          'data': data,
        },
        token: _tokenProvider(),
      );
    }

    final resData = response['data'];
    if (resData is Map<String, dynamic>) {
      return DataRecord.fromJson(resData);
    }
    return DataRecord(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      databaseId: databaseId,
      collectionName: collectionName,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    Map<String, dynamic> response;
    try {
      response = await _tcp.send(
        action: 'UPDATE',
        payload: {
          'id': record.id,
          'database': record.databaseId,
          'databaseId': record.databaseId,
          'collection': record.collectionName,
          'collectionName': record.collectionName,
          'filter': {'id': record.id},
          'document': record.data,
          'data': record.data,
        },
        token: _tokenProvider(),
      );
    } catch (_) {
      response = await _tcp.send(
        action: 'records.update',
        payload: {
          'id': record.id,
          'database': record.databaseId,
          'databaseId': record.databaseId,
          'collection': record.collectionName,
          'collectionName': record.collectionName,
          'document': record.data,
          'data': record.data,
        },
        token: _tokenProvider(),
      );
    }

    final resData = response['data'];
    if (resData is Map<String, dynamic>) {
      return DataRecord.fromJson(resData);
    }
    return record;
  }

  @override
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  }) async {
    try {
      await _tcp.send(
        action: 'DELETE',
        payload: {
          'id': id,
          'filter': {'id': id},
          if (databaseId != null) 'database': databaseId,
          if (databaseId != null) 'databaseId': databaseId,
          if (collectionName != null) 'collection': collectionName,
          if (collectionName != null) 'collectionName': collectionName,
        },
        token: _tokenProvider(),
      );
    } catch (_) {
      await _tcp.send(
        action: 'records.delete',
        payload: {
          'id': id,
          if (databaseId != null) 'database': databaseId,
          if (databaseId != null) 'databaseId': databaseId,
          if (collectionName != null) 'collection': collectionName,
          if (collectionName != null) 'collectionName': collectionName,
        },
        token: _tokenProvider(),
      );
    }
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
