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

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory DataRecord.fromJson(Map<String, dynamic> json) {
    // `data` alanı backend'den nested map olarak gelir.
    // Eğer backend düz (flat) bir döküman gönderiyorsa
    // bilinen meta alanlarını çıkarıp kalanını `data` olarak al.
    final Map<String, dynamic> dataFields;
    if (json.containsKey('data')) {
      dataFields =
          Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>);
    } else {
      // Düz MongoDB dökümanı: meta alanları çıkar, geri kalan = data
      dataFields = Map<String, dynamic>.from(json)
        ..remove('_id')
        ..remove('id')
        ..remove('databaseId')
        ..remove('collectionName')
        ..remove('createdAt')
        ..remove('updatedAt');
    }

    return DataRecord(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      databaseId: json['databaseId'] as String? ?? '',
      collectionName: json['collectionName'] as String? ?? '',
      data: dataFields,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'databaseId': databaseId,
      'collectionName': collectionName,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

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
      collectionName: collectionName ?? this.collectionName,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
