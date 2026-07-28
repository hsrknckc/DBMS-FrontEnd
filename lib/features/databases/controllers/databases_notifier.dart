import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/database_item.dart';
import '../../../core/providers/repository_providers.dart';

class DatabasesNotifier extends AsyncNotifier<List<DatabaseItem>> {
  bool _includeDeleted = false;

  @override
  Future<List<DatabaseItem>> build() async {
    return _fetchEnrichedDatabases();
  }

  Future<List<DatabaseItem>> _fetchEnrichedDatabases() async {
    final list = await ref
        .read(databaseRepositoryProvider)
        .getDatabases(includeDeleted: _includeDeleted);

    final explorerRepo = ref.read(dataExplorerRepositoryProvider);
    final enrichedList = <DatabaseItem>[];

    for (final db in list) {
      try {
        final cols = await explorerRepo.getCollections(db.name);
        int totalRecs = 0;
        for (final col in cols) {
          final recs = await explorerRepo.getRecords(
            databaseId: db.name,
            collectionName: col,
          );
          totalRecs += recs.length;
        }
        enrichedList.add(db.copyWith(
          collectionCount: cols.length,
          recordCount: totalRecs,
        ));
      } catch (_) {
        enrichedList.add(db);
      }
    }

    return enrichedList;
  }

  Future<void> refresh({bool? includeDeleted}) async {
    if (includeDeleted != null) _includeDeleted = includeDeleted;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchEnrichedDatabases());
  }

  Future<void> createDatabase({
    required String name,
    required String department,
    required String description,
  }) async {
    final newDb = await ref.read(databaseRepositoryProvider).createDatabase(
          name: name,
          department: department,
          description: description,
        );
    state = AsyncData([...state.value ?? [], newDb]);
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> updateDatabase(DatabaseItem item) async {
    final updated =
        await ref.read(databaseRepositoryProvider).updateDatabase(item);
    state = AsyncData(
      (state.value ?? []).map((db) => db.id == updated.id ? updated : db).toList(),
    );
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> softDelete(String id) async {
    await ref.read(databaseRepositoryProvider).softDeleteDatabase(id);
    state = AsyncData(
      (state.value ?? []).where((db) => db.id != id && db.name != id).toList(),
    );
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> restore(String id) async {
    await ref.read(databaseRepositoryProvider).restoreDatabase(id);
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> permanentlyDelete(String id) async {
    await ref.read(databaseRepositoryProvider).permanentlyDeleteDatabase(id);
    state = AsyncData(
      (state.value ?? []).where((db) => db.id != id && db.name != id).toList(),
    );
    await refresh(includeDeleted: _includeDeleted);
  }
}

final databasesProvider =
    AsyncNotifierProvider<DatabasesNotifier, List<DatabaseItem>>(
        DatabasesNotifier.new);
