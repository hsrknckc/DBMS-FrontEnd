import '../../core/services/tcp_socket_service.dart';
import '../../models/database_item.dart';
import 'database_repository.dart';

/// TCP/IP soket üzerinden database CRUD işlemleri.
///
/// Protokol aksiyonları:
///   databases.list           → {includeDeleted}
///   databases.getById        → {id}
///   databases.create         → {name, department, description}
///   databases.update         → {database}
///   databases.softDelete     → {id}
///   databases.restore        → {id}
///   databases.permanentDelete→ {id}
class TcpDatabaseRepository implements DatabaseRepository {
  final TcpSocketService _tcp;
  final String? Function() _tokenProvider;

  TcpDatabaseRepository(this._tcp, this._tokenProvider);

  @override
  Future<List<DatabaseItem>> getDatabases({bool includeDeleted = false}) async {
    Map<String, dynamic> response;
    try {
      response = await _tcp.send(
        action: 'LIST_DATABASES',
        payload: {},
        token: _tokenProvider(),
      );
    } catch (_) {
      response = await _tcp.send(
        action: 'databases.list',
        payload: {'includeDeleted': includeDeleted},
        token: _tokenProvider(),
      );
    }

    final rawData = response['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }

    return rawData.map((item) {
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
  }

  @override
  Future<DatabaseItem> getDatabaseById(String id) async {
    final response = await _tcp.send(
      action: 'databases.getById',
      payload: {'id': id},
      token: _tokenProvider(),
    );
    return _parseDb(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<DatabaseItem> createDatabase({
    required String name,
    required String department,
    required String description,
  }) async {
    final response = await _tcp.send(
      action: 'databases.create',
      payload: {
        'name': name,
        'department': department,
        'description': description,
      },
      token: _tokenProvider(),
    );
    return _parseDb(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<DatabaseItem> updateDatabase(DatabaseItem item) async {
    final response = await _tcp.send(
      action: 'databases.update',
      payload: _serializeDb(item),
      token: _tokenProvider(),
    );
    return _parseDb(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> softDeleteDatabase(String id) async {
    await _tcp.send(
      action: 'databases.softDelete',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<void> restoreDatabase(String id) async {
    await _tcp.send(
      action: 'databases.restore',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  @override
  Future<void> permanentlyDeleteDatabase(String id) async {
    await _tcp.send(
      action: 'databases.permanentDelete',
      payload: {'id': id},
      token: _tokenProvider(),
    );
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  DatabaseItem _parseDb(Map<String, dynamic> data) {
    return DatabaseItem(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      department: data['department'] as String? ?? '',
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
