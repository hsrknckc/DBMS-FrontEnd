import '../../models/database_item.dart';
import 'database_repository.dart';

/// Sahte database verisi — databases_page.dart'taki hard-coded liste buraya taşındı.
class MockDatabaseRepository implements DatabaseRepository {
  final List<DatabaseItem> _databases = [
    DatabaseItem(
      id: 'db-1',
      name: 'sensor_database',
      department: 'Sensor',
      description: 'Sensör cihazlarından gelen ölçüm ve durum verilerini içerir.',
      collectionCount: 4,
      recordCount: 42580,
      createdAt: DateTime(2026, 7, 1, 9, 0),
      updatedAt: DateTime(2026, 7, 15, 13, 40),
    ),
    DatabaseItem(
      id: 'db-2',
      name: 'signal_database',
      department: 'Signal',
      description: 'Sinyal kayıtları ve analiz sonuçlarının tutulduğu database.',
      collectionCount: 3,
      recordCount: 18940,
      createdAt: DateTime(2026, 7, 3, 10, 30),
      updatedAt: DateTime(2026, 7, 15, 11, 15),
    ),
    DatabaseItem(
      id: 'db-3',
      name: 'acoustic_database',
      department: 'Acoustic',
      description: 'Akustik ölçüm verileri ve işlenmiş sonuçları içerir.',
      collectionCount: 6,
      recordCount: 78320,
      createdAt: DateTime(2026, 6, 25, 14, 20),
      updatedAt: DateTime(2026, 7, 14, 17, 50),
    ),
    DatabaseItem(
      id: 'db-4',
      name: 'sonar_archive',
      department: 'Sonar',
      description: 'Arşivlenmiş sonar verilerinin tutulduğu database.',
      collectionCount: 2,
      recordCount: 12500,
      createdAt: DateTime(2026, 6, 18, 12, 10),
      updatedAt: DateTime(2026, 7, 10, 16, 25),
    ),
    DatabaseItem(
      id: 'db-5',
      name: 'old_test_database',
      department: 'Test',
      description: 'Eski test kayıtlarının tutulduğu silinmiş database.',
      collectionCount: 1,
      recordCount: 840,
      createdAt: DateTime(2026, 5, 12, 8, 30),
      updatedAt: DateTime(2026, 6, 20, 15, 0),
      isDeleted: true,
      deletedAt: DateTime(2026, 7, 12, 10, 45),
      deletedBy: 'Ayşe Yılmaz',
    ),
  ];

  @override
  Future<List<DatabaseItem>> getDatabases({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (includeDeleted) return List.unmodifiable(_databases);
    return _databases.where((db) => !db.isDeleted).toList();
  }

  @override
  Future<DatabaseItem> getDatabaseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _databases.firstWhere(
      (db) => db.id == id,
      orElse: () => throw Exception('Database bulunamadı: $id'),
    );
  }

  @override
  Future<DatabaseItem> createDatabase({
    required String name,
    required String department,
    required String description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newDb = DatabaseItem(
      id: 'db-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      department: department,
      description: description,
      collectionCount: 0,
      recordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _databases.add(newDb);
    return newDb;
  }

  @override
  Future<DatabaseItem> updateDatabase(DatabaseItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _databases.indexWhere((db) => db.id == item.id);
    if (index == -1) throw Exception('Database bulunamadı: ${item.id}');
    _databases[index] = item.copyWith(updatedAt: DateTime.now());
    return _databases[index];
  }

  @override
  Future<void> softDeleteDatabase(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _databases.indexWhere((db) => db.id == id);
    if (index == -1) throw Exception('Database bulunamadı: $id');
    _databases[index] = _databases[index].copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> restoreDatabase(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _databases.indexWhere((db) => db.id == id);
    if (index == -1) throw Exception('Database bulunamadı: $id');
    _databases[index] = _databases[index].copyWith(
      isDeleted: false,
      updatedAt: DateTime.now(),
      clearDeletedAt: true,
      clearDeletedBy: true,
    );
  }

  @override
  Future<void> permanentlyDeleteDatabase(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _databases.removeWhere((db) => db.id == id);
  }
}
