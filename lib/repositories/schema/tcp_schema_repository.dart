import '../../core/providers/repository_providers.dart';
import '../../core/services/tcp_socket_service.dart';
import 'schema_repository.dart';

/// TCP/IP soket üzerinden şema (alan tipleri) işlemleri.
class TcpSchemaRepository implements SchemaRepository {
  final TcpSocketService _tcp;
  final Credentials? Function() _credentialsProvider;

  TcpSchemaRepository(this._tcp, this._credentialsProvider);

  Credentials _getCreds() {
    final c = _credentialsProvider();
    if (c == null || c.username.isEmpty || c.password.isEmpty) {
      throw const TcpException('Oturum açılmamış (kullanıcı kimliği eksik).');
    }
    return c;
  }

  // ── DESCRIBE_COLLECTION ────────────────────────────────────────────────────

  @override
  Future<Map<String, SchemaField>> getCollectionSchema({
    required String databaseName,
    required String collectionName,
  }) async {
    final c = _getCreds();

    final response = await _tcp.send(
      action: 'DESCRIBE_COLLECTION',
      username: c.username,
      password: c.password,
      database: databaseName,
      collection: collectionName,
    );

    final data = response['data'] as List? ?? [];
    if (data.isEmpty) return <String, SchemaField>{};

    final schema = data.first as Map<String, dynamic>;
    final rawFields = schema['fields'] as List? ?? [];
    final fields = rawFields.cast<Map<String, dynamic>>();

    final result = <String, SchemaField>{};
    for (final f in fields) {
      final name = f['name'] as String? ?? '';
      final type = (f['type'] as String? ?? 'any').toLowerCase();
      final inferred = f['inferred'] as bool? ?? false;
      if (name.isNotEmpty) {
        result[name] = SchemaField(name: name, type: type, inferred: inferred);
      }
    }
    return result;
  }

  // ── DEFINE_FIELDS ──────────────────────────────────────────────────────────

  @override
  Future<void> saveCollectionSchema({
    required String databaseName,
    required String collectionName,
    required List<Map<String, String>> fields,
  }) async {
    final c = _getCreds();

    await _tcp.send(
      action: 'DEFINE_FIELDS',
      username: c.username,
      password: c.password,
      database: databaseName,
      collection: collectionName,
      document: {
        'fields': fields,
      },
    );
  }
}
