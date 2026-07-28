import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/database_item.dart';
import '../../models/data_record.dart';
import '../../models/permission.dart';
import '../databases/controllers/databases_notifier.dart';

class DataTypeExplorerPage extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const DataTypeExplorerPage({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<DataTypeExplorerPage> createState() => _DataTypeExplorerPageState();
}

class _DataTypeExplorerPageState extends ConsumerState<DataTypeExplorerPage> {
  static String? _lastSelectedDatabaseId;
  static String? _lastSelectedCollection;

  String? _selectedDatabaseId;
  String? _selectedCollection;

  final Map<String, String> _customTypes = {};
  final Map<String, List<String>> _extraCollections = {};

  @override
  void initState() {
    super.initState();
    _selectedDatabaseId = _lastSelectedDatabaseId;
    _selectedCollection = _lastSelectedCollection;
  }

  bool get _canView =>
      widget.currentUser.isSuperAdmin ||
      widget.currentUser.hasPermission(Permission.dataView);

  bool get _canCreateCollection =>
      widget.currentUser.isSuperAdmin ||
      widget.currentUser.hasPermission(Permission.dataCreate);

  @override
  Widget build(BuildContext context) {
    final dbsAsync = ref.watch(databasesProvider);
    final databases = dbsAsync.valueOrNull ?? [];

    if (!_canView) {
      return const Center(
        child: Text(
          'Bu sayfayı görüntülemek için yetkiniz bulunmamaktadır.',
          style: TextStyle(color: AppColors.danger, fontSize: 16),
        ),
      );
    }

    if (_selectedDatabaseId == null && databases.isNotEmpty) {
      _selectedDatabaseId = databases.first.id;
    }

    final selectedDb = databases.firstWhere(
      (d) => d.id == _selectedDatabaseId || d.name == _selectedDatabaseId,
      orElse: () => databases.isNotEmpty
          ? databases.first
          : DatabaseItem(
              id: '',
              name: 'Veritabanı Yok',
              department: 'General',
              description: '',
              collectionCount: 0,
              recordCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, databases, selectedDb),
            const SizedBox(height: 24),
            if (databases.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Henüz veritabanı bulunmamaktadır.'),
                ),
              )
            else
              _buildMainContent(selectedDb),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<DatabaseItem> databases, DatabaseItem selectedDb) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Type Explorer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Koleksiyonların alan adlarını, veri tiplerini inceleyin ve güncelleyin.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: databases.any((d) => d.id == _selectedDatabaseId || d.name == _selectedDatabaseId)
                      ? _selectedDatabaseId
                      : (databases.isNotEmpty ? databases.first.id : null),
                  items: databases.map((db) {
                    return DropdownMenuItem<String>(
                      value: db.id,
                      child: Text(db.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDatabaseId = val;
                        _lastSelectedDatabaseId = val;
                        _selectedCollection = null;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_canCreateCollection && selectedDb.id.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _showAddCollectionDialog(selectedDb.name),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Koleksiyon Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainContent(DatabaseItem selectedDb) {
    return FutureBuilder<List<String>>(
      future: ref.read(dataExplorerRepositoryProvider).getCollections(selectedDb.name),
      builder: (context, snapshot) {
        final cols = (snapshot.data ?? []).toList();
        final extra = _extraCollections[selectedDb.id] ?? [];
        for (final e in extra) {
          if (!cols.contains(e)) cols.add(e);
        }

        if (_selectedCollection == null && cols.isNotEmpty) {
          _selectedCollection = cols.first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cols.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Bu veritabanında henüz koleksiyon bulunmamaktadır.'),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cols.map((c) {
                  final isSelected = c == _selectedCollection;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _selectedCollection = c;
                          _lastSelectedCollection = c;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              if (_selectedCollection != null)
                _buildSchemaTable(selectedDb.name, _selectedCollection!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSchemaTable(String dbName, String colName) {
    return FutureBuilder<List<DataRecord>>(
      future: ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbName,
            collectionName: colName,
          ),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final fieldsMap = <String, String>{};
        for (final r in records) {
          r.data.forEach((k, v) {
            if (!fieldsMap.containsKey(k)) {
              fieldsMap[k] = _inferType(v);
            }
          });
        }

        if (fieldsMap.isEmpty) {
          fieldsMap['_id'] = 'String';
          fieldsMap['created_at'] = 'DateTime';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Alan Adı (Field)')),
                DataColumn(label: Text('Veri Tipi (Type)')),
                DataColumn(label: Text('Durum')),
              ],
              rows: fieldsMap.entries.map((e) {
                final custom = _customTypes['${dbName}_${colName}_${e.key}'];
                final displayType = custom ?? e.value;
                return DataRow(
                  cells: [
                    DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      DropdownButton<String>(
                        value: ['String', 'Integer', 'Double', 'Boolean', 'DateTime', 'Array', 'Object'].contains(displayType)
                            ? displayType
                            : 'String',
                        items: ['String', 'Integer', 'Double', 'Boolean', 'DateTime', 'Array', 'Object']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _customTypes['${dbName}_${colName}_${e.key}'] = val;
                            });
                          }
                        },
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(custom != null ? 'Özel' : 'Otomatik'),
                        backgroundColor: custom != null ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _inferType(dynamic val) {
    if (val is int) return 'Integer';
    if (val is double) return 'Double';
    if (val is bool) return 'Boolean';
    if (val is List) return 'Array';
    if (val is Map) return 'Object';
    if (val != null && DateTime.tryParse(val.toString()) != null) return 'DateTime';
    return 'String';
  }

  Future<void> _showAddCollectionDialog(String dbName) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Koleksiyon Ekle'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Koleksiyon Adı',
              hintText: 'örn. test_koleksiyon',
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
      final name = controller.text.trim();
      final creds = ref.read(credentialsProvider);

      if (creds != null) {
        try {
          await ref.read(socketServiceProvider).send(
            action: 'CREATE_COLLECTION',
            username: creds.username,
            password: creds.password,
            database: dbName,
            collection: name,
          );
        } catch (_) {}
      }

      setState(() {
        _extraCollections.putIfAbsent(dbName, () => []).add(name);
        _selectedCollection = name;
        _lastSelectedCollection = name;
      });

      if (mounted) {
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