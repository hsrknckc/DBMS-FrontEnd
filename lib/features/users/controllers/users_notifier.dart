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
    final current = state.value ?? const <AppUser>[];
    state = AsyncData(_upsertUser(current, newUser));
  }

  Future<void> updateUser(AppUser user) async {
    final updated = await ref.read(userRepositoryProvider).updateUser(user);
    state = AsyncData(
      _upsertUser(state.value ?? const <AppUser>[], updated),
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
      _upsertUser(state.value ?? const <AppUser>[], updated),
    );
  }

  Future<void> forcePasswordReset(String userId) async {
    await ref.read(userRepositoryProvider).forcePasswordReset(userId);
    await refresh();
  }

  List<AppUser> _upsertUser(List<AppUser> users, AppUser updated) {
    var replaced = false;
    final next = users.map((user) {
      if (_sameUser(user, updated)) {
        replaced = true;
        return updated;
      }
      return user;
    }).toList();

    if (!replaced) {
      next.add(updated);
    }

    return _dedupeUsers(next);
  }

  List<AppUser> _dedupeUsers(Iterable<AppUser> users) {
    final result = <AppUser>[];
    for (final user in users) {
      final index = result.indexWhere((item) => _sameUser(item, user));
      if (index == -1) {
        result.add(user);
      } else {
        result[index] = user;
      }
    }
    return result;
  }

  bool _sameUser(AppUser first, AppUser second) {
    final firstId = first.id.trim();
    final secondId = second.id.trim();
    if (firstId.isNotEmpty && secondId.isNotEmpty && firstId == secondId) {
      return true;
    }

    final firstEmail = first.email.trim().toLowerCase();
    final secondEmail = second.email.trim().toLowerCase();
    return firstEmail.isNotEmpty &&
        secondEmail.isNotEmpty &&
        firstEmail == secondEmail;
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);
