import '../../models/data_record.dart';

/// Data Explorer CRUD + export işlemleri için soyut arayüz.
abstract class DataExplorerRepository {
  /// Belirli bir database ve collection'daki kayıtları getirir.
  /// [searchQuery] varsa sonuçları filtreler.
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  });

  /// Tek kaydı ID ile getirir.
  Future<DataRecord> getRecordById(String id);

  /// Yeni kayıt oluşturur.
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  });

  /// Mevcut kaydı günceller.
  Future<DataRecord> updateRecord(DataRecord record);

  /// Kaydı siler (data explorer'da soft-delete yok, kalıcı).
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  });

  /// Kayıtları export eder.
  /// [format]: 'json' | 'csv'
  /// Dönen String → indirme URL'i veya dosya içeriği.
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  });

  /// JSON verisiyle toplu kayıt içe aktarır.
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  });
}
