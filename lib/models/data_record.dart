class DataRecord {
  final String id;
  final String databaseId;
  final String collectionName;
  final Map<String, dynamic> data;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DataRecord({
    required this.id,
    required this.databaseId,
    required this.collectionName,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  DataRecord copyWith({
    String? id,
    String? databaseId,
    String? collectionName,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DataRecord(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      collectionName:
          collectionName ?? this.collectionName,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}