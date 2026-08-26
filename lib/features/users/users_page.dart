import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import 'controllers/users_notifier.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  /// 0: Tümü
  /// 1: Aktif
  /// 2: Pasif
  /// 3: Silinenler
  int _statusFilter = 0;

  List<AppUser> get _users {
    return ref.watch(usersProvider).valueOrNull ?? [];
  }

  List<AppUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesQuery =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.departments.any(
            (department) => department.toLowerCase().contains(query),
          );

      if (!matchesQuery) {
        return false;
      }

      switch (_statusFilter) {
        case 1:
          return !user.isDeleted && user.isActive;

        case 2:
          return !user.isDeleted && !user.isActive;

        case 3:
          return user.isDeleted;

        default:
          return !user.isDeleted;
      }
    }).toList();
  }

  int get _activeUserCount {
    return _users.where((user) {
      return !user.isDeleted && user.isActive;
    }).length;
  }

  int get _inactiveUserCount {
    return _users.where((user) {
      return !user.isDeleted && !user.isActive;
    }).length;
  }

  int get _deletedUserCount {
    return _users.where((user) => user.isDeleted).length;
  }

  int get _normalUserCount {
    return _users.where((user) => !user.isDeleted).length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    final showingDeletedUsers = _statusFilter == 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        _buildSummaryCards(),
        const SizedBox(height: 20),
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildUsersTable(
            filteredUsers,
            showingDeletedUsers: showingDeletedUsers,
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kullanıcı Yönetimi',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Kullanıcı hesaplarını, durumlarını ve giriş hareketlerini yönetin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Yeni Kullanıcı'),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final passwordChangeCount = _users.where((user) {
      return !user.isDeleted && user.mustChangePassword;
    }).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Toplam Kullanıcı',
          value: _normalUserCount.toString(),
          icon: Icons.people_outline,
        ),
        _SummaryCard(
          title: 'Aktif Kullanıcı',
          value: _activeUserCount.toString(),
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        ),
        _SummaryCard(
          title: 'Pasif Kullanıcı',
          value: _inactiveUserCount.toString(),
          icon: Icons.pause_circle_outline,
          iconColor: AppColors.warning,
        ),
        _SummaryCard(
          title: 'Silinen Kullanıcı',
          value: _deletedUserCount.toString(),
          icon: Icons.delete_outline,
          iconColor: AppColors.danger,
        ),
        _SummaryCard(
          title: 'Şifre Değiştirecek',
          value: passwordChangeCount.toString(),
          icon: Icons.key_outlined,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Ad, e-posta veya departman ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(value: 0, label: Text('Tümü')),
              ButtonSegment<int>(value: 1, label: Text('Aktif')),
              ButtonSegment<int>(value: 2, label: Text('Pasif')),
              ButtonSegment<int>(
                value: 3,
                label: Text('Silinenler'),
                icon: Icon(Icons.delete_outline),
              ),
            ],
            selected: {_statusFilter},
            onSelectionChanged: (selection) {
              setState(() {
                _statusFilter = selection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(
    List<AppUser> users, {
    required bool showingDeletedUsers,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: users.isEmpty
          ? _buildEmptyState(showingDeletedUsers)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      // Yalnızca dikey kaydırma — tablo satırları çok olunca
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          // Tablo her zaman en az container genişliğini doldurur
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.background,
                            ),
                            columnSpacing: 28,
                            horizontalMargin: 20,
                            dataRowMinHeight: 68,
                            dataRowMaxHeight: 86,
                            columns: [
                              const DataColumn(label: Text('Kullanıcı')),
                              const DataColumn(label: Text('Departmanlar')),
                              DataColumn(
                                label: Text(
                                  showingDeletedUsers
                                      ? 'Silinme Tarihi'
                                      : 'Son Giriş',
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  showingDeletedUsers
                                      ? 'Silen Kullanıcı'
                                      : 'Son Çıkış',
                                ),
                              ),
                              const DataColumn(label: Text('Durum')),
                              const DataColumn(label: Text('İşlemler')),
                            ],
                            rows: users.map((user) {
                              return _buildUserRow(
                                user,
                                showingDeletedUsers: showingDeletedUsers,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }


  DataRow _buildUserRow(AppUser user, {required bool showingDeletedUsers}) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 230,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: user.departments.isEmpty
                ? const Text(
                    'Atanmadı',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: user.departments.map((department) {
                      return _DepartmentChip(label: department);
                    }).toList(),
                  ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              showingDeletedUsers
                  ? _formatDateTime(user.deletedAt)
                  : _formatDateTime(user.lastLoginAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              showingDeletedUsers
                  ? user.deletedBy ?? 'Bilinmiyor'
                  : _formatDateTime(user.lastLogoutAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          showingDeletedUsers
              ? const _DeletedBadge()
              : _StatusBadge(isActive: user.isActive),
        ),
        DataCell(
          showingDeletedUsers
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Kullanıcıyı geri yükle',
                      onPressed: () {
                        _showRestoreUserDialog(user);
                      },
                      icon: const Icon(
                        Icons.restore_outlined,
                        size: 21,
                        color: AppColors.success,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kalıcı olarak sil',
                      onPressed: () {
                        _showPermanentDeleteDialog(user);
                      },
                      icon: const Icon(
                        Icons.delete_forever_outlined,
                        size: 21,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Kullanıcıyı düzenle',
                      onPressed: () {
                        _showEditUserDialog(user);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: user.isActive
                          ? 'Kullanıcıyı pasifleştir'
                          : 'Kullanıcıyı aktifleştir',
                      onPressed: () {
                        _toggleUserStatus(user);
                      },
                      icon: Icon(
                        user.isActive
                            ? Icons.person_off_outlined
                            : Icons.person_add_alt_outlined,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Şifre yenileme anahtarı oluştur',
                      onPressed: () {
                        _showPasswordResetDialog(user);
                      },
                      icon: const Icon(Icons.key_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Kullanıcıyı sil',
                      onPressed: () {
                        _showSoftDeleteDialog(user);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool showingDeletedUsers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showingDeletedUsers
                  ? Icons.delete_sweep_outlined
                  : Icons.search_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              showingDeletedUsers
                  ? 'Silinen kullanıcı bulunmuyor'
                  : 'Kullanıcı bulunamadı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              showingDeletedUsers
                  ? 'Silinen kullanıcılar burada görüntülenecek.'
                  : 'Arama veya filtre kriterlerini değiştirin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    if (user.isDeleted) {
      return;
    }

    try {
      await ref
          .read(usersProvider.notifier)
          .updateUser(user.copyWith(isActive: !user.isActive));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive
                ? '${user.name} pasif duruma getirildi.'
                : '${user.name} aktif duruma getirildi.',
          ),
        ),
      );
    } catch (e) {
      _showActionError('Kullanıcı durumu güncellenemedi', e);
    }
  }

  Future<void> _showSoftDeleteDialog(AppUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kullanıcıyı sil'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name} silinen kullanıcılar bölümüne taşınacak.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu kullanıcı daha sonra geri yüklenebilir. Kullanıcı sisteme giriş yapamaz ve Permissions ekranında görünmez.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(usersProvider.notifier).softDelete(user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} silinen kullanıcılar bölümüne taşındı.'),
          action: SnackBarAction(
            label: 'Geri Al',
            onPressed: () {
              _restoreUser(user.id);
            },
          ),
        ),
      );
    } catch (e) {
      _showActionError('Kullanıcı silinemedi', e);
    }
  }

  Future<void> _showRestoreUserDialog(AppUser user) async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kullanıcıyı geri yükle'),
          content: Text(
            '${user.name} tekrar aktif kullanıcı listesine alınacak.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Geri Yükle'),
            ),
          ],
        );
      },
    );

    if (shouldRestore == true) {
      _restoreUser(user.id);
    }
  }

  Future<void> _restoreUser(String userId) async {
    AppUser? user;
    for (final item in _users) {
      if (item.id == userId) {
        user = item;
        break;
      }
    }

    try {
      await ref.read(usersProvider.notifier).restore(userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user?.name ?? 'Kullanıcı'} geri yüklendi.')),
      );
    } catch (e) {
      _showActionError('Kullanıcı geri yüklenemedi', e);
    }
  }

  Future<void> _showPermanentDeleteDialog(AppUser user) async {
    final confirmationController = TextEditingController();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = confirmationController.text.trim() == 'SİL';

            return AlertDialog(
              title: const Text('Kalıcı olarak sil'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name} sistemden kalıcı olarak silinecek.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu işlem geri alınamaz. Kullanıcının hesabı, departman erişimleri ve yetkileri tamamen kaldırılır.',
                      style: TextStyle(fontSize: 13, color: AppColors.danger),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Onaylamak için aşağıdaki alana SİL yazın.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmationController,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'SİL',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  onPressed: canDelete
                      ? () {
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Kalıcı Olarak Sil'),
                ),
              ],
            );
          },
        );
      },
    );

    confirmationController.dispose();

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(usersProvider.notifier).permanentlyDelete(user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} kalıcı olarak silindi.')),
      );
    } catch (e) {
      _showActionError('Kullanıcı kalıcı olarak silinemedi', e);
    }
  }

  Future<void> _showPasswordResetDialog(AppUser user) async {
    final keyController = TextEditingController();
    bool obscureKey = true;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Şifre yenileme anahtarı'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name} için geçici bir anahtar belirleyin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: keyController,
                      obscureText: obscureKey,
                      decoration: InputDecoration(
                        labelText: 'Geçici anahtar',
                        hintText: 'En az 8 karakter',
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureKey = !obscureKey;
                            });
                          },
                          icon: Icon(
                            obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (keyController.text.trim().length < 8) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Anahtarı Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    keyController.dispose();

    if (shouldReset != true) {
      return;
    }

    try {
      await ref.read(usersProvider.notifier).forcePasswordReset(user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} için şifre yenileme zorlandı.')),
      );
    } catch (e) {
      _showActionError('Şifre yenileme başlatılamadı', e);
    }
  }

  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(
      text: 'TemporaryPassword123!',
    );
    bool obscurePassword = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni kullanıcı ekle'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ad soyad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Geçici şifre',
                        helperText:
                            'Kullanıcı ilk girişten sonra değiştirebilir.',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Departman ve scoped permission ayarları Permissions ekranından atanacaktır.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            _showActionError(
                              'Kullanıcı eklenemedi',
                              'Ad soyad, e-posta ve geçici şifre zorunludur.',
                            );
                            return;
                          }

                          if (!_looksLikeEmail(email)) {
                            _showActionError(
                              'Kullanıcı eklenemedi',
                              'Geçerli bir e-posta adresi girin.',
                            );
                            return;
                          }

                          if (password.length < 8) {
                            _showActionError(
                              'Kullanıcı eklenemedi',
                              'Geçici şifre en az 8 karakter olmalıdır.',
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await ref.read(usersProvider.notifier).createUser(
                                  name: name,
                                  email: email,
                                  password: password,
                                );

                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kullanıcı başarıyla eklendi.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            _showActionError('Kullanıcı eklenemedi', e);
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(isSubmitting ? 'Ekleniyor...' : 'Kullanıcı Ekle'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);

    final emailController = TextEditingController(text: user.email);

    final result = await showDialog<AppUser>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kullanıcıyı düzenle'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad soyad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(user.copyWith(name: name, email: email));
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();

    if (result == null) {
      return;
    }

    if (!_looksLikeEmail(result.email)) {
      _showActionError(
        'Kullanıcı güncellenemedi',
        'Geçerli bir e-posta adresi girin.',
      );
      return;
    }

    try {
      await ref.read(usersProvider.notifier).updateUser(result);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.name} güncellendi.')),
      );
    } catch (e) {
      _showActionError('Kullanıcı güncellenemedi', e);
    }
  }

  bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  void _showActionError(String title, Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('$title: $error'),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Henüz yok';
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year\n$hour:$minute';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentChip extends StatelessWidget {
  final String label;

  const _DepartmentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Pasif',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeletedBadge extends StatelessWidget {
  const _DeletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Silindi',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.danger,
        ),
      ),
    );
  }
}
