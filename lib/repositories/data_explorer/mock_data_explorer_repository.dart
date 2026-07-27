import '../../models/data_record.dart';
import 'data_explorer_repository.dart';

/// Sahte data explorer verisi — data_explorer_page.dart'taki hard-coded veriler buraya taşındı.
class MockDataExplorerRepository implements DataExplorerRepository {
  final List<DataRecord> _records = [
    DataRecord(
      id: 'record-1',
      databaseId: 'db-1',
      collectionName: 'sensor_readings',
      data: const {
        'sensorId': 'SEN-001',
        'type': 'Temperature',
        'value': 22.8,
        'unit': '°C',
        'status': 'Normal',
        'timestamp': '2026-07-16 08:30',
      },
      createdAt: DateTime(2026, 7, 16, 8, 30),
      updatedAt: DateTime(2026, 7, 16, 8, 30),
    ),
    DataRecord(
      id: 'record-2',
      databaseId: 'db-1',
      collectionName: 'sensor_readings',
      data: const {
        'sensorId': 'SEN-002',
        'type': 'Pressure',
        'value': 101.7,
        'unit': 'kPa',
        'status': 'Normal',
        'timestamp': '2026-07-16 08:32',
      },
      createdAt: DateTime(2026, 7, 16, 8, 32),
      updatedAt: DateTime(2026, 7, 16, 8, 32),
    ),
    DataRecord(
      id: 'record-3',
      databaseId: 'db-1',
      collectionName: 'sensor_readings',
      data: const {
        'sensorId': 'SEN-003',
        'type': 'Humidity',
        'value': 65.2,
        'unit': '%',
        'status': 'Warning',
        'timestamp': '2026-07-16 08:35',
      },
      createdAt: DateTime(2026, 7, 16, 8, 35),
      updatedAt: DateTime(2026, 7, 16, 8, 35),
    ),
    DataRecord(
      id: 'record-4',
      databaseId: 'db-1',
      collectionName: 'device_logs',
      data: const {
        'deviceId': 'DEV-010',
        'event': 'reconnected',
        'location': 'Test Area A',
        'lastConnection': '2026-07-16 08:40',
      },
      createdAt: DateTime(2026, 7, 16, 8, 40),
      updatedAt: DateTime(2026, 7, 16, 8, 40),
    ),
    DataRecord(
      id: 'record-5',
      databaseId: 'db-2',
      collectionName: 'signal_records',
      data: const {
        'signalId': 'SIG-101',
        'frequency': 1250,
        'amplitude': 0.82,
        'classification': 'Unknown',
        'timestamp': '2026-07-16 07:55',
      },
      createdAt: DateTime(2026, 7, 16, 7, 55),
      updatedAt: DateTime(2026, 7, 16, 7, 55),
    ),
    DataRecord(
      id: 'record-6',
      databaseId: 'db-3',
      collectionName: 'acoustic_samples',
      data: const {
        'sampleId': 'AC-550',
        'frequency': 620,
        'duration': 4.5,
        'confidence': 0.91,
        'classification': 'Marine Object',
      },
      createdAt: DateTime(2026, 7, 15, 18, 20),
      updatedAt: DateTime(2026, 7, 15, 18, 20),
    ),
  ];

  @override
  Future<List<DataRecord>> getRecords({
    required String databaseId,
    required String collectionName,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = _records
        .where((r) =>
            r.databaseId == databaseId &&
            r.collectionName == collectionName)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((r) {
        return r.data.values.any((v) => v.toString().toLowerCase().contains(q));
      }).toList();
    }
    return results;
  }

  @override
  Future<DataRecord> getRecordById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _records.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Kayıt bulunamadı: $id'),
    );
  }

  @override
  Future<DataRecord> createRecord({
    required String databaseId,
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newRecord = DataRecord(
      id: 'record-${DateTime.now().millisecondsSinceEpoch}',
      databaseId: databaseId,
      collectionName: collectionName,
      data: data,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _records.add(newRecord);
    return newRecord;
  }

  @override
  Future<DataRecord> updateRecord(DataRecord record) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index == -1) throw Exception('Kayıt bulunamadı: ${record.id}');
    _records[index] = record.copyWith(updatedAt: DateTime.now());
    return _records[index];
  }

  @override
  Future<void> deleteRecord(
    String id, {
    String? databaseId,
    String? collectionName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<String> exportRecords({
    required String databaseId,
    required String collectionName,
    required String format,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Mock: boş export URL döner
    return 'mock-export-$databaseId-$collectionName.$format';
  }

  @override
  Future<int> importRecords({
    required String databaseId,
    required String collectionName,
    required List<Map<String, dynamic>> records,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    for (final data in records) {
      _records.add(DataRecord(
        id: 'record-${DateTime.now().millisecondsSinceEpoch}-${_records.length}',
        databaseId: databaseId,
        collectionName: collectionName,
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    return records.length;
  }
}
