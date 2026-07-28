import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// TCP/IP soket üzerinden data explorer CRUD + export/import işlemleri (Yeni Tek Protokol).
///
/// Aksiyonlar:
///   PING              → MongoDB erişilebilirlik kontrolü
///   LIST_COLLECTIONS  → database
///   CREATE_COLLECTION → database, collection
///   DROP_COLLECTION   → database, collection
///   READ              → database, collection, filter
///   WRITE             → database, collection, document
///   UPDATE            → database, collection, filter, document
///   DELETE            → database, collection, filter
class TcpDataExplorerRepository implements DataExplorerRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  TcpDataExplorerRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null) {
      throw const TcpException('Oturum açılmamış (kimlik bilgisi eksik).');
    }
    return c;
  }

  /// MongoDB erişilebilirlik kontrolü (PING)
  Future<bool> ping() async {
    try {
      final c = _getCreds();
      final response = await _tcp.send(
        action: 'PING',
        username: c.username,
        password: c.password,
      );
      return response['status'] == 'OK';
    } catch (_) {
      return false;
    }
  }

  /// Veritabanındaki koleksiyon adlarını çekme (LIST_COLLECTIONS)
  Future<List<String>> getCollections(String databaseName) async {
    try {
      final c = _getCreds();
      final response = await _tcp.send(
        action: 'LIST_COLLECTIONS',
        username: c.username,
        password: c.password,
        database: databaseName,
      );
      final rawData = response['data'];
      if (rawData is List) {
        return rawData.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'READ',
      username: c.username,
      password: c.password,
      database: databaseId,
      collection: collectionName,
      filter: (searchQuery != null && searchQuery.isNotEmpty)
          ? {'searchQuery': searchQuery}
          : {},
    );

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }

    return rawData.map((doc) {
      if (doc is Map<String, dynamic>) {
        return DataRecord.fromJson(doc);
      } else if (doc is Map) {
        return DataRecord.fromJson(Map<String, dynamic>.from(doc));
      }
      return DataRecord(
        id: doc.toString(),
        databaseId: databaseId,
        collectionName: collectionName,
        data: {'value': doc},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'READ',
      username: c.username,
      password: c.password,
      filter: {'id': id},
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return DataRecord.fromJson(first);
      if (first is Map) return DataRecord.fromJson(Map<String, dynamic>.from(first));
    }

    return DataRecord(
      id: id,
      databaseId: '',
      collectionName: '',
      data: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'WRITE',
      username: c.username,
      password: c.password,
      database: databaseId,
      collection: collectionName,
      document: data,
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return DataRecord.fromJson(first);
      if (first is Map) return DataRecord.fromJson(Map<String, dynamic>.from(first));
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
    final c = _getCreds();
    final response = await _tcp.send(
      action: 'UPDATE',
      username: c.username,
      password: c.password,
      database: record.databaseId,
      collection: record.collectionName,
      filter: {'id': record.id},
      document: record.data,
    );

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) return DataRecord.fromJson(first);
      if (first is Map) return DataRecord.fromJson(Map<String, dynamic>.from(first));
    }

    return record;
  }

  @override
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  }) async {
    final c = _getCreds();
    await _tcp.send(
      action: 'DELETE',
      username: c.username,
      password: c.password,
      database: databaseId,
      collection: collectionName,
      filter: {'id': id},
    );
  }

  @override
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  }) async {
    final records = await getRecords(
      databaseId: databaseId,
      collectionName: collectionName,
    );
    return records.map((r) => r.toJson()).toList().toString();
  }

  @override
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  }) async {
    int count = 0;
    for (final rec in records) {
      try {
        await createRecord(
          databaseId: databaseId,
          collectionName: collectionName,
          data: rec,
        );
        count++;
      } catch (_) {}
    }
    return count;
  }
}
