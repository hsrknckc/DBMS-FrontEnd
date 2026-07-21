import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/data_record.dart';
import '../../../core/providers/repository_providers.dart';

/// Seçili database + collection bilgisini tutan provider.
final selectedDatabaseIdProvider = StateProvider<String?>((ref) => null);
final selectedCollectionProvider = StateProvider<String?>((ref) => null);

class DataExplorerNotifier extends AsyncNotifier<List<DataRecord>> {
  @override
  Future<List<DataRecord>> build() async {
    final dbId = ref.watch(selectedDatabaseIdProvider);
    final collection = ref.watch(selectedCollectionProvider);
    if (dbId == null || collection == null) return [];

    return ref.read(dataExplorerRepositoryProvider).getRecords(
          databaseId: dbId,
          collectionName: collection,
        );
  }

  Future<void> search(String query) async {
    final dbId = ref.read(selectedDatabaseIdProvider);
    final collection = ref.read(selectedCollectionProvider);
    if (dbId == null || collection == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbId,
            collectionName: collection,
            searchQuery: query.isEmpty ? null : query,
          ),
    );
  }

  Future<void> createRecord(Map<String, dynamic> data) async {
    final dbId = ref.read(selectedDatabaseIdProvider);
    final collection = ref.read(selectedCollectionProvider);
    if (dbId == null || collection == null) return;

    final newRecord =
        await ref.read(dataExplorerRepositoryProvider).createRecord(
              databaseId: dbId,
              collectionName: collection,
              data: data,
            );
    state = AsyncData([...state.value ?? [], newRecord]);
  }

  Future<void> updateRecord(DataRecord record) async {
    final updated =
        await ref.read(dataExplorerRepositoryProvider).updateRecord(record);
    state = AsyncData(
      (state.value ?? [])
          .map((r) => r.id == updated.id ? updated : r)
          .toList(),
    );
  }

  Future<void> deleteRecord(String id) async {
    await ref.read(dataExplorerRepositoryProvider).deleteRecord(id);
    state = AsyncData(
      (state.value ?? []).where((r) => r.id != id).toList(),
    );
  }

  Future<String> exportRecords(String format) async {
    final dbId = ref.read(selectedDatabaseIdProvider);
    final collection = ref.read(selectedCollectionProvider);
    if (dbId == null || collection == null) {
      throw Exception('Önce database ve collection seçin.');
    }
    return ref.read(dataExplorerRepositoryProvider).exportRecords(
          databaseId: dbId,
          collectionName: collection,
          format: format,
        );
  }

  Future<int> importRecords(List<Map<String, dynamic>> records) async {
    final dbId = ref.read(selectedDatabaseIdProvider);
    final collection = ref.read(selectedCollectionProvider);
    if (dbId == null || collection == null) {
      throw Exception('Önce database ve collection seçin.');
    }
    final count =
        await ref.read(dataExplorerRepositoryProvider).importRecords(
              databaseId: dbId,
              collectionName: collection,
              records: records,
            );
    // Listeyi yenile
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbId,
            collectionName: collection,
          ),
    );
    return count;
  }
}

final dataExplorerProvider =
    AsyncNotifierProvider<DataExplorerNotifier, List<DataRecord>>(
        DataExplorerNotifier.new);
