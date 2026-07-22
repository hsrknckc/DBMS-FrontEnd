import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/data_record.dart';
import '../../models/permission.dart';

class DataExplorerPage extends StatefulWidget {
  final AppUser currentUser;

  const DataExplorerPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<DataExplorerPage> createState() =>
      _DataExplorerPageState();
}

class _DataExplorerPageState
    extends State<DataExplorerPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String? _selectedDatabaseId;
  String? _selectedCollection;

  bool _showJsonView = false;
  bool _isImporting = false;

  final List<_ExplorerDatabase> _databases = const [
    _ExplorerDatabase(
      id: 'db-1',
      name: 'sensor_database',
      department: 'Sensor',
      collections: [
        'sensor_readings',
        'sensor_status',
        'device_logs',
      ],
    ),
    _ExplorerDatabase(
      id: 'db-2',
      name: 'signal_database',
      department: 'Signal',
      collections: [
        'signal_records',
        'signal_analysis',
      ],
    ),
    _ExplorerDatabase(
      id: 'db-3',
      name: 'acoustic_database',
      department: 'Acoustic',
      collections: [
        'acoustic_samples',
        'analysis_results',
      ],
    ),
    _ExplorerDatabase(
      id: 'db-4',
      name: 'sonar_archive',
      department: 'Sonar',
      collections: [
        'sonar_contacts',
        'archived_scans',
      ],
    ),
  ];

  final List<DataRecord> _records = [
    DataRecord(
      id: 'record-1',
      databaseId: 'db-1',
      collectionName: 'sensor_readings',
      data: {
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
      data: {
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
      data: {
        'sensorId': 'SEN-003',
        'type': 'Humidity',
        'value': 67,
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
      collectionName: 'sensor_status',
      data: {
        'sensorId': 'SEN-001',
        'online': true,
        'battery': 84,
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
      data: {
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
      data: {
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

  List<_ExplorerDatabase> get _visibleDatabases {
    if (widget.currentUser.isSuperAdmin) {
      return _databases;
    }

    return _databases.where((database) {
      return widget.currentUser.canAccessDepartment(
        database.department,
      );
    }).toList();
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

    final query =
        _searchController.text.trim().toLowerCase();

    return _records.where((record) {
      final belongsToSelection =
          record.databaseId == databaseId &&
          record.collectionName == collectionName;

      if (!belongsToSelection) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchableText = [
        record.id,
        ...record.data.entries.map(
          (entry) => '${entry.key} ${entry.value}',
        ),
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  bool get _canView {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(
          Permission.dataView,
        );
  }

  bool get _canCreate {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(
          Permission.dataCreate,
        );
  }

  bool get _canUpdate {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(
          Permission.dataUpdate,
        );
  }

  bool get _canDelete {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(
          Permission.dataDelete,
        );
  }

  bool get _canImport {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(
          Permission.dataImport,
        );
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
    return _selectedDatabaseId != null &&
        _selectedCollection != null;
  }

  @override
  void initState() {
    super.initState();

    final databases = _visibleDatabases;

    if (databases.isNotEmpty) {
      _selectedDatabaseId = databases.first.id;

      if (databases.first.collections.isNotEmpty) {
        _selectedCollection =
            databases.first.collections.first;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return _buildAccessDenied();
    }

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
              style:
                  Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Database collection kayıtlarını görüntüleyin, içe aktarın ve yönetin.',
              style:
                  Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );

        // ── Yazma yetkisi kontrolü ──────────────────────────────────────────
        // SuperAdmin her zaman tam yetkili.
        // Normal kullanıcı için _canImport / _canCreate yoksa butonlar
        // görünür ama disabled + %50 opaklık + Tooltip ile uyarı verir.
        const _noWriteTooltip =
            'Bu işlem için yazma yetkiniz bulunmamaktadır.\nYöneticinizle iletişime geçin.';

        Widget importBtn = Opacity(
          opacity: _canImport ? 1.0 : 0.5,
          child: Tooltip(
            message: _canImport ? '' : _noWriteTooltip,
            child: OutlinedButton.icon(
              onPressed: _canImport && _hasSelection && !_isImporting
                  ? _pickAndImportJson
                  : null,
              icon: _isImporting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_isImporting ? 'Dosya okunuyor' : 'JSON İçe Aktar'),
            ),
          ),
        );

        Widget createBtn = Opacity(
          opacity: _canCreate ? 1.0 : 0.5,
          child: Tooltip(
            message: _canCreate ? '' : _noWriteTooltip,
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
          children: [importBtn, createBtn],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              actions,
            ],
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
            crossAxisAlignment:
                WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isNarrow
                    ? constraints.maxWidth
                    : 300,
                child:
                    DropdownButtonFormField<String>(
                  value: _selectedDatabaseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Database',
                    prefixIcon:
                        Icon(Icons.storage_outlined),
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

                    final database =
                        _visibleDatabases.firstWhere(
                      (item) => item.id == value,
                    );

                    setState(() {
                      _selectedDatabaseId = value;
                      _selectedCollection =
                          database.collections.isEmpty
                              ? null
                              : database
                                  .collections.first;
                      _searchController.clear();
                    });
                  },
                ),
              ),
              SizedBox(
                width: isNarrow
                    ? constraints.maxWidth
                    : 280,
                child:
                    DropdownButtonFormField<String>(
                  value: _selectedCollection,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Collection',
                    prefixIcon:
                        Icon(Icons.folder_outlined),
                  ),
                  items: (_selectedDatabase
                              ?.collections ??
                          [])
                      .map((collection) {
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
                    });
                  },
                ),
              ),
              if (_selectedDatabase != null)
                _InfoBadge(
                  icon: Icons.apartment_outlined,
                  text:
                      _selectedDatabase!.department,
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
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          final searchField = SizedBox(
            width: isNarrow
                ? constraints.maxWidth
                : 320,
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
            crossAxisAlignment:
                WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon:
                        Icon(Icons.table_rows_outlined),
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
                child: OutlinedButton.icon(
                  // onPressed null yaparak tıklamayı PopupMenuButton'a bırakıyoruz
                  onPressed: recordCount == 0 ? null : () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Dışa Aktar'),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 12),
                controls,
              ],
            );
          }

          return Row(
            children: [
              searchField,
              const Spacer(),
              controls,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableView(
    List<DataRecord> records,
  ) {
    final columns = _findColumns(records);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor:
                    const WidgetStatePropertyAll(
                  AppColors.background,
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...columns.map((column) {
                    return DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                  const DataColumn(
                    label: Text(
                      'İşlemler',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
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
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...columns.map((column) {
                        return DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              _displayValue(
                                record.data[column],
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
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
                              icon: const Icon(
                                Icons.visibility_outlined,
                              ),
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
    );
  }

  Widget _buildJsonView(
    List<DataRecord> records,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
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
          ).convert({
            '_id': record.id,
            ...record.data,
          });

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
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
      final result =
          await FilePicker.pickFiles(
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
        _showErrorMessage(
          'Dosya içeriği okunamadı.',
        );
        return;
      }

      final jsonText = _decodeJsonBytes(bytes);

      final importedDocuments =
          _parseImportedDocuments(jsonText);

      if (importedDocuments.isEmpty) {
        _showErrorMessage(
          'Dosyada içe aktarılabilecek kayıt bulunamadı.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final shouldImport =
          await _showImportPreviewDialog(
        fileName: selectedFile.name,
        documents: importedDocuments,
      );

      if (shouldImport != true || !mounted) {
        return;
      }

      _importDocuments(importedDocuments);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${importedDocuments.length} kayıt içe aktarıldı.',
          ),
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
      throw const FormatException(
        'Dosya UTF-8 formatında okunamadı.',
      );
    }
  }

  List<Map<String, dynamic>>
      _parseImportedDocuments(String jsonText) {
    final trimmedText = jsonText.trim();

    if (trimmedText.isEmpty) {
      throw const FormatException(
        'Seçilen JSON dosyası boş.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(trimmedText);
    } on FormatException {
      return _parseJsonLines(trimmedText);
    }

    if (decoded is Map) {
      return [
        Map<String, dynamic>.from(decoded),
      ];
    }

    if (decoded is List) {
      final documents = <Map<String, dynamic>>[];

      for (var index = 0;
          index < decoded.length;
          index++) {
        final item = decoded[index];

        if (item is! Map) {
          throw FormatException(
            '${index + 1}. kayıt bir JSON nesnesi değil.',
          );
        }

        documents.add(
          Map<String, dynamic>.from(item),
        );
      }

      return documents;
    }

    throw const FormatException(
      'Dosyanın kökünde bir JSON nesnesi veya JSON dizisi bulunmalıdır.',
    );
  }

  List<Map<String, dynamic>> _parseJsonLines(
    String jsonText,
  ) {
    final lines = const LineSplitter()
        .convert(jsonText)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException(
        'JSON dosyasında kayıt bulunamadı.',
      );
    }

    final documents = <Map<String, dynamic>>[];

    for (var index = 0;
        index < lines.length;
        index++) {
      dynamic decodedLine;

      try {
        decodedLine = jsonDecode(lines[index]);
      } on FormatException {
        throw FormatException(
          '${index + 1}. satır geçerli JSON değil.',
        );
      }

      if (decodedLine is! Map) {
        throw FormatException(
          '${index + 1}. satır bir JSON nesnesi değil.',
        );
      }

      documents.add(
        Map<String, dynamic>.from(decodedLine),
      );
    }

    return documents;
  }

  Future<bool?> _showImportPreviewDialog({
    required String fileName,
    required List<Map<String, dynamic>> documents,
  }) {
    final previewDocuments =
        documents.take(3).toList();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'JSON içe aktarma önizlemesi',
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
              maxHeight: 620,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _ImportInformationRow(
                  label: 'Dosya',
                  value: fileName,
                ),
                _ImportInformationRow(
                  label: 'Database',
                  value:
                      _selectedDatabase?.name ?? '-',
                ),
                _ImportInformationRow(
                  label: 'Collection',
                  value:
                      _selectedCollection ?? '-',
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
                    itemCount:
                        previewDocuments.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final jsonText =
                          const JsonEncoder.withIndent(
                        '  ',
                      ).convert(
                        previewDocuments[index],
                      );

                      return Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                          ),
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
              icon:
                  const Icon(Icons.upload_outlined),
              label: Text(
                '${documents.length} Kaydı Aktar',
              ),
            ),
          ],
        );
      },
    );
  }

  void _importDocuments(
    List<Map<String, dynamic>> documents,
  ) {
    final databaseId = _selectedDatabaseId;
    final collectionName = _selectedCollection;

    if (databaseId == null ||
        collectionName == null) {
      return;
    }

    final now = DateTime.now();
    final importedRecords = <DataRecord>[];

    for (var index = 0;
        index < documents.length;
        index++) {
      final originalDocument =
          Map<String, dynamic>.from(
        documents[index],
      );

      final extractedId =
          _extractMongoDocumentId(
        originalDocument['_id'],
      );

      originalDocument.remove('_id');

      importedRecords.add(
        DataRecord(
          id: extractedId ??
              'import-${now.millisecondsSinceEpoch}-$index',
          databaseId: databaseId,
          collectionName: collectionName,
          data: originalDocument,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    setState(() {
      _records.addAll(importedRecords);
    });
  }

  String? _extractMongoDocumentId(dynamic idValue) {
    if (idValue == null) {
      return null;
    }

    if (idValue is String ||
        idValue is num) {
      return idValue.toString();
    }

    if (idValue is Map) {
      final objectId =
          idValue[r'$oid'];

      if (objectId != null) {
        return objectId.toString();
      }

      return jsonEncode(idValue);
    }

    return idValue.toString();
  }

  Future<void> _showCreateRecordDialog() async {
    final jsonController = TextEditingController(
      text: const JsonEncoder.withIndent(' ').convert({
        'fieldName': 'value',
      }),
    );

    final result =
        await _showJsonEditorDialog(
      title: 'Yeni Kayıt',
      controller: jsonController,
      saveButtonText: 'Kaydet',
    );

    jsonController.dispose();

    if (result == null || !_hasSelection) {
      return;
    }

    final now = DateTime.now();

    setState(() {
      _records.add(
        DataRecord(
          id: 'record-${now.millisecondsSinceEpoch}',
          databaseId: _selectedDatabaseId!,
          collectionName: _selectedCollection!,
          data: result,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Yeni kayıt oluşturuldu.',
        ),
      ),
    );
  }

  Future<void> _showEditRecordDialog(
    DataRecord record,
  ) async {
    final jsonController = TextEditingController(
      text: const JsonEncoder.withIndent(' ')
          .convert(record.data),
    );

    final result =
        await _showJsonEditorDialog(
      title: 'Kaydı Düzenle',
      controller: jsonController,
      saveButtonText: 'Değişiklikleri Kaydet',
    );

    jsonController.dispose();

    if (result == null) {
      return;
    }

    final index = _records.indexWhere(
      (item) => item.id == record.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _records[index] = record.copyWith(
        data: result,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<Map<String, dynamic>?>
      _showJsonEditorDialog({
    required String title,
    required TextEditingController controller,
    required String saveButtonText,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                ),
                child: TextField(
                  controller: controller,
                  minLines: 10,
                  maxLines: 17,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'JSON',
                    alignLabelWithHint: true,
                    errorText: errorMessage,
                  ),
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
                    try {
                      final decoded =
                          jsonDecode(controller.text);

                      if (decoded is! Map) {
                        throw const FormatException();
                      }

                      Navigator.of(dialogContext).pop(
                        Map<String, dynamic>.from(
                          decoded,
                        ),
                      );
                    } catch (_) {
                      setDialogState(() {
                        errorMessage =
                            'Geçerli bir JSON nesnesi girin.';
                      });
                    }
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

  Future<void> _showDeleteDialog(
    DataRecord record,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kayıt silinsin mi?'),
          content: Text(
            '${record.id} numaralı kayıt silinecek.',
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

    setState(() {
      _records.removeWhere(
        (item) => item.id == record.id,
      );
    });
  }

  Future<void> _showRecordDetails(
    DataRecord record, {
    bool readOnly = false,
  }) async {
    final jsonText =
        const JsonEncoder.withIndent('  ').convert({
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 13, color: AppColors.warning),
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
            constraints: const BoxConstraints(
              maxWidth: 650,
              maxHeight: 600,
            ),
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

    // Downloads klasörünü bul (path_provider)
    String? initialDir;
    try {
      final downloads = await getDownloadsDirectory();
      initialDir = downloads?.path;
    } catch (_) {
      // Desteklenmeyen platformda görmezden gel
    }

    // Masaüstü kaydetme penceresi — file_picker ^11 static API
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
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Dosya yazılamadı: $e');
    }
  }

  String _buildJsonExport(List<DataRecord> records) {
    final docs = records.map((r) => {
          '_id': r.id,
          ...r.data,
          '_createdAt': r.createdAt.toIso8601String(),
          '_updatedAt': r.updatedAt.toIso8601String(),
        }).toList();
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
    buffer.writeln((['_id', ...cols, '_createdAt', '_updatedAt'])
        .map(_csvEscape)
        .join(','));
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
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n')) {
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
      description:
          'Verileri görüntülemek için üst bölümden seçim yapın.',
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

  List<String> _findColumns(
    List<DataRecord> records,
  ) {
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
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

  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.primary,
          ),
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

class _ImportInformationRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ImportInformationRow({
    required this.label,
    required this.value,
  });

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
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: AppColors.textSecondary,
            ),
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
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}