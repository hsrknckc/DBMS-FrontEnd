import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_user.dart';
import '../../../models/permission.dart';
import '../../../core/providers/repository_providers.dart';

class UsersNotifier extends AsyncNotifier<List<AppUser>> {
  bool _includeDeleted = true; // Users page varsayılan: tüm durumlarda göster

  @override
  Future<List<AppUser>> build() {
    return ref
        .read(userRepositoryProvider)
        .getUsers(includeDeleted: _includeDeleted);
  }

  Future<void> refresh({bool? includeDeleted}) async {
    if (includeDeleted != null) _includeDeleted = includeDeleted;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(userRepositoryProvider)
          .getUsers(includeDeleted: _includeDeleted),
    );
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    Set<String> departments = const {},
    Set<Permission> permissions = const {},
  }) async {
    final newUser = await ref.read(userRepositoryProvider).createUser(
          name: name,
          email: email,
          password: password,
          departments: departments,
          permissions: permissions,
        );
    state = AsyncData([...state.value ?? [], newUser]);
  }

  Future<void> updateUser(AppUser user) async {
    final updated = await ref.read(userRepositoryProvider).updateUser(user);
    state = AsyncData(
      (state.value ?? [])
          .map((u) => u.id == updated.id ? updated : u)
          .toList(),
    );
  }

  Future<void> softDelete(String id) async {
    await ref.read(userRepositoryProvider).softDeleteUser(id);
    await refresh();
  }

  Future<void> restore(String id) async {
    await ref.read(userRepositoryProvider).restoreUser(id);
    await refresh();
  }

  Future<void> permanentlyDelete(String id) async {
    await ref.read(userRepositoryProvider).permanentlyDeleteUser(id);
    state = AsyncData(
      (state.value ?? []).where((u) => u.id != id).toList(),
    );
  }

  Future<void> updatePermissions({
    required String userId,
    required Set<String> departments,
    required Set<Permission> permissions,
    Map<String, List<String>> allowedCollections = const {},
    Map<String, Set<Permission>> databasePermissions = const {},
    Map<String, Set<Permission>> collectionPermissions = const {},
  }) async {
    final updated = await ref.read(userRepositoryProvider).updatePermissions(
          userId: userId,
          departments: departments,
          permissions: permissions,
          allowedCollections: allowedCollections,
          databasePermissions: databasePermissions,
          collectionPermissions: collectionPermissions,
        );
    state = AsyncData(
      (state.value ?? [])
          .map((u) => u.id == updated.id ? updated : u)
          .toList(),
    );
  }

  Future<void> forcePasswordReset(String userId) async {
    await ref.read(userRepositoryProvider).forcePasswordReset(userId);
    await refresh();
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);
