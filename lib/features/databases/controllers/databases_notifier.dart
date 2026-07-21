import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/database_item.dart';
import '../../../core/providers/repository_providers.dart';

class DatabasesNotifier extends AsyncNotifier<List<DatabaseItem>> {
  bool _includeDeleted = false;

  @override
  Future<List<DatabaseItem>> build() {
    return ref
        .read(databaseRepositoryProvider)
        .getDatabases(includeDeleted: _includeDeleted);
  }

  Future<void> refresh({bool? includeDeleted}) async {
    if (includeDeleted != null) _includeDeleted = includeDeleted;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(databaseRepositoryProvider)
          .getDatabases(includeDeleted: _includeDeleted),
    );
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
  }

  Future<void> updateDatabase(DatabaseItem item) async {
    final updated =
        await ref.read(databaseRepositoryProvider).updateDatabase(item);
    state = AsyncData(
      (state.value ?? []).map((db) => db.id == updated.id ? updated : db).toList(),
    );
  }

  Future<void> softDelete(String id) async {
    await ref.read(databaseRepositoryProvider).softDeleteDatabase(id);
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> restore(String id) async {
    await ref.read(databaseRepositoryProvider).restoreDatabase(id);
    await refresh(includeDeleted: _includeDeleted);
  }

  Future<void> permanentlyDelete(String id) async {
    await ref.read(databaseRepositoryProvider).permanentlyDeleteDatabase(id);
    state = AsyncData(
      (state.value ?? []).where((db) => db.id != id).toList(),
    );
  }
}

final databasesProvider =
    AsyncNotifierProvider<DatabasesNotifier, List<DatabaseItem>>(
        DatabasesNotifier.new);
