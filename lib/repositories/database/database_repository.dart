import '../../models/database_item.dart';

/// Database CRUD işlemleri için soyut arayüz.
abstract class DatabaseRepository {
  /// Tüm database'leri getirir.
  /// [includeDeleted] true ise soft-deleted olanlar da dahil edilir.
  Future<List<DatabaseItem>> getDatabases({bool includeDeleted = false});

  /// Tek database'i ID ile getirir.
  Future<DatabaseItem> getDatabaseById(String id);

  /// Yeni database oluşturur.
  Future<DatabaseItem> createDatabase({
    required String name,
    required String department,
    required String description,
  });

  /// Database bilgilerini günceller.
  Future<DatabaseItem> updateDatabase(DatabaseItem item);

  /// Database'i soft-delete yapar (geri yüklenebilir).
  Future<void> softDeleteDatabase(String id);

  /// Soft-deleted database'i geri yükler.
  Future<void> restoreDatabase(String id);

  /// Database'i kalıcı olarak siler (geri alınamaz).
  Future<void> permanentlyDeleteDatabase(String id);
}
