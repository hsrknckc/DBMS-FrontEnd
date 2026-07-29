import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// TCP/IP soket üzerinden data explorer CRUD + export/import işlemleri (PROTOKOL.md Tek Protokol).
class TcpDataExplorerRepository implements DataExplorerRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  final Map<String, List<DataRecord>> _localRecords = {};
  final Map<String, List<String>> _localCollections = {};

  TcpDataExplorerRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null || c.username.isEmpty || c.password.isEmpty) {
      throw const TcpException('Oturum açılmamış (kullanıcı kimliği eksik).');
    }
    return c;
  }

  /// Veritabanındaki koleksiyon adlarını çekme (LIST_COLLECTIONS)
  @override
  Future<List<String>> getCollections(String databaseName) async {
    final c = _getCreds();
    try {
      final response = await _tcp.send(
        action: 'LIST_COLLECTIONS',
        username: c.username,
        password: c.password,
        database: databaseName,
      );
      final rawData = response['data'];
      if (rawData is List) {
        final fetched = rawData.map((e) => e.toString()).toList();
        _localCollections[databaseName] = fetched;
      }
    } catch (_) {}

    return _localCollections[databaseName] ?? [];
  }

  /// Koleksiyonu Silme (DROP_COLLECTION)
  Future<void> dropCollection(
    String databaseName,
    String collectionName,
  ) async {
    final c = _getCreds();
    _localCollections[databaseName]?.remove(collectionName);
    _localRecords.remove('${databaseName}_$collectionName');

    await _tcp.send(
      action: 'DROP_COLLECTION',
      username: c.username,
      password: c.password,
      database: databaseName,
      collection: collectionName,
    );
  }

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    final key = '${databaseId}_$collectionName';
    final c = _getCreds();

    try {
      final response = await _tcp.send(
        action: 'READ',
        username: c.username,
        password: c.password,
        database: databaseId,
        collection: collectionName,
        filter: (searchQuery != null && searchQuery.isNotEmpty)
            ? {'searchQuery': searchQuery}
            : null,
      );

      final rawData = response['data'];
      if (rawData is List) {
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

        _localRecords[key] = fetched;
      }
    } catch (_) {}

    final list = _localRecords[key] ?? [];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      return list
          .where((r) => r.data.toString().toLowerCase().contains(queryLower))
          .toList();
    }
    return list;
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
      if (first is Map)
        return DataRecord.fromJson(Map<String, dynamic>.from(first));
    }

    throw TcpException('Kayıt bulunamadı: $id');
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    final key = '${databaseId}_$collectionName';
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
    DataRecord newRec;
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map<String, dynamic>) {
        newRec = DataRecord.fromJson(first);
      } else if (first is Map) {
        newRec = DataRecord.fromJson(Map<String, dynamic>.from(first));
      } else {
        newRec = DataRecord(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          databaseId: databaseId,
          collectionName: collectionName,
          data: data,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } else {
      newRec = DataRecord(
        id:
            data['_id']?.toString() ??
            data['id']?.toString() ??
            'rec_${DateTime.now().millisecondsSinceEpoch}',
        databaseId: databaseId,
        collectionName: collectionName,
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final current = _localRecords[key] ?? [];
    current.add(newRec);
    _localRecords[key] = current;

    return newRec;
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    final key = '${record.databaseId}_${record.collectionName}';
    final c = _getCreds();

    await _tcp.send(
      action: 'UPDATE',
      username: c.username,
      password: c.password,
      database: record.databaseId,
      collection: record.collectionName,
      filter: {'id': record.id},
      document: record.data,
    );

    final current = _localRecords[key] ?? [];
    final index = current.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      current[index] = record;
      _localRecords[key] = current;
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

    final response = await _tcp.send(
      action: 'DELETE',
      username: c.username,
      password: c.password,
      database: databaseId,
      collection: collectionName,
      filter: {'id': id},
    );

    // PROTOKOL.md Madde 4: deletedCount Kontrolü
    final list = response['data'] as List;
    if (list.isNotEmpty) {
      final first = list.first;
      if (first is Map) {
        final deletedCount = (first['deletedCount'] as num?)?.toInt() ?? 1;
        if (deletedCount == 0) {
          throw Exception('Kayıt silinemedi (sunucuda eşleşme bulunamadı)');
        }
      }
    }

    if (databaseId != null && collectionName != null) {
      final key = '${databaseId}_$collectionName';
      _localRecords[key]?.removeWhere((r) => r.id == id);
    } else {
      for (final l in _localRecords.values) {
        l.removeWhere((r) => r.id == id);
      }
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
