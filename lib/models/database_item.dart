class DatabaseItem {
  final String id;
  final String name;
  final String department;
  final String description;
  final int collectionCount;
  final int recordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  const DatabaseItem({
    required this.id,
    required this.name,
    required this.department,
    required this.description,
    required this.collectionCount,
    required this.recordCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory DatabaseItem.fromJson(Map<String, dynamic> json) {
    return DatabaseItem(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? '',
      description: json['description'] as String? ?? '',
      collectionCount: (json['collectionCount'] as num?)?.toInt() ?? 0,
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'description': description,
      'collectionCount': collectionCount,
      'recordCount': recordCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deletedBy': deletedBy,
    };
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────

  DatabaseItem copyWith({
    String? id,
    String? name,
    String? department,
    String? description,
    int? collectionCount,
    int? recordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    bool clearDeletedAt = false,
    bool clearDeletedBy = false,
  }) {
    return DatabaseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      description: description ?? this.description,
      collectionCount: collectionCount ?? this.collectionCount,
      recordCount: recordCount ?? this.recordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletedBy: clearDeletedBy ? null : (deletedBy ?? this.deletedBy),
    );
  }
}
