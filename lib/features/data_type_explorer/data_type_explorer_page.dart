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

  bool get _canUpdateType =>
      widget.currentUser.isSuperAdmin ||
      widget.currentUser.hasPermission(Permission.dataUpdate);

  bool get _canCreateCollection =>
      widget.currentUser.isSuperAdmin ||
      widget.currentUser.hasPermission(Permission.dataCreate);

  @override
  Widget build(BuildContext context) {
    final dbsAsync = ref.watch(databasesProvider);
    final databases = dbsAsync.valueOrNull ?? [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_canView) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Bu sayfayı görüntülemek için yetkiniz bulunmamaktadır.',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary, fontSize: 16),
            ),
          ],
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
              name: '',
              department: 'General',
              description: '',
              collectionCount: 0,
              recordCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık ──
          Text(
            'Data Type Explorer',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Koleksiyonların alan adlarını, veri tiplerini inceleyin ve güncelleyin.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ── Veritabanı Seçici + Koleksiyon Ekle ──
          _buildDatabaseSelector(databases, selectedDb, isDark),
          const SizedBox(height: 20),

          // ── Ana İçerik ──
          if (databases.isEmpty)
            _buildEmptyBox(
              icon: Icons.storage_outlined,
              title: 'Henüz veritabanı bulunmamaktadır.',
              subtitle: 'Veritabanı oluşturmak için Databases sayfasını kullanın.',
              isDark: isDark,
            )
          else
            _buildMainContent(selectedDb, isDark),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Veritabanı Seçici
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDatabaseSelector(List<DatabaseItem> databases, DatabaseItem selectedDb, bool isDark) {
    return Row(
      children: [
        // Veritabanı dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storage_outlined, size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
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
                        _lastSelectedCollection = null;
                      });
                    }
                  },
                ),
              ),
            ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Ana İçerik: Koleksiyon Seçimi + Şema Tablosu
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent(DatabaseItem selectedDb, bool isDark) {
    return FutureBuilder<List<String>>(
      future: ref.read(dataExplorerRepositoryProvider).getCollections(selectedDb.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }

        final cols = (snapshot.data ?? []).toList();
        final extra = _extraCollections[selectedDb.id] ?? [];
        for (final e in extra) {
          if (!cols.contains(e)) cols.add(e);
        }

        if (_selectedCollection == null && cols.isNotEmpty) {
          _selectedCollection = cols.first;
        }

        if (cols.isEmpty) {
          return _buildEmptyBox(
            icon: Icons.folder_open_outlined,
            title: 'Bu veritabanında henüz koleksiyon bulunmamaktadır.',
            subtitle: 'Koleksiyon eklemek için yukarıdaki butonu kullanabilirsiniz.',
            isDark: isDark,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Koleksiyon chip'leri
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cols.map((c) {
                final isSelected = c == _selectedCollection;
                return ChoiceChip(
                  label: Text(c),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
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
              _buildSchemaTable(selectedDb.name, _selectedCollection!, isDark),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Şema Tablosu: Alanlar + Veri Tipleri
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSchemaTable(String dbName, String colName, bool isDark) {
    return FutureBuilder<List<DataRecord>>(
      future: ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbName,
            collectionName: colName,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }

        final records = snapshot.data ?? [];

        // ── Boş koleksiyon ──
        if (records.isEmpty) {
          return _buildEmptyBox(
            icon: Icons.table_rows_outlined,
            title: 'Bu koleksiyonda henüz kayıt bulunmamaktadır.',
            subtitle: 'Kayıt eklendikçe alan adları ve veri tipleri burada otomatik olarak görünecektir.',
            isDark: isDark,
          );
        }

        // ── Alanları ve tiplerini tüm kayıtlardan çıkar ──
        final fieldsMap = <String, _FieldInfo>{};
        for (final r in records) {
          r.data.forEach((key, val) {
            if (fieldsMap.containsKey(key)) {
              fieldsMap[key]!.sampleCount++;
            } else {
              fieldsMap[key] = _FieldInfo(
                inferredType: _inferType(val),
                sampleValue: val,
                sampleCount: 1,
              );
            }
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst bilgi satırı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schema_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$colName — ${fieldsMap.length} alan, ${records.length} kayıt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Tablo
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  columns: const [
                    DataColumn(label: Text('Alan Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Algılanan Tip', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Atanan Tip', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Kayıt Sayısı', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: fieldsMap.entries.map((entry) {
                    final key = entry.key;
                    final info = entry.value;
                    final customKey = '${dbName}_${colName}_$key';
                    final customType = _customTypes[customKey];
                    final isOverridden = customType != null && customType != info.inferredType;

                    return DataRow(
                      cells: [
                        // Alan adı
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_iconForType(customType ?? info.inferredType), size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                            ],
                          ),
                        ),

                        // Algılanan (otomatik) tip
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _colorForType(info.inferredType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              info.inferredType,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _colorForType(info.inferredType),
                              ),
                            ),
                          ),
                        ),

                        // Atanan tip (dropdown – yetki yoksa disabled)
                        DataCell(
                          DropdownButton<String>(
                            value: _validTypeValue(customType ?? info.inferredType),
                            underline: const SizedBox(),
                            items: _typeOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: _canUpdateType
                                ? (val) {
                                    if (val != null) {
                                      setState(() {
                                        _customTypes[customKey] = val;
                                      });
                                    }
                                  }
                                : null,
                          ),
                        ),

                        // Kayıt sayısı
                        DataCell(Text('${info.sampleCount} / ${records.length}')),

                        // Durum chip'i
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOverridden
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOverridden ? 'Özel' : 'Otomatik',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOverridden ? Colors.amber.shade800 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Yetki uyarısı
              if (!_canUpdateType)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Veri tiplerini değiştirmek için güncelleme yetkiniz bulunmamaktadır.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Boş Durum Kutusu
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Yardımcılar
  // ════════════════════════════════════════════════════════════════════════

  static const _typeOptions = ['String', 'Integer', 'Double', 'Boolean', 'DateTime', 'Array', 'Object'];

  String _validTypeValue(String type) {
    return _typeOptions.contains(type) ? type : 'String';
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'String':
        return Icons.text_fields;
      case 'Integer':
      case 'Double':
        return Icons.tag;
      case 'Boolean':
        return Icons.toggle_on_outlined;
      case 'DateTime':
        return Icons.calendar_today_outlined;
      case 'Array':
        return Icons.list;
      case 'Object':
        return Icons.data_object;
      default:
        return Icons.help_outline;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'String':
        return const Color(0xFF3B82F6);
      case 'Integer':
        return const Color(0xFF8B5CF6);
      case 'Double':
        return const Color(0xFFEC4899);
      case 'Boolean':
        return const Color(0xFF10B981);
      case 'DateTime':
        return const Color(0xFFF59E0B);
      case 'Array':
        return const Color(0xFF06B6D4);
      case 'Object':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Koleksiyon Ekleme Diyalogu
  // ════════════════════════════════════════════════════════════════════════

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

// ════════════════════════════════════════════════════════════════════════
//  Yardımcı Modeller
// ════════════════════════════════════════════════════════════════════════

class _FieldInfo {
  final String inferredType;
  final dynamic sampleValue;
  int sampleCount;

  _FieldInfo({
    required this.inferredType,
    this.sampleValue,
    this.sampleCount = 1,
  });
}