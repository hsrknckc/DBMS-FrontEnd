// Permissions sayfası aynı UserRepository'yi kullandığı için
// ayrı bir repository gerekmez. UsersNotifier yeniden kullanılır.
//
// Kullanım (permissions_page.dart içinde):
//   ref.watch(usersProvider)            → kullanıcı listesi
//   ref.read(usersProvider.notifier).updatePermissions(...) → kaydet

// Bu dosya, permissions page'e özgü geçici seçim durumunu tutar.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/permission.dart';

/// Şu an permissions panelinde seçili kullanıcının ID'si.
final selectedUserIdProvider = StateProvider<String?>((ref) => null);

/// Düzenlenmekte olan departman seti.
final editingDepartmentsProvider = StateProvider<Set<String>>((ref) => {});

/// Düzenlenmekte olan izin seti.
final editingPermissionsProvider = StateProvider<Set<Permission>>((ref) => {});

/// Kaydedilmemiş değişiklik var mı?
final hasUnsavedPermissionChangesProvider = Provider<bool>((ref) {
  // Kullanım: ref.watch(hasUnsavedPermissionChangesProvider)
  // Gerçek hesaplama page'de yapılır, bu sadece placeholder.
  return false;
});
