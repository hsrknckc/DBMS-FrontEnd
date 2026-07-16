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
      deletedAt: clearDeletedAt
          ? null
          : deletedAt ?? this.deletedAt,
      deletedBy: clearDeletedBy
          ? null
          : deletedBy ?? this.deletedBy,
    );
  }
}