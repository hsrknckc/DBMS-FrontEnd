import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/database_item.dart';
import '../../models/permission.dart';
import 'controllers/databases_notifier.dart';

class DatabasesPage extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const DatabasesPage({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<DatabasesPage> createState() => _DatabasesPageState();
}

class _DatabasesPageState extends ConsumerState<DatabasesPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String? _selectedDepartment;

  /// 0: Aktif database'ler
  /// 1: Silinen database'ler
  int _viewFilter = 0;

  static const List<String> _defaultDepartments = [
    'Sensor',
    'Signal',
    'Acoustic',
    'Sonar',
    'General',
    'Test',
  ];

  List<DatabaseItem> get _databases {
    final dbState = ref.watch(databasesProvider);
    return dbState.valueOrNull ?? [];
  }

  List<String> get _departments {
    final serverDepts = _databases
        .map((database) => database.department)
        .where((dept) => dept.trim().isNotEmpty);

    final allDepts = {..._defaultDepartments, ...serverDepts}.toList();
    allDepts.sort();

    return allDepts;
  }

  bool get _canCreateDatabase {
    return widget.currentUser.hasPermission(
      Permission.databaseCreate,
    );
  }

  bool get _isSuperAdmin {
    return widget.currentUser.isSuperAdmin;
  }

  List<DatabaseItem> get _filteredDatabases {
    final query = _searchController.text.trim().toLowerCase();

    return _databases.where((database) {
      final matchesDeletedState = _viewFilter == 0
          ? !database.isDeleted
          : database.isDeleted;

      if (!matchesDeletedState) {
        return false;
      }

      final matchesSearch =
          query.isEmpty ||
          database.name.toLowerCase().contains(query) ||
          database.description.toLowerCase().contains(query) ||
          database.department.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      final matchesDepartment =
          _selectedDepartment == null ||
          database.department == _selectedDepartment;

      if (!matchesDepartment) {
        return false;
      }

      if (_isSuperAdmin) {
        return true;
      }

      return widget.currentUser.canAccessDepartment(
        database.department,
      );
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databases = _filteredDatabases;
    final showingDeleted = _viewFilter == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildSummaryCards(),
        const SizedBox(height: 18),
        _buildFilters(),
        const SizedBox(height: 18),
        Expanded(
          child: databases.isEmpty
              ? _buildEmptyState(showingDeleted)
              : _buildDatabaseGrid(
                  databases,
                  showingDeleted: showingDeleted,
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Database Yönetimi',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Departmanlara ait database yapılarını görüntüleyin ve yönetin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_canCreateDatabase)
          ElevatedButton.icon(
            onPressed: _showCreateDatabaseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Database'),
          ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final activeCount = _databases.where((database) {
      return !database.isDeleted;
    }).length;

    final deletedCount = _databases.where((database) {
      return database.isDeleted;
    }).length;

    final totalRecords = _databases
        .where((database) => !database.isDeleted)
        .fold<int>(
          0,
          (total, database) => total + database.recordCount,
        );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Aktif Database',
          value: activeCount.toString(),
          icon: Icons.storage_outlined,
        ),
        _SummaryCard(
          title: 'Toplam Kayıt',
          value: _formatNumber(totalRecords),
          icon: Icons.table_rows_outlined,
        ),
        _SummaryCard(
          title: 'Departman',
          value: _departments.length.toString(),
          icon: Icons.apartment_outlined,
        ),
        if (_isSuperAdmin)
          _SummaryCard(
            title: 'Silinen Database',
            value: deletedCount.toString(),
            icon: Icons.delete_outline,
            iconColor: AppColors.danger,
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isNarrow
                    ? constraints.maxWidth
                    : 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Database ara...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: isNarrow
                    ? constraints.maxWidth
                    : 220,
                child: DropdownButtonFormField<String?>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Departman',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tüm departmanlar'),
                    ),
                    ..._departments.map((department) {
                      return DropdownMenuItem<String?>(
                        value: department,
                        child: Text(department),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                ),
              ),
              if (_isSuperAdmin)
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Aktif'),
                      icon: Icon(Icons.storage_outlined),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Silinenler'),
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                  selected: {_viewFilter},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _viewFilter = selection.first;
                    });
                  },
                ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(
                  Icons.filter_alt_off_outlined,
                ),
                label: const Text('Filtreleri temizle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDatabaseGrid(
    List<DatabaseItem> databases, {
    required bool showingDeleted,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = switch (constraints.maxWidth) {
          >= 1200 => 3,
          >= 760 => 2,
          _ => 1,
        };

        final spacing = 16.0;

        final cardWidth = (
          constraints.maxWidth -
          ((columnCount - 1) * spacing)
        ) / columnCount;

        return SingleChildScrollView(
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: databases.map((database) {
              return SizedBox(
                width: cardWidth,
                child: _DatabaseCard(
                  database: database,
                  showingDeleted: showingDeleted,
                  isSuperAdmin: _isSuperAdmin,
                  onOpen: () {
                    _showDatabaseDetails(database);
                  },
                  onDelete: () {
                    _showSoftDeleteDialog(database);
                  },
                  onRestore: () {
                    _showRestoreDialog(database);
                  },
                  onPermanentDelete: () {
                    _showPermanentDeleteDialog(database);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool showingDeleted) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showingDeleted
                  ? Icons.delete_sweep_outlined
                  : Icons.storage_outlined,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              showingDeleted
                  ? 'Silinen database bulunmuyor'
                  : 'Database bulunamadı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              showingDeleted
                  ? 'Silinen database kayıtları burada görünür.'
                  : 'Arama veya filtre kriterlerini değiştirin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDepartment = null;
    });
  }

  Future<void> _showCreateDatabaseDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    String? selectedDepartment;

    final result = await showDialog<DatabaseItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Database'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Database adı',
                        prefixIcon: Icon(
                          Icons.storage_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Departman',
                        prefixIcon: Icon(
                          Icons.apartment_outlined,
                        ),
                      ),
                      items: _departments.map((department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDepartment = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        alignLabelWithHint: true,
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
                    final description =
                        descriptionController.text.trim();

                    if (name.isEmpty ||
                        selectedDepartment == null) {
                      return;
                    }

                    final now = DateTime.now();

                    Navigator.of(dialogContext).pop(
                      DatabaseItem(
                        id: now.millisecondsSinceEpoch.toString(),
                        name: name,
                        department: selectedDepartment!,
                        description: description.isEmpty
                            ? 'Açıklama eklenmedi.'
                            : description,
                        collectionCount: 0,
                        recordCount: 0,
                        createdAt: now,
                        updatedAt: now,
                      ),
                    );
                  },
                  child: const Text('Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (result == null) {
      return;
    }

    try {
      await ref.read(databasesProvider.notifier).createDatabase(
        name: result.name,
        department: result.department,
        description: result.description,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} oluşturuldu.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _showDatabaseDetails(
    DatabaseItem database,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(database.name),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(
                  label: 'Departman',
                  value: database.department,
                ),
                _DetailRow(
                  label: 'Açıklama',
                  value: database.description,
                ),
                _DetailRow(
                  label: 'Collection',
                  value: database.collectionCount.toString(),
                ),
                _DetailRow(
                  label: 'Kayıt',
                  value: _formatNumber(
                    database.recordCount,
                  ),
                ),
                _DetailRow(
                  label: 'Oluşturulma',
                  value: _formatDateTime(
                    database.createdAt,
                  ),
                ),
                _DetailRow(
                  label: 'Son güncelleme',
                  value: _formatDateTime(
                    database.updatedAt,
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
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSoftDeleteDialog(
    DatabaseItem database,
  ) async {
    if (!_isSuperAdmin) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Database silinsin mi?'),
          content: Text(
            '${database.name} silinen database bölümüne taşınacak.',
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
      await ref.read(databasesProvider.notifier).softDelete(database.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${database.name} silinenlere taşındı.',
          ),
          action: SnackBarAction(
            label: 'Geri Al',
            onPressed: () {
              _restoreDatabase(database.id);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _showRestoreDialog(
    DatabaseItem database,
  ) async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Database geri yüklensin mi?'),
          content: Text(
            '${database.name} yeniden aktif database listesine alınacak.',
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
      await _restoreDatabase(database.id);
    }
  }

  Future<void> _restoreDatabase(String databaseId) async {
    try {
      await ref.read(databasesProvider.notifier).restore(databaseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database geri yüklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _showPermanentDeleteDialog(
    DatabaseItem database,
  ) async {
    if (!_isSuperAdmin) {
      return;
    }

    final confirmationController =
        TextEditingController();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete =
                confirmationController.text.trim() == 'SİL';

            return AlertDialog(
              title: const Text(
                'Database kalıcı olarak silinsin mi?',
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${database.name} kalıcı olarak silinecek.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu işlem geri alınamaz. Devam etmek için SİL yazın.',
                      style: TextStyle(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmationController,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'SİL',
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
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                  ),
                  label: const Text('Kalıcı Sil'),
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
      await ref.read(databasesProvider.notifier).permanentlyDelete(database.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${database.name} kalıcı olarak silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(2, '0');
    final month =
        dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour =
        dateTime.hour.toString().padLeft(2, '0');
    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _formatNumber(int number) {
    final text = number.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;

      buffer.write(text[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

class _DatabaseCard extends StatelessWidget {
  final DatabaseItem database;
  final bool showingDeleted;
  final bool isSuperAdmin;

  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _DatabaseCard({
    required this.database,
    required this.showingDeleted,
    required this.isSuperAdmin,
    required this.onOpen,
    required this.onDelete,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.storage_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  database.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            database.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _CardMetadata(
            icon: Icons.apartment_outlined,
            value: database.department,
          ),
          const SizedBox(height: 8),
          _CardMetadata(
            icon: Icons.folder_copy_outlined,
            value:
                '${database.collectionCount} collection',
          ),
          const SizedBox(height: 8),
          _CardMetadata(
            icon: Icons.table_rows_outlined,
            value: '${database.recordCount} kayıt',
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          if (showingDeleted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(
                      Icons.restore_outlined,
                    ),
                    label: const Text('Geri Yükle'),
                  ),
                ),
                if (isSuperAdmin) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Kalıcı sil',
                    onPressed: onPermanentDelete,
                    icon: const Icon(
                      Icons.delete_forever_outlined,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text('Görüntüle'),
                  ),
                ),
                if (isSuperAdmin) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Database sil',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
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
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
    );
  }
}

class _CardMetadata extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CardMetadata({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}