import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/data_record.dart';
import '../../models/permission.dart';
import '../databases/controllers/databases_notifier.dart';
import './controllers/data_explorer_notifier.dart';
import '../../core/providers/repository_providers.dart';
import '../../repositories/data_explorer/tcp_data_explorer_repository.dart';
import '../../core/providers/schema_provider.dart';

enum RecordFieldType {
  string,
  integer,
  double,
  boolean,
  dateTime,
  array,
  object,
  nullValue,
}

class DataExplorerPage extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const DataExplorerPage({super.key, required this.currentUser});

  @override
  ConsumerState<DataExplorerPage> createState() => _DataExplorerPageState();
}

class _DataExplorerPageState extends ConsumerState<DataExplorerPage> {
  static String? _lastSelectedDatabaseId;
  static String? _lastSelectedCollection;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableHorizontalScrollController = ScrollController();
  final ScrollController _tableVerticalScrollController = ScrollController();

  String? _selectedDatabaseId;
  String? _selectedCollection;

  bool _showJsonView = false;
  bool _isImporting = false;

  static final Map<String, Set<String>> _extraCollections = {};
  static final Map<String, List<String>> _serverCollections = {};
  bool _collectionsLoading = false;

  /// Sunucudan LIST_COLLECTIONS ile koleksiyonları çeker ve cache'ler.
  Future<void> _loadCollectionsForDatabase(String dbId, String dbName) async {
    if (_collectionsLoading) return;
    _collectionsLoading = true;

    try {
      final repo = ref.read(dataExplorerRepositoryProvider);
      if (repo is TcpDataExplorerRepository) {
        final cols = await repo.getCollections(dbName);
        if (mounted && cols.isNotEmpty) {
          setState(() {
            _serverCollections[dbId] = cols;
          });
        }
      }
    } catch (e) {
      print('[DataExplorer] LIST_COLLECTIONS hatası: $e');
    } finally {
      _collectionsLoading = false;
    }
  }

  List<_ExplorerDatabase> get _visibleDatabases {
    final dbAsync = ref.watch(databasesProvider);
    final serverDbs = dbAsync.valueOrNull ?? [];

    final seenKeys = <String>{};
    final List<_ExplorerDatabase> sourceList = [];

    for (final db in serverDbs) {
      final dbKey = db.name.isNotEmpty ? db.name : db.id;
      if (!seenKeys.add(dbKey)) continue;

      final serverCols =
          _serverCollections[dbKey] ?? _serverCollections[db.id] ?? [];
      final extraCols =
          _extraCollections[dbKey] ?? _extraCollections[db.id] ?? <String>{};
      final mergedCols = {...serverCols, ...extraCols}.toList();

      sourceList.add(
        _ExplorerDatabase(
          id: dbKey,
          name: db.name.isNotEmpty ? db.name : db.id,
          department: db.department,
          collections: mergedCols,
        ),
      );
    }

    if (widget.currentUser.isSuperAdmin) {
      return sourceList;
    }

    return sourceList
        .map((database) {
          if (!widget.currentUser.canAccessDepartment(database.department)) {
            return null;
          }

          final allowedCols = database.collections.where((col) {
            return widget.currentUser.canAccessCollection(
              database.department,
              col,
            );
          }).toList();

          if (allowedCols.isEmpty) return null;

          return _ExplorerDatabase(
            id: database.id,
            name: database.name,
            department: database.department,
            collections: allowedCols,
          );
        })
        .whereType<_ExplorerDatabase>()
        .toList();
  }

  _ExplorerDatabase? get _selectedDatabase {
    final selectedId = _selectedDatabaseId;

    if (selectedId == null) {
      return null;
    }

    for (final database in _visibleDatabases) {
      if (database.id == selectedId) {
        return database;
      }
    }

    return null;
  }

  List<DataRecord> get _filteredRecords {
    final databaseId = _selectedDatabaseId;
    final collectionName = _selectedCollection;

    if (databaseId == null || collectionName == null) {
      return [];
    }

    final recordsAsync = ref.watch(dataExplorerProvider);
    final sourceRecords = recordsAsync.valueOrNull ?? [];

    final query = _searchController.text.trim().toLowerCase();

    return sourceRecords.where((record) {
      if (query.isEmpty) {
        return true;
      }

      final searchableText = [
        record.id,
        ...record.data.entries.map((entry) => '${entry.key} ${entry.value}'),
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  bool get _canView {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataView);
  }

  bool get _canCreate {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataCreate);
  }

  bool get _canUpdate {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataUpdate);
  }

  bool get _canDelete {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataDelete);
  }

  bool get _canImport {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataImport);
  }

  // Export yetkisi: tüm kullanıcılar dışa aktarabilir; _canExport
  // tutuldu ama PopupMenuButton üzerinden erişim direkt olduğundan
  // bu getter referans edilmiyor — ileride ihtiyaç duyulursa kullanılır.
  // ignore: unused_element
  bool get _canExport {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataExport);
  }

  bool get _hasSelection {
    return _selectedDatabaseId != null && _selectedCollection != null;
  }

  @override
  void initState() {
    super.initState();
    _selectedDatabaseId =
        ref.read(selectedDatabaseIdProvider) ?? _lastSelectedDatabaseId;
    _selectedCollection =
        ref.read(selectedCollectionProvider) ?? _lastSelectedCollection;
  }

  void _ensureSelection(List<_ExplorerDatabase> databases) {
    if (databases.isEmpty) return;

    final currentRefDb = ref.read(selectedDatabaseIdProvider);
    final currentRefCol = ref.read(selectedCollectionProvider);

    if (_selectedDatabaseId == null) {
      if (currentRefDb != null &&
          databases.any((db) => db.id == currentRefDb)) {
        _selectedDatabaseId = currentRefDb;
      } else if (_lastSelectedDatabaseId != null &&
          databases.any((db) => db.id == _lastSelectedDatabaseId)) {
        _selectedDatabaseId = _lastSelectedDatabaseId;
      }
    }

    if (_selectedDatabaseId == null) return;

    final selectedDb = databases.firstWhere(
      (db) => db.id == _selectedDatabaseId,
      orElse: () => databases.first,
    );

    if (!_serverCollections.containsKey(selectedDb.id)) {
      _loadCollectionsForDatabase(selectedDb.id, selectedDb.name);
    }

    if (_selectedCollection == null) {
      if (currentRefCol != null &&
          selectedDb.collections.contains(currentRefCol)) {
        _selectedCollection = currentRefCol;
      } else if (_lastSelectedCollection != null &&
          selectedDb.collections.contains(_lastSelectedCollection)) {
        _selectedCollection = _lastSelectedCollection;
      }
    }

    _lastSelectedDatabaseId = _selectedDatabaseId;
    _lastSelectedCollection = _selectedCollection;

    if (currentRefDb != _selectedDatabaseId ||
        currentRefCol != _selectedCollection) {
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedDatabaseIdProvider.notifier).state =
              _selectedDatabaseId;
          ref.read(selectedCollectionProvider.notifier).state =
              _selectedCollection;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableHorizontalScrollController.dispose();
    _tableVerticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return _buildAccessDenied();
    }

    _ensureSelection(_visibleDatabases);

    final records = _filteredRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSelectionPanel(),
        const SizedBox(height: 16),
        _buildToolbar(records.length),
        const SizedBox(height: 16),
        Expanded(
          child: !_hasSelection
              ? _buildNoSelection()
              : records.isEmpty
              ? _buildEmptyState()
              : _showJsonView
              ? _buildJsonView(records)
              : _buildTableView(records),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Explorer',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Database collection kayıtlarını görüntüleyin, içe aktarın ve yönetin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );

        // ── Yazma yetkisi kontrolü ──────────────────────────────────────────
        // SuperAdmin her zaman tam yetkili.
        // Normal kullanıcı için _canImport / _canCreate yoksa butonlar
        // görünür ama disabled + %50 opaklık + Tooltip ile uyarı verir.
        const noWriteTooltip =
            'Bu işlem için yazma yetkiniz bulunmamaktadır.\nYöneticinizle iletişime geçin.';

        Widget createBtn = Opacity(
          opacity: _canCreate ? 1.0 : 0.5,
          child: Tooltip(
            message: _canCreate ? '' : noWriteTooltip,
            child: ElevatedButton.icon(
              onPressed: _canCreate && _hasSelection
                  ? _showCreateRecordDialog
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Kayıt'),
            ),
          ),
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [createBtn],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleSection, const SizedBox(height: 14), actions],
          );
        }

        return Row(
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSelectionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                width: isNarrow ? constraints.maxWidth : 300,
                child: DropdownButtonFormField<String>(
                  value:
                      _visibleDatabases.any(
                        (db) => db.id == _selectedDatabaseId,
                      )
                      ? _selectedDatabaseId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Database',
                    prefixIcon: Icon(Icons.storage_outlined),
                  ),
                  items: _visibleDatabases.map((database) {
                    return DropdownMenuItem<String>(
                      value: database.id,
                      child: Text(
                        database.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    final database = _visibleDatabases.firstWhere(
                      (item) => item.id == value,
                    );

                    setState(() {
                      _selectedDatabaseId = value;
                      _selectedCollection = database.collections.isEmpty
                          ? null
                          : database.collections.first;
                      _searchController.clear();
                      _lastSelectedDatabaseId = _selectedDatabaseId;
                      _lastSelectedCollection = _selectedCollection;
                    });
                    ref.read(selectedDatabaseIdProvider.notifier).state =
                        _selectedDatabaseId;
                    ref.read(selectedCollectionProvider.notifier).state =
                        _selectedCollection;

                    // Yeni veritabanı seçildiğinde koleksiyonlarını sunucudan çek
                    _loadCollectionsForDatabase(database.id, database.name);
                  },
                ),
              ),
              SizedBox(
                width: isNarrow ? constraints.maxWidth : 340,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            (_selectedDatabase?.collections.contains(
                                  _selectedCollection,
                                ) ??
                                false)
                            ? _selectedCollection
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Collection',
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        items: (_selectedDatabase?.collections ?? []).map((
                          collection,
                        ) {
                          return DropdownMenuItem<String>(
                            value: collection,
                            child: Text(
                              collection,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCollection = value;
                            _searchController.clear();
                            _lastSelectedCollection = value;
                          });
                          ref.read(selectedCollectionProvider.notifier).state =
                              value;
                        },
                      ),
                    ),
                    if (_canCreate && _selectedDatabase != null) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Yeni Collection Ekle',
                        child: InkWell(
                          onTap: _showAddCollectionDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_canDelete &&
                        _selectedDatabase != null &&
                        _selectedCollection != null) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Seçili Collection\'ı Sil',
                        child: InkWell(
                          onTap: _showDeleteCollectionDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_selectedDatabase != null)
                _InfoBadge(
                  icon: Icons.apartment_outlined,
                  text: _selectedDatabase!.department,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(int recordCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          final searchField = SizedBox(
            width: isNarrow ? constraints.maxWidth : 320,
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Kayıtlarda ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          );

          final controls = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.table_rows_outlined),
                    label: Text('Tablo'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.data_object),
                    label: Text('JSON'),
                  ),
                ],
                selected: {_showJsonView},
                onSelectionChanged: (selection) {
                  setState(() {
                    _showJsonView = selection.first;
                  });
                },
              ),
              _InfoBadge(
                icon: Icons.description_outlined,
                text: '$recordCount kayıt',
              ),
              // Export: tüm kullanıcılar görebilir.
              // PopupMenuButton ile format seçimi yapılır.
              PopupMenuButton<String>(
                enabled: recordCount > 0,
                tooltip: recordCount == 0
                    ? 'Dışa aktarılacak kayıt yok'
                    : 'Dışa Aktar',
                offset: const Offset(0, 44),
                onSelected: _exportWithFormat,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'JSON',
                    child: Row(
                      children: [
                        Icon(Icons.data_object, size: 18),
                        SizedBox(width: 10),
                        Text('JSON Formatında İndir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'CSV',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('CSV Formatında İndir'),
                      ],
                    ),
                  ),
                ],
                child: IgnorePointer(
                  child: OutlinedButton.icon(
                    onPressed: recordCount == 0 ? null : () {},
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Dışa Aktar'),
                  ),
                ),
              ),
              if (_canImport)
                OutlinedButton.icon(
                  onPressed: _pickAndImportJson,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('İçe Aktar'),
                ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [searchField, const SizedBox(height: 12), controls],
            );
          }

          return Row(children: [searchField, const Spacer(), controls]);
        },
      ),
    );
  }

  Widget _buildTableView(List<DataRecord> records) {
    final columns = _findColumns(records);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Scrollbar(
            controller: _tableHorizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _tableHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _tableVerticalScrollController,
                child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(
                  AppColors.background,
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'ID',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...columns.map((column) {
                    return DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }),
                  const DataColumn(
                    label: Text(
                      'İşlemler',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                rows: records.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            record.id,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...columns.map((column) {
                        return DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              _displayValue(record.data[column]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: _canUpdate
                                  ? 'Detay'
                                  : 'Detay (Sadece Okunabilir)',
                              onPressed: () {
                                _showRecordDetails(
                                  record,
                                  readOnly: !_canUpdate,
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            Opacity(
                              opacity: _canUpdate ? 1.0 : 0.5,
                              child: Tooltip(
                                message: _canUpdate
                                    ? 'Düzenle'
                                    : 'Bu işlem için yazma yetkiniz bulunmamaktadır.',
                                child: IconButton(
                                  onPressed: _canUpdate
                                      ? () => _showEditRecordDialog(record)
                                      : null,
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: _canDelete ? 1.0 : 0.5,
                              child: Tooltip(
                                message: _canDelete
                                    ? 'Sil'
                                    : 'Bu işlem için yazma yetkiniz bulunmamaktadır.',
                                child: IconButton(
                                  onPressed: _canDelete
                                      ? () => _showDeleteDialog(record)
                                      : null,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildJsonView(List<DataRecord> records) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 14);
        },
        itemBuilder: (context, index) {
          final record = records[index];

          final jsonText = const JsonEncoder.withIndent(
            '  ',
          ).convert({'_id': record.id, ...record.data});

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Detay',
                      onPressed: () {
                        _showRecordDetails(record);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    Opacity(
                      opacity: _canUpdate ? 1.0 : 0.5,
                      child: Tooltip(
                        message: _canUpdate
                            ? 'Düzenle'
                            : 'Bu işlem için yazma yetkiniz bulunmamaktadır.',
                        child: IconButton(
                          onPressed: _canUpdate
                              ? () => _showEditRecordDialog(record)
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _canDelete ? 1.0 : 0.5,
                      child: Tooltip(
                        message: _canDelete
                            ? 'Sil'
                            : 'Bu işlem için yazma yetkiniz bulunmamaktadır.',
                        child: IconButton(
                          onPressed: _canDelete
                              ? () => _showDeleteDialog(record)
                              : null,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                SelectableText(
                  jsonText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndImportJson() async {
    if (!_canImport || !_hasSelection) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'MongoDB JSON dosyasını seçin',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedFile = result.files.single;
      final bytes = selectedFile.bytes;

      if (bytes == null) {
        _showErrorMessage('Dosya içeriği okunamadı.');
        return;
      }

      final jsonText = _decodeJsonBytes(bytes);

      final importedDocuments = _parseImportedDocuments(jsonText);

      if (importedDocuments.isEmpty) {
        _showErrorMessage('Dosyada içe aktarılabilecek kayıt bulunamadı.');
        return;
      }

      if (!mounted) {
        return;
      }

      final shouldImport = await _showImportPreviewDialog(
        fileName: selectedFile.name,
        documents: importedDocuments,
      );

      if (shouldImport != true || !mounted) {
        return;
      }

      _importDocuments(importedDocuments);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${importedDocuments.length} kayıt içe aktarıldı.'),
        ),
      );
    } on FormatException catch (error) {
      _showErrorMessage(error.message);
    } catch (error) {
      _showErrorMessage(
        'JSON dosyası içe aktarılırken bir hata oluştu: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  String _decodeJsonBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('Dosya UTF-8 formatında okunamadı.');
    }
  }

  List<Map<String, dynamic>> _parseImportedDocuments(String jsonText) {
    final trimmedText = jsonText.trim();

    if (trimmedText.isEmpty) {
      throw const FormatException('Seçilen JSON dosyası boş.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(trimmedText);
    } on FormatException {
      return _parseJsonLines(trimmedText);
    }

    if (decoded is Map) {
      return [Map<String, dynamic>.from(decoded)];
    }

    if (decoded is List) {
      final documents = <Map<String, dynamic>>[];

      for (var index = 0; index < decoded.length; index++) {
        final item = decoded[index];

        if (item is! Map) {
          throw FormatException('${index + 1}. kayıt bir JSON nesnesi değil.');
        }

        documents.add(Map<String, dynamic>.from(item));
      }

      return documents;
    }

    throw const FormatException(
      'Dosyanın kökünde bir JSON nesnesi veya JSON dizisi bulunmalıdır.',
    );
  }

  List<Map<String, dynamic>> _parseJsonLines(String jsonText) {
    final lines = const LineSplitter()
        .convert(jsonText)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException('JSON dosyasında kayıt bulunamadı.');
    }

    final documents = <Map<String, dynamic>>[];

    for (var index = 0; index < lines.length; index++) {
      dynamic decodedLine;

      try {
        decodedLine = jsonDecode(lines[index]);
      } on FormatException {
        throw FormatException('${index + 1}. satır geçerli JSON değil.');
      }

      if (decodedLine is! Map) {
        throw FormatException('${index + 1}. satır bir JSON nesnesi değil.');
      }

      documents.add(Map<String, dynamic>.from(decodedLine));
    }

    return documents;
  }

  Future<bool?> _showImportPreviewDialog({
    required String fileName,
    required List<Map<String, dynamic>> documents,
  }) {
    final previewDocuments = documents.take(3).toList();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('JSON içe aktarma önizlemesi'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImportInformationRow(label: 'Dosya', value: fileName),
                _ImportInformationRow(
                  label: 'Database',
                  value: _selectedDatabase?.name ?? '-',
                ),
                _ImportInformationRow(
                  label: 'Collection',
                  value: _selectedCollection ?? '-',
                ),
                _ImportInformationRow(
                  label: 'Kayıt sayısı',
                  value: documents.length.toString(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'İlk kayıtların önizlemesi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: previewDocuments.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final jsonText = const JsonEncoder.withIndent(
                        '  ',
                      ).convert(previewDocuments[index]);

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SelectableText(
                          jsonText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (documents.length > 3) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${documents.length - 3} kayıt daha bulunuyor.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
              icon: const Icon(Icons.upload_outlined),
              label: Text('${documents.length} Kaydı Aktar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importDocuments(List<Map<String, dynamic>> documents) async {
    final databaseId = _selectedDatabaseId;
    final collectionName = _selectedCollection;

    if (databaseId == null || collectionName == null) {
      return;
    }

    final now = DateTime.now();
    final importedRecords = <DataRecord>[];

    for (var index = 0; index < documents.length; index++) {
      final originalDocument = Map<String, dynamic>.from(documents[index]);

      final extractedId = _extractMongoDocumentId(originalDocument['_id']);

      originalDocument.remove('_id');

      importedRecords.add(
        DataRecord(
          id: extractedId ?? 'import-${now.millisecondsSinceEpoch}-$index',
          databaseId: databaseId,
          collectionName: collectionName,
          data: originalDocument,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (importedRecords.isNotEmpty) {
      final dataList = importedRecords.map((r) => r.data).toList();
      try {
        await ref.read(dataExplorerProvider.notifier).importRecords(dataList);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${importedRecords.length} kayıt içe aktarıldı.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('İçe aktarma hatası: $e')));
        }
      }
    }
  }

  String? _extractMongoDocumentId(dynamic idValue) {
    if (idValue == null) {
      return null;
    }

    if (idValue is String || idValue is num) {
      return idValue.toString();
    }

    if (idValue is Map) {
      final objectId = idValue[r'$oid'];

      if (objectId != null) {
        return objectId.toString();
      }

      return jsonEncode(idValue);
    }

    return idValue.toString();
  }

  RecordFieldType _mapStringToRecordFieldType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'integer': return RecordFieldType.integer;
      case 'double': return RecordFieldType.double;
      case 'boolean': return RecordFieldType.boolean;
      case 'array': return RecordFieldType.array;
      case 'object': return RecordFieldType.object;
      case 'datetime': return RecordFieldType.dateTime;
      default: return RecordFieldType.string;
    }
  }

  Map<String, RecordFieldType> _inferCollectionTypes() {
    final types = <String, RecordFieldType>{};
    final schema = ref.read(schemaProvider);
    
    final dbsAsync = ref.read(databasesProvider);
    final rawDatabases = dbsAsync.valueOrNull ?? [];
    String actualDbName = _selectedDatabaseId ?? '';
    if (actualDbName.isNotEmpty) {
      try {
        final db = rawDatabases.firstWhere((d) => d.id == _selectedDatabaseId || d.name == _selectedDatabaseId);
        actualDbName = db.name.isNotEmpty ? db.name : db.id;
      } catch (_) {}
    }
    final colName = _selectedCollection ?? '';

    for (var r in _filteredRecords) {
      for (var entry in r.data.entries) {
        final key = entry.key;
        final val = entry.value;
        
        final customKey = '${actualDbName}_${colName}_$key';
        final customTypeStr = schema[customKey];
        if (customTypeStr != null) {
           types[key] = _mapStringToRecordFieldType(customTypeStr);
           continue;
        }

        if (val != null && !types.containsKey(key)) {
          if (val is bool) {
            types[key] = RecordFieldType.boolean;
          } else if (val is int) {
            types[key] = RecordFieldType.integer;
          } else if (val is double) {
            types[key] = RecordFieldType.double;
          } else if (val is List) {
            types[key] = RecordFieldType.array;
          } else if (val is Map) {
            types[key] = RecordFieldType.object;
          } else if (DateTime.tryParse(val.toString()) != null &&
              val.toString().contains('-') &&
              val.toString().length >= 10) {
            types[key] = RecordFieldType.dateTime;
          } else {
            types[key] = RecordFieldType.string;
          }
        }
      }
    }
    
    final allKeys = <String>{};
    for (var r in _filteredRecords) {
      allKeys.addAll(r.data.keys);
    }
    
    final prefix = '${actualDbName}_${colName}_';
    for (final sk in schema.keys) {
      if (sk.startsWith(prefix)) {
        allKeys.add(sk.substring(prefix.length));
      }
    }

    for (var key in allKeys) {
      if (!types.containsKey(key)) {
        final customKey = '${actualDbName}_${colName}_$key';
        final customTypeStr = schema[customKey];
        if (customTypeStr != null) {
           types[key] = _mapStringToRecordFieldType(customTypeStr);
        } else {
           types[key] = RecordFieldType.string;
        }
      }
    }
    
    return types;
  }

  Future<void> _showCreateRecordDialog() async {
    final schemaTypes = _inferCollectionTypes();
    final initialData = <String, dynamic>{};
    for (var key in schemaTypes.keys) {
      initialData[key] = null; // Start empty
    }

    if (initialData.isEmpty) {
      initialData['yeni_alan'] = '';
    }

    final result = await _showRecordEditorDialog(
      title: 'Yeni Kayıt',
      initialData: initialData,
      saveButtonText: 'Kaydet',
      schemaTypes: schemaTypes,
    );

    if (result == null || !_hasSelection) {
      return;
    }

    try {
      await ref.read(dataExplorerProvider.notifier).createRecord(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni kayıt oluşturuldu.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _showEditRecordDialog(DataRecord record) async {
    final schemaTypes = _inferCollectionTypes();
    final allData = <String, dynamic>{};
    for (var key in schemaTypes.keys) {
      allData[key] = record.data[key];
    }
    for (var key in record.data.keys) {
      allData[key] = record.data[key];
    }

    final result = await _showRecordEditorDialog(
      title: 'Kaydı Düzenle',
      initialData: allData,
      saveButtonText: 'Değişiklikleri Kaydet',
      schemaTypes: schemaTypes,
    );

    if (result == null) {
      return;
    }

    try {
      final updatedRecord = record.copyWith(
        data: result,
        updatedAt: DateTime.now(),
      );
      await ref.read(dataExplorerProvider.notifier).updateRecord(updatedRecord);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kayıt güncellendi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<Map<String, dynamic>?> _showRecordEditorDialog({
    required String title,
    required Map<String, dynamic> initialData,
    required String saveButtonText,
    Map<String, RecordFieldType>? schemaTypes,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        String? errorMessage;
        bool isJsonMode = false;

        final formData = Map<String, dynamic>.from(initialData);
        final controllers = <String, TextEditingController>{};
        final types = <String, RecordFieldType>{};

        void initField(String key, dynamic val) {
          final inferredType = schemaTypes?[key];

          if (inferredType != null) {
            types[key] = inferredType;
            if (val == null) {
              if (inferredType == RecordFieldType.boolean) {
                controllers[key] = TextEditingController(text: 'null');
              } else {
                controllers[key] = TextEditingController(text: '');
              }
            } else if (inferredType == RecordFieldType.boolean) {
              controllers[key] = TextEditingController(text: val.toString());
            } else if (inferredType == RecordFieldType.array || inferredType == RecordFieldType.object) {
              controllers[key] = TextEditingController(text: (val is List || val is Map) ? jsonEncode(val) : val.toString());
            } else {
              controllers[key] = TextEditingController(text: val.toString());
            }
          } else {
            if (val == null) {
              types[key] = RecordFieldType.string;
              controllers[key] = TextEditingController(text: '');
            } else if (val is bool) {
              types[key] = RecordFieldType.boolean;
              controllers[key] = TextEditingController(text: val.toString());
            } else if (val is int) {
              types[key] = RecordFieldType.integer;
              controllers[key] = TextEditingController(text: val.toString());
            } else if (val is double) {
              types[key] = RecordFieldType.double;
              controllers[key] = TextEditingController(text: val.toString());
            } else if (val is num) {
              types[key] = RecordFieldType.integer;
              controllers[key] = TextEditingController(text: val.toString());
            } else if (val is List) {
              types[key] = RecordFieldType.array;
              controllers[key] = TextEditingController(text: jsonEncode(val));
            } else if (val is Map) {
              types[key] = RecordFieldType.object;
              controllers[key] = TextEditingController(text: jsonEncode(val));
            } else if (val != null &&
                DateTime.tryParse(val.toString()) != null &&
                val.toString().contains('-') &&
                val.toString().length >= 10) {
              types[key] = RecordFieldType.dateTime;
              controllers[key] = TextEditingController(text: val.toString());
            } else {
              types[key] = RecordFieldType.string;
              controllers[key] = TextEditingController(text: val.toString());
            }
          }
        }

        for (var key in formData.keys) {
          initField(key, formData[key]);
        }

        final jsonController = TextEditingController(
          text: const JsonEncoder.withIndent(' ').convert(formData),
        );

        final newKeyController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void syncToJson() {
              for (var key in controllers.keys) {
                final type = types[key]!;
                final text = controllers[key]!.text.trim();

                if (text.isEmpty && type != RecordFieldType.boolean) {
                  formData[key] = null;
                } else if (type == RecordFieldType.boolean) {
                  if (text == 'null') {
                    formData[key] = null;
                  } else {
                    formData[key] = (text == 'true');
                  }
                } else if (type == RecordFieldType.integer) {
                  formData[key] =
                      int.tryParse(text) ?? num.tryParse(text)?.toInt();
                } else if (type == RecordFieldType.double) {
                  formData[key] = double.tryParse(text);
                } else if (type == RecordFieldType.dateTime) {
                  formData[key] = text;
                } else if (type == RecordFieldType.array ||
                    type == RecordFieldType.object) {
                  try {
                    formData[key] = jsonDecode(text);
                  } catch (_) {
                    formData[key] = text;
                  }
                } else {
                  formData[key] = text;
                }
              }
              jsonController.text = const JsonEncoder.withIndent(
                ' ',
              ).convert(formData);
            }

            void syncToForm() {
              try {
                final decoded = jsonDecode(jsonController.text);
                if (decoded is! Map<String, dynamic>)
                  throw const FormatException();

                formData.clear();
                formData.addAll(decoded);
                controllers.clear();
                types.clear();
                for (var key in formData.keys) {
                  initField(key, formData[key]);
                }
                errorMessage = null;
              } catch (e) {
                errorMessage = 'Geçersiz JSON formatı';
              }
            }

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.list),
                        label: Text('Form'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.data_object),
                        label: Text('JSON'),
                      ),
                    ],
                    selected: {isJsonMode},
                    onSelectionChanged: (val) {
                      setDialogState(() {
                        if (isJsonMode) {
                          syncToForm();
                          if (errorMessage != null) return;
                        } else {
                          syncToJson();
                        }
                        isJsonMode = val.first;
                      });
                    },
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                  maxHeight: 550,
                ),
                child: isJsonMode
                    ? TextField(
                        controller: jsonController,
                        minLines: 15,
                        maxLines: 20,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'JSON',
                          alignLabelWithHint: true,
                          errorText: errorMessage,
                          border: const OutlineInputBorder(),
                        ),
                      )
                    : SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: controllers.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: Text(
                                          'Gösterilecek alan yok (Koleksiyon boş)',
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      shrinkWrap: true,
                                      children: controllers.entries.map((e) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  e.key,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueGrey
                                                      .withOpacity(0.1),
                                                  borderRadius: BorderRadius
                                                      .circular(6),
                                                ),
                                                child: Text(
                                                  types[e.key].toString().split('.').last.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blueGrey,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 3,
                                                child:
                                                    types[e.key] == RecordFieldType.boolean
                                                        ? DropdownButtonFormField<String>(
                                                            value: (e.value.text == 'true' || e.value.text == 'false') ? e.value.text : 'null',
                                                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                                            items: const [
                                                              DropdownMenuItem(value: 'true', child: Text('True')),
                                                              DropdownMenuItem(value: 'false', child: Text('False')),
                                                              DropdownMenuItem(value: 'null', child: Text('Boş')),
                                                            ],
                                                            onChanged: (val) {
                                                              if (val != null) e.value.text = val;
                                                            },
                                                          )
                                                        : TextField(
                                                            controller: e.value,
                                                            enabled: types[e.key] != RecordFieldType.nullValue,
                                                            keyboardType: types[e.key] == RecordFieldType.integer || types[e.key] == RecordFieldType.double
                                                                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                                                : TextInputType.text,
                                                            inputFormatters: types[e.key] == RecordFieldType.integer
                                                                ? [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))]
                                                                : (types[e.key] == RecordFieldType.double
                                                                    ? [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))]
                                                                    : []),
                                                            decoration: const InputDecoration(
                                                              isDense: true,
                                                              border: OutlineInputBorder(),
                                                            ),
                                                          ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ), // end of Column
                      ), // end of SizedBox
              ), // end of ConstrainedBox
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isJsonMode) {
                      syncToForm();
                      if (errorMessage != null) {
                        setDialogState(() {});
                        return;
                      }
                    } else {
                      syncToJson();
                    }
                    Navigator.of(dialogContext).pop(formData);
                  },
                  child: Text(saveButtonText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(DataRecord record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kayıt silinsin mi?'),
          content: Text('${record.id} numaralı kayıt silinecek.'),
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
      await ref.read(dataExplorerProvider.notifier).deleteRecord(record.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kayıt silindi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _showRecordDetails(
    DataRecord record, {
    bool readOnly = false,
  }) async {
    final jsonText = const JsonEncoder.withIndent('  ').convert({
      '_id': record.id,
      ...record.data,
      '_createdAt': record.createdAt.toIso8601String(),
      '_updatedAt': record.updatedAt.toIso8601String(),
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(record.id, overflow: TextOverflow.ellipsis)),
              if (readOnly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Sadece Okunabilir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // ── Export: Format seçimi PopupMenu'den gelir ─────────────────────────────
  Future<void> _exportWithFormat(String format) async {
    final records = _filteredRecords;
    if (records.isEmpty) return;

    final collectionName = _selectedCollection ?? 'export';
    final ext = format.toLowerCase(); // 'json' veya 'csv'
    final defaultFileName = '${collectionName}.$ext';

    String? initialDir;
    try {
      final downloads = await getDownloadsDirectory();
      initialDir = downloads?.path;
    } catch (_) {
      // Desteklenmeyen platformda görmezden gel
    }

    final savePath = await FilePicker.saveFile(
      dialogTitle: '$format formatında dışa aktar',
      fileName: defaultFileName,
      initialDirectory: initialDir,
      type: FileType.custom,
      allowedExtensions: [ext],
    );

    if (savePath == null) return; // kullanıcı iptal etti
    if (!mounted) return;

    try {
      final content = format == 'JSON'
          ? _buildJsonExport(records)
          : _buildCsvExport(records);

      await File(savePath).writeAsString(content, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${records.length} kayıt $format olarak kaydedildi: $savePath',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: 'Tamam', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Dosya yazılamadı: $e');
    }
  }

  String _buildJsonExport(List<DataRecord> records) {
    final docs = records
        .map(
          (r) => {
            '_id': r.id,
            ...r.data,
            '_createdAt': r.createdAt.toIso8601String(),
            '_updatedAt': r.updatedAt.toIso8601String(),
          },
        )
        .toList();
    return const JsonEncoder.withIndent('  ').convert(docs);
  }

  String _buildCsvExport(List<DataRecord> records) {
    // Tüm sütunları topla
    final columns = <String>{};
    for (final r in records) {
      columns.addAll(r.data.keys);
    }
    final cols = columns.toList();

    final buffer = StringBuffer();
    // Header satırı
    buffer.writeln(
      (['_id', ...cols, '_createdAt', '_updatedAt']).map(_csvEscape).join(','),
    );
    // Veri satırları
    for (final r in records) {
      final row = [
        r.id,
        ...cols.map((c) => _displayValue(r.data[c])),
        r.createdAt.toIso8601String(),
        r.updatedAt.toIso8601String(),
      ].map(_csvEscape).join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Widget _buildAccessDenied() {
    return const Center(
      child: _MessagePanel(
        icon: Icons.lock_outline,
        title: 'Erişim yetkiniz bulunmuyor',
        description:
            'Verileri görüntülemek için Veri görüntüleme yetkisine sahip olmalısınız.',
      ),
    );
  }

  Widget _buildNoSelection() {
    return const _MessagePanel(
      icon: Icons.touch_app_outlined,
      title: 'Database ve collection seçin',
      description: 'Verileri görüntülemek için üst bölümden seçim yapın.',
    );
  }

  Widget _buildEmptyState() {
    return const _MessagePanel(
      icon: Icons.inbox_outlined,
      title: 'Kayıt bulunamadı',
      description:
          'Bu collection içerisinde arama kriterlerine uygun kayıt bulunmuyor.',
    );
  }

  List<String> _findColumns(List<DataRecord> records) {
    final columns = <String>{};

    for (final record in records) {
      columns.addAll(record.data.keys);
    }

    return columns.toList();
  }

  String _displayValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is Map || value is List) {
      return jsonEncode(value);
    }

    return value.toString();
  }

  void _showErrorMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  /// PowerShell ile native dosya seçici açar (mouse_tracker bug'ı önlenir).
  Future<({String name, Uint8List bytes})?> _pickJsonFileNative() async {
    try {
      final result = await Process.run('powershell', [
        '-command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.OpenFileDialog
$d.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
$d.Title = 'JSON dosyasi sec'
if ($d.ShowDialog() -eq 'OK') { Write-Output $d.FileName }
''',
      ]);
      final path = result.stdout.toString().trim();
      if (path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final name = path.split(RegExp(r'[\\/]')).last;
      return (name: name, bytes: Uint8List.fromList(bytes));
    } catch (e) {
      return null;
    }
  }

  Future<void> _showAddCollectionDialog() async {
    final collectionNameController = TextEditingController();
    final currentDb = _selectedDatabase;
    if (currentDb == null) return;

    String? selectedFileName;
    List<Map<String, dynamic>>? parsedDocuments;
    String? fileError;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            Future<void> handlePickFile() async {
              setDlgState(() => fileError = null);
              final picked = await _pickJsonFileNative();
              if (picked == null) return;

              try {
                final jsonText = _decodeJsonBytes(picked.bytes);
                final docs = _parseImportedDocuments(jsonText);
                setDlgState(() {
                  selectedFileName = picked.name;
                  parsedDocuments = docs;
                  fileError = null;
                });
              } on FormatException catch (e) {
                setDlgState(() {
                  fileError = e.message;
                  selectedFileName = null;
                  parsedDocuments = null;
                });
              } catch (e) {
                setDlgState(() {
                  fileError = 'JSON okuma hatası: $e';
                  selectedFileName = null;
                  parsedDocuments = null;
                });
              }
            }

            return AlertDialog(
              title: Text('${currentDb.name} – Yeni Collection Ekle'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: collectionNameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Collection Adı',
                        hintText: 'örn. ogrenciler',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'JSON Dosyası İçe Aktarma (İsteğe Bağlı)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedFileName == null)
                      OutlinedButton.icon(
                        onPressed: handlePickFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('PC\'den JSON Dosyası Seç'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$selectedFileName (${parsedDocuments?.length ?? 0} kayıt)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Dosyayı kaldır',
                              onPressed: () {
                                setDlgState(() {
                                  selectedFileName = null;
                                  parsedDocuments = null;
                                  fileError = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    if (fileError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        fileError!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(
                    parsedDocuments != null
                        ? 'Oluştur ve ${parsedDocuments!.length} Kaydı Aktar'
                        : 'Oluştur',
                  ),
                  onPressed: () {
                    if (collectionNameController.text.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      final name = collectionNameController.text.trim();
      final currentDbId = _selectedDatabaseId;

      if (name.isNotEmpty && currentDbId != null) {
        setState(() {
          _extraCollections
              .putIfAbsent(currentDbId, () => <String>{})
              .add(name);
          _selectedCollection = name;
          _lastSelectedCollection = name;
        });

        ref.read(selectedCollectionProvider.notifier).state = name;

        try {
          final creds = ref.read(credentialsProvider);
          if (creds != null) {
            final tcpRepo = ref.read(socketServiceProvider);
            tcpRepo
                .send(
                  action: 'CREATE_COLLECTION',
                  username: creds.username,
                  password: creds.password,
                  database: currentDb.name,
                  collection: name,
                )
                .catchError((_) => <String, dynamic>{});
          }
          ref.invalidate(dataExplorerProvider);
        } catch (_) {}

        // Eğer JSON dosyası seçilmişse kayıtları bu koleksiyona aktar
        if (parsedDocuments != null && parsedDocuments!.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "'$name' oluşturuldu. ${parsedDocuments!.length} kayıt aktarılıyor...",
                ),
              ),
            );
          }
          await _importDocuments(parsedDocuments!);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'$name' koleksiyonu oluşturuldu."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteCollectionDialog() async {
    final currentDb = _selectedDatabase;
    final currentCol = _selectedCollection;
    if (currentDb == null || currentCol == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Collection Silinsin mi?'),
          content: Text(
            "'$currentCol' koleksiyonu ve içindeki tüm kayıtlar silinecek. Emin misiniz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final creds = ref.read(credentialsProvider);
        if (creds != null) {
          final tcpRepo = ref.read(socketServiceProvider);
          await tcpRepo
              .send(
                action: 'DROP_COLLECTION',
                username: creds.username,
                password: creds.password,
                database: currentDb.name,
                collection: currentCol,
              )
              .catchError((_) => <String, dynamic>{});
          await tcpRepo
              .send(
                action: 'DROP_COLLECTION',
                username: creds.username,
                password: creds.password,
                database: currentDb.name,
                collection: currentCol,
              )
              .catchError((_) => <String, dynamic>{});
        }
      } catch (_) {}

      setState(() {
        _serverCollections[currentDb.id]?.remove(currentCol);
        _extraCollections[currentDb.id]?.remove(currentCol);
        _selectedCollection = null;
        _lastSelectedCollection = null;
      });
      ref.read(selectedCollectionProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'$currentCol' koleksiyonu silindi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ExplorerDatabase {
  final String id;
  final String name;
  final String department;
  final List<String> collections;

  const _ExplorerDatabase({
    required this.id,
    required this.name,
    required this.department,
    required this.collections,
  });
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportInformationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ImportInformationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
