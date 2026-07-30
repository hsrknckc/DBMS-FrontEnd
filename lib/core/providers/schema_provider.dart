import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/schema/schema_repository.dart';
import 'repository_providers.dart';

/// Belirli bir koleksiyonun şemasını sunucudan çekmek ve önbelleğe almak için kullanılır.
/// family parametresi: 'databaseName::collectionName'
final collectionSchemaProvider = FutureProvider.family<Map<String, SchemaField>, String>((ref, key) async {
  final parts = key.split('::');
  if (parts.length != 2) return {};

  final dbName = parts[0];
  final colName = parts[1];

  final repo = ref.read(schemaRepositoryProvider);
  return repo.getCollectionSchema(
    databaseName: dbName,
    collectionName: colName,
  );
});

/// Bir alana karşılık gelen backend tip adını, kullanıcı dostu etiketine çevirir.
String typeToLabel(String type) {
  switch (type.toLowerCase()) {
    case 'string':
      return 'String';
    case 'int':
      return 'Integer';
    case 'double':
      return 'Double';
    case 'boolean':
      return 'Boolean';
    case 'array':
      return 'Array';
    case 'object':
      return 'Object';
    case 'any':
      return 'Any';
    default:
      return type;
  }
}

/// Kullanıcı dostu etiketi backend tip adına çevirir.
String labelToType(String label) {
  switch (label) {
    case 'String':
      return 'string';
    case 'Integer':
      return 'int';
    case 'Double':
      return 'double';
    case 'Boolean':
      return 'boolean';
    case 'Array':
      return 'array';
    case 'Object':
      return 'object';
    case 'Any':
      return 'any';
    default:
      return label.toLowerCase();
  }
}

/// Form alanlarından gelen metin değerini, şemadaki hedef tipe dönüştürür.
/// Dönüştürülemezse null döner.
dynamic convertValueToSchemaType(String text, String type) {
  if (text.isEmpty) return null;
  switch (type.toLowerCase()) {
    case 'int':
      return int.tryParse(text);
    case 'double':
      return double.tryParse(text);
    case 'boolean':
      return text.toLowerCase() == 'true';
    case 'string':
      return text;
    default:
      return text;
  }
}

/// Kullanıcı arayüzünde gösterilebilecek tüm tip etiketleri.
const List<String> allTypeLabels = [
  'String',
  'Integer',
  'Double',
  'Boolean',
  'Array',
  'Object',
  'Any',
];
