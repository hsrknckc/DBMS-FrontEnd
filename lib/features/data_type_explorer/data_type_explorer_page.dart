import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/data_record.dart';
import '../../models/permission.dart';

class DataTypeExplorerPage extends StatefulWidget {
  final AppUser currentUser;

  const DataTypeExplorerPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<DataTypeExplorerPage> createState() => _DataTypeExplorerPageState();
}

class _DataTypeExplorerPageState extends State<DataTypeExplorerPage> {
  static String? _lastSelectedDatabaseId;
  static String? _lastSelectedCollection;

  String? _selectedDatabaseId;
  String? _selectedCollection;

  final Map<String, String> _customTypes = {};

  final List<_ExplorerDatabase> _databases = [
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
  ];

  List<_ExplorerDatabase> get _visibleDatabases {
    if (widget.currentUser.isSuperAdmin) {
      return _databases;
    }
    return _databases.map((database) {
      if (!widget.currentUser.canAccessDepartment(database.department)) {
        return null;
      }
      final allowedCols = database.collections.where((col) {
        return widget.currentUser.canAccessCollection(database.department, col);
      }).toList();
      if (allowedCols.isEmpty) return null;
      return _ExplorerDatabase(
        id: database.id,
        name: database.name,
        department: database.department,
        collections: allowedCols,
      );
    }).whereType<_ExplorerDatabase>().toList();
  }

  _ExplorerDatabase? get _selectedDatabase {
    final selectedId = _selectedDatabaseId;
    if (selectedId == null) return null;
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

    return _records.where((record) {
      return record.databaseId == databaseId &&
          record.collectionName == collectionName;
    }).toList();
  }

  bool get _canCreate {
    return widget.currentUser.isSuperAdmin ||
        widget.currentUser.hasPermission(Permission.dataCreate);
  }

  bool get _hasSelection {
    return _selectedDatabaseId != null && _selectedCollection != null;
  }

  @override
  void initState() {
    super.initState();

    final databases = _visibleDatabases;

    if (databases.isNotEmpty) {
      if (_lastSelectedDatabaseId != null &&
          databases.any((db) => db.id == _lastSelectedDatabaseId)) {
        _selectedDatabaseId = _lastSelectedDatabaseId;
        final selectedDb =
            databases.firstWhere((db) => db.id == _lastSelectedDatabaseId);
        if (_lastSelectedCollection != null &&
            selectedDb.collections.contains(_lastSelectedCollection)) {
          _selectedCollection = _lastSelectedCollection;
        } else if (selectedDb.collections.isNotEmpty) {
          _selectedCollection = selectedDb.collections.first;
        }
      } else {
        _selectedDatabaseId = databases.first.id;
        if (databases.first.collections.isNotEmpty) {
          _selectedCollection = databases.first.collections.first;
        }
      }
      _lastSelectedDatabaseId = _selectedDatabaseId;
      _lastSelectedCollection = _selectedCollection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(theme, isDark),
        Expanded(
          child: _hasSelection
              ? _buildTableView(theme, isDark)
              : _buildEmptySelectionState(theme),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Type Explorer',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color ??
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verilerin türlerini (String, Number, vb.) inceleyin ve yönetin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasSelection)
                Opacity(
                  opacity: _canCreate ? 1.0 : 0.5,
                  child: Tooltip(
                    message: _canCreate
                        ? 'Yeni Feature Ekle'
                        : 'Sütun eklemek için yazma yetkiniz bulunmamaktadır.',
                    child: ElevatedButton.icon(
                      onPressed: _canCreate ? _showAddFeatureDialog : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_box_outlined, size: 20),
                      label: const Text(
                        '+ Yeni Feature Ekle',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  theme: theme,
                  label: 'Database',
                  value: _selectedDatabaseId,
                  items: _visibleDatabases.map((db) {
                    return DropdownMenuItem(
                      value: db.id,
                      child: Text(db.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final db = _visibleDatabases.firstWhere((item) => item.id == val);
                    setState(() {
                      _selectedDatabaseId = val;
                      _selectedCollection =
                          db.collections.isEmpty ? null : db.collections.first;
                      _lastSelectedDatabaseId = _selectedDatabaseId;
                      _lastSelectedCollection = _selectedCollection;
                    });
                  },
                  icon: Icons.storage_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        theme: theme,
                        label: 'Collection',
                        value: _selectedCollection,
                        items: _selectedDatabase != null
                            ? _selectedDatabase!.collections.map((col) {
                                return DropdownMenuItem(
                                  value: col,
                                  child: Text(col),
                                );
                              }).toList()
                            : [],
                        onChanged: (val) {
                          setState(() {
                            _selectedCollection = val;
                            _lastSelectedCollection = val;
                          });
                        },
                        icon: Icons.folder_open_outlined,
                        isDark: isDark,
                        isEnabled: _selectedDatabase != null,
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
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required ThemeData theme,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required bool isDark,
    bool isEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50])
            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[100]),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(
                'Select $label',
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
          items: items,
          onChanged: isEnabled ? onChanged : null,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  Widget _buildTableView(ThemeData theme, bool isDark) {
    final records = _filteredRecords;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'Kayıt bulunamadı',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    final Set<String> columns = {};
    for (final record in records) {
      columns.addAll(record.data.keys);
    }

    final columnsList = columns.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[50],
                ),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                dividerThickness: 1,
                columns: [
                  const DataColumn(label: Text('ID')),
                  ...columnsList.map((col) => DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(col),
                            if (_canCreate && _isColumnCompletelyNull(col))
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 16),
                                padding: EdgeInsets.zero,
                                splashRadius: 16,
                                tooltip: 'Feature Seçenekleri',
                                onSelected: (val) {
                                  if (val == 'rename') {
                                    _showRenameFeatureDialog(col);
                                  } else if (val == 'delete') {
                                    _showDeleteFeatureDialog(col);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Yeniden Adlandır', style: TextStyle(fontSize: 13)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Sil', style: TextStyle(fontSize: 13, color: Colors.red)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )),
                ],
                rows: records.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          record.id,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      ...columnsList.map((col) {
                        final val = record.data[col];
                        return DataCell(_buildTypeBadge(val, col));
                      }),
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

  Widget _buildTypeBadge(dynamic value, String col) {
    String label;
    Color color;

    if (value == null) {
      if (_customTypes.containsKey(col)) {
        label = _customTypes[col]!;
        color = _getColorForLabel(label);
      } else {
        label = 'Null';
        color = Colors.grey;
      }
    } else if (value is String) {
      label = 'String';
      color = Colors.blue;
    } else if (value is num) {
      label = 'Number';
      color = Colors.green;
    } else if (value is bool) {
      label = 'Boolean';
      color = Colors.orange;
    } else if (value is List) {
      label = 'List';
      color = Colors.purple;
    } else if (value is Map) {
      label = 'Map';
      color = Colors.indigo;
    } else {
      label = 'Unknown';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getColorForLabel(String label) {
    switch (label) {
      case 'String': return Colors.blue;
      case 'Number': return Colors.green;
      case 'Boolean': return Colors.orange;
      case 'DateTime': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptySelectionState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined,
              size: 80, color: theme.hintColor.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            'Lütfen bir database ve collection seçin',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFeatureDialog() async {
    final nameController = TextEditingController();
    String selectedType = 'String';

    final String? resultType = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Feature Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Feature / Sütun Adı',
                      hintText: 'örn. battery_level',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Veri Tipi',
                    ),
                    items: ['String', 'Number', 'Boolean', 'DateTime']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context, selectedType);
                  },
                  child: const Text('Devam Et'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultType != null) {
      final String featureName = nameController.text.trim();
      final bool? confirm = await _showConfirmationDialog(featureName);

      if (confirm == true) {
        setState(() {
          _customTypes[featureName] = resultType;
          for (var record in _records) {
            if (record.databaseId == _selectedDatabaseId &&
                record.collectionName == _selectedCollection) {
              record.data[featureName] = null;
            }
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni sütun başarıyla eklendi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog(String featureName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Emin misiniz?'),
            ],
          ),
          content: Text(
              "Yeni bir sütun eklemek üzeresiniz. Bu işlem mevcut kayıtlara veri doldurmayacaktır. Tüm mevcut belgeler için '$featureName' sütunu varsayılan olarak 'null' değeri ile otomatik doldurulacaktır.\n\nDevam etmek istiyor musunuz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Evet, Onaylıyorum'),
            ),
          ],
        );
      },
    );
  }

  bool _isColumnCompletelyNull(String columnName) {
    for (var record in _filteredRecords) {
      if (record.data.containsKey(columnName) && record.data[columnName] != null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showRenameFeatureDialog(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Feature Yeniden Adlandır'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Yeni İsim'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty || controller.text.trim() == oldName) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final newName = controller.text.trim();
      setState(() {
        if (_customTypes.containsKey(oldName)) {
          _customTypes[newName] = _customTypes.remove(oldName)!;
        }
        for (var record in _records) {
          if (record.databaseId == _selectedDatabaseId &&
              record.collectionName == _selectedCollection &&
              record.data.containsKey(oldName)) {
            final value = record.data.remove(oldName);
            record.data[newName] = value;
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$oldName', '$newName' olarak değiştirildi."), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showDeleteFeatureDialog(String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Feature Sil'),
          content: Text("'$name' isimli feature'ı silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _customTypes.remove(name);
        for (var record in _records) {
          if (record.databaseId == _selectedDatabaseId &&
              record.collectionName == _selectedCollection) {
            record.data.remove(name);
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$name' silindi."), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddCollectionDialog() async {
    final controller = TextEditingController();
    final dbName = _selectedDatabase!.name;
    final prefix = '${dbName}_';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Collection Ekle'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Collection Adı (Prefix Otomatik)', 
              hintText: 'örn. test_koleksiyon',
              prefixText: prefix,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final name = '$prefix${controller.text.trim()}';
      setState(() {
        _selectedDatabase!.collections.add(name);
        _selectedCollection = name;
        _lastSelectedCollection = name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$name' koleksiyonu oluşturuldu."), backgroundColor: Colors.green),
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