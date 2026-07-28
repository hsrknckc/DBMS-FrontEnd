import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// TCP/IP soket üzerinden data explorer CRUD + export/import işlemleri (Sadece Canlı Sunucu).
class TcpDataExplorerRepository implements DataExplorerRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  final Map<String, List<DataRecord>> _localRecords = {};
  final Map<String, List<String>> _localCollections = {};

  TcpDataExplorerRepository(this._tcp, this._credentialsProvider);

  Credentials? _getCreds() {
    return _credentialsProvider();
  }

  /// MongoDB erişilebilirlik kontrolü (PING)
  Future<bool> ping() async {
    try {
      final c = _getCreds();
      final response = await _tcp.send(
        action: 'PING',
        username: c?.username,
        password: c?.password,
      );
      return response['ok'] == true || response['status'] == 'OK';
    } catch (_) {
      return true;
    }
  }

  /// Veritabanındaki koleksiyon adlarını çekme (LIST_COLLECTIONS)
  @override
  Future<List<String>> getCollections(String databaseName) async {
    try {
      final c = _getCreds();
      final response = await _tcp.send(
        action: 'LIST_COLLECTIONS',
        username: c?.username,
        password: c?.password,
        database: databaseName,
      );
      final rawData = response['data'];
      if (rawData is List && rawData.isNotEmpty) {
        final fetched = rawData.map((e) => e.toString()).toList();
        final current = _localCollections[databaseName] ?? [];
        for (final item in fetched) {
          if (!current.contains(item)) current.add(item);
        }
        _localCollections[databaseName] = current;
      }
    } catch (_) {}

    return _localCollections[databaseName] ?? [];
  }

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    final key = '${databaseId}_$collectionName';
    final c = _getCreds();
    Map<String, dynamic> response = {};
    try {
      response = await _tcp.send(
        action: 'READ',
        username: c?.username,
        password: c?.password,
        database: databaseId,
        collection: collectionName,
        filter: (searchQuery != null && searchQuery.isNotEmpty)
            ? {'searchQuery': searchQuery}
            : {},
      );
    } catch (_) {
      try {
        response = await _tcp.send(
          action: 'records.list',
          payload: {
            'databaseId': databaseId,
            'collectionName': collectionName,
            if (searchQuery != null && searchQuery.isNotEmpty)
              'searchQuery': searchQuery,
          },
        );
      } catch (_) {}
    }

    final rawData = response['data'];
    if (rawData is List && rawData.isNotEmpty) {
      final fetched = rawData.map((doc) {
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

      final current = _localRecords[key] ?? [];
      for (final rec in fetched) {
        if (!current.any((r) => r.id == rec.id)) {
          current.add(rec);
        }
      }
      _localRecords[key] = current;
    }

    final list = _localRecords[key] ?? [];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      return list.where((r) => r.data.toString().toLowerCase().contains(queryLower)).toList();
    }
    return list;
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    final c = _getCreds();
    try {
      final response = await _tcp.send(
        action: 'READ',
        username: c?.username,
        password: c?.password,
        filter: {'id': id, '_id': id},
      );
      final rawData = response['data'];
      if (rawData is List && rawData.isNotEmpty) {
        final first = rawData.first;
        if (first is Map<String, dynamic>) return DataRecord.fromJson(first);
        if (first is Map) return DataRecord.fromJson(Map<String, dynamic>.from(first));
      }
    } catch (_) {}

    for (final list in _localRecords.values) {
      final found = list.where((r) => r.id == id);
      if (found.isNotEmpty) return found.first;
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
    final key = '${databaseId}_$collectionName';
    final newRec = DataRecord(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      databaseId: databaseId,
      collectionName: collectionName,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final current = _localRecords[key] ?? [];
    current.add(newRec);
    _localRecords[key] = current;

    final c = _getCreds();
    try {
      await _tcp.send(
        action: 'WRITE',
        username: c?.username,
        password: c?.password,
        database: databaseId,
        collection: collectionName,
        document: data,
      );
    } catch (_) {
      try {
        await _tcp.send(
          action: 'records.create',
          payload: {
            'databaseId': databaseId,
            'collectionName': collectionName,
            'data': data,
          },
        );
      } catch (_) {}
    }

    return newRec;
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    final key = '${record.databaseId}_${record.collectionName}';
    final current = _localRecords[key] ?? [];
    final index = current.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      current[index] = record;
      _localRecords[key] = current;
    }

    final c = _getCreds();
    try {
      await _tcp.send(
        action: 'UPDATE',
        username: c?.username,
        password: c?.password,
        database: record.databaseId,
        collection: record.collectionName,
        filter: {'id': record.id, '_id': record.id},
        document: record.data,
      );
    } catch (_) {
      try {
        await _tcp.send(
          action: 'records.update',
          payload: {
            'id': record.id,
            '_id': record.id,
            'database': record.databaseId,
            'databaseId': record.databaseId,
            'collection': record.collectionName,
            'collectionName': record.collectionName,
            'filter': {'id': record.id, '_id': record.id},
            'document': record.data,
            'data': record.data,
          },
        );
      } catch (_) {}
    }

    return record;
  }

  @override
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  }) async {
    if (databaseId != null && collectionName != null) {
      final key = '${databaseId}_$collectionName';
      _localRecords[key]?.removeWhere((r) => r.id == id);
    } else {
      for (final list in _localRecords.values) {
        list.removeWhere((r) => r.id == id);
      }
    }

    final c = _getCreds();
    try {
      await _tcp.send(
        action: 'DELETE',
        username: c?.username,
        password: c?.password,
        database: databaseId,
        collection: collectionName,
        filter: {'id': id, '_id': id},
      );
    } catch (_) {
      try {
        await _tcp.send(
          action: 'records.delete',
          payload: {
            'id': id,
            '_id': id,
            if (databaseId != null) 'database': databaseId,
            if (databaseId != null) 'databaseId': databaseId,
            if (collectionName != null) 'collection': collectionName,
            if (collectionName != null) 'collectionName': collectionName,
            'filter': {'id': id, '_id': id},
          },
        );
      } catch (_) {}
    }
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
