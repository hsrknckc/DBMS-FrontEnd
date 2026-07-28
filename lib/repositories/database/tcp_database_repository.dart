import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import '../../models/database_item.dart';
import 'database_repository.dart';

/// TCP/IP soket üzerinden database CRUD işlemleri (PROTOKOL.md Tek Protokol).
class TcpDatabaseRepository implements DatabaseRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  final List<DatabaseItem> _localDbs = [];

  TcpDatabaseRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null || c.username.isEmpty || c.password.isEmpty) {
      throw const TcpException('Oturum açılmamış (kullanıcı kimliği eksik).');
    }
    return c;
  }

  @override
  Future<List<DatabaseItem>> getDatabases({bool includeDeleted = false}) async {
    final c = _getCreds();

    try {
      final response = await _tcp.send(
        action: 'LIST_DATABASES_INFO',
        username: c.username,
        password: c.password,
      );

      final rawData = response['data'];
      if (rawData is List) {
        final fetched = rawData.map((item) {
          if (item is String) {
            return DatabaseItem(
              id: item,
              name: item,
              department: 'General',
              description: '$item veritabanı',
              collectionCount: 0,
              recordCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else if (item is Map<String, dynamic>) {
            return _parseDb(item);
          } else if (item is Map) {
            return _parseDb(Map<String, dynamic>.from(item));
          }
          return DatabaseItem(
            id: item.toString(),
            name: item.toString(),
            department: 'General',
            description: '',
            collectionCount: 0,
            recordCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        _localDbs.clear();
        _localDbs.addAll(fetched);
      }
    } catch (_) {}

    if (includeDeleted) {
      return _localDbs;
    }
    return _localDbs.where((db) => !db.isDeleted).toList();
  }

  @override
  Future<DatabaseItem> getDatabaseById(String id) async {
    final list = await getDatabases(includeDeleted: true);
    return list.firstWhere(
      (db) => db.id == id || db.name == id,
      orElse: () => DatabaseItem(
        id: id,
        name: id,
        department: 'General',
        description: '',
        collectionCount: 0,
        recordCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<DatabaseItem> createDatabase({
    required String name,
    required String department,
    required String description,
  }) async {
    final c = _getCreds();
    final newDb = DatabaseItem(
      id: name,
      name: name,
      department: department,
      description: description,
      collectionCount: 0,
      recordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _tcp.send(
      action: 'CREATE_DATABASE',
      username: c.username,
      password: c.password,
      database: name,
      document: {
        'department': department,
        'description': description,
      },
    );

    _localDbs.add(newDb);
    return newDb;
  }

  @override
  Future<DatabaseItem> updateDatabase(DatabaseItem item) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'UPDATE_DATABASE',
      username: c.username,
      password: c.password,
      database: item.name,
      document: _serializeDb(item),
    );

    final index = _localDbs.indexWhere((db) => db.id == item.id || db.name == item.name);
    if (index != -1) {
      _localDbs[index] = item;
    }

    return item;
  }

  @override
  Future<void> softDeleteDatabase(String id) async {
    await permanentlyDeleteDatabase(id);
  }

  @override
  Future<void> restoreDatabase(String id) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'RESTORE_DATABASE',
      username: c.username,
      password: c.password,
      database: id,
    );

    final index = _localDbs.indexWhere((db) => db.id == id || db.name == id);
    if (index != -1) {
      _localDbs[index] = _localDbs[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
    }
  }

  @override
  Future<void> permanentlyDeleteDatabase(String id) async {
    final c = _getCreds();
    _localDbs.removeWhere((db) => db.id == id || db.name == id);

    try {
      await _tcp.send(
        action: 'DROP_DATABASE',
        username: c.username,
        password: c.password,
        database: id,
      );
    } catch (e) {
      try {
        await _tcp.send(
          action: 'DELETE_DATABASE',
          username: c.username,
          password: c.password,
          database: id,
        );
      } catch (err) {
        if (!err.toString().toLowerCase().contains('not found')) {
          rethrow;
        }
      }
    }
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  DatabaseItem _parseDb(Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? data['database']?.toString() ?? data['_id']?.toString() ?? '';
    return DatabaseItem(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? name,
      name: name,
      department: data['department'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      collectionCount: (data['collectionCount'] as num?)?.toInt() ?? 0,
      recordCount: (data['recordCount'] as num?)?.toInt() ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.tryParse(data['deletedAt'].toString())
          : null,
      deletedBy: data['deletedBy'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _serializeDb(DatabaseItem item) => {
        'id': item.id,
        'name': item.name,
        'department': item.department,
        'description': item.description,
        'isDeleted': item.isDeleted,
      };
}
