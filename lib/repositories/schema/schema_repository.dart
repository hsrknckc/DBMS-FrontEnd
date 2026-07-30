/// Koleksiyon şeması (alan tipleri) için soyut arayüz.
abstract class SchemaRepository {
  /// Koleksiyonun sunucu tarafındaki şemasını getirir.
  /// Dönen harita: { 'alanAdı': SchemaField(...) }
  Future<Map<String, SchemaField>> getCollectionSchema({
    required String databaseName,
    required String collectionName,
  });

  /// Koleksiyona şema (alan tanımları) kaydeder.
  /// [fields]: [{'name': '...', 'type': '...'}, ...]
  Future<void> saveCollectionSchema({
    required String databaseName,
    required String collectionName,
    required List<Map<String, String>> fields,
  });
}

/// Tek bir alan tanımı.
class SchemaField {
  final String name;
  final String type; // string, int, double, boolean, array, object, any
  final bool inferred;

  const SchemaField({
    required this.name,
    required this.type,
    this.inferred = false,
  });

  @override
  String toString() => 'SchemaField(name: $name, type: $type, inferred: $inferred)';
}
