import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/data_record.dart';
import '../../models/database_item.dart';
import '../../models/permission.dart';
import '../databases/controllers/databases_notifier.dart';
import '../data_explorer/controllers/data_explorer_notifier.dart';

class DataTypeExplorerPage extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const DataTypeExplorerPage({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<DataTypeExplorerPage> createState() =>
      _DataTypeExplorerPageState();
}

class _DataTypeExplorerPageState
    extends ConsumerState<DataTypeExplorerPage> {
  static String? _lastSelectedDatabaseId;
  static String? _lastSelectedCollection;

  String? _selectedDatabaseId;
  String? _selectedCollection;

  final Map<String, String> _customTypes = {};
  final Map<String, List<String>> _extraCollections = {};
  final Set<String> _selectedFields = {};
  String _searchQuery = '';
  String _bulkTargetType = 'String';

  bool _isSavingToDb = false;
  bool _isRecordLevelMode = false;
  final Map<String, Map<String, String>> _recordCustomTypes = {};

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDatabaseId = _lastSelectedDatabaseId;
    _selectedCollection = _lastSelectedCollection;
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final rawDatabases = dbsAsync.valueOrNull ?? [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Veritabanı isimlerini deduplicate et
    final seenKeys = <String>{};
    final List<DatabaseItem> databases = [];
    for (final db in rawDatabases) {
      final key = db.name.isNotEmpty ? db.name : db.id;
      if (seenKeys.add(key)) {
        databases.add(db);
      }
    }

    if (!_canView) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: isDark ? const Color(0xFF64748B) : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bu sayfayı görüntülemek için yetkiniz bulunmamaktadır.',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedDatabaseId == null && databases.isNotEmpty) {
      _selectedDatabaseId =
          databases.first.name.isNotEmpty ? databases.first.name : databases.first.id;
    }

    final selectedDb = databases.firstWhere(
      (d) =>
          d.id == _selectedDatabaseId ||
          d.name == _selectedDatabaseId,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Type Explorer',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Koleksiyonların alan adlarını inceleyin, veri tiplerini tekli veya toplu olarak yönetin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              subtitle:
                  'Veritabanı oluşturmak için Databases sayfasını kullanın.',
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

  Widget _buildDatabaseSelector(
      List<DatabaseItem> databases, DatabaseItem selectedDb, bool isDark) {
    return Row(
      children: [
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
              Icon(
                Icons.storage_outlined,
                size: 18,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: databases.any(
                          (d) => d.id == _selectedDatabaseId || d.name == _selectedDatabaseId)
                      ? _selectedDatabaseId
                      : (databases.isNotEmpty
                          ? (databases.first.name.isNotEmpty
                              ? databases.first.name
                              : databases.first.id)
                          : null),
                  items: databases.map((db) {
                    final key = db.name.isNotEmpty ? db.name : db.id;
                    return DropdownMenuItem<String>(
                      value: key,
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
                        _selectedFields.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (_canCreateCollection && selectedDb.name.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _showAddCollectionDialog(selectedDb.name),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Koleksiyon Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Ana İçerik: Koleksiyon Seçimi + Şema Görünümü
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent(DatabaseItem selectedDb, bool isDark) {
    return FutureBuilder<List<String>>(
      future: ref
          .read(dataExplorerRepositoryProvider)
          .getCollections(selectedDb.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final cols = (snapshot.data ?? []).toList();
        final dbKey = selectedDb.name.isNotEmpty ? selectedDb.name : selectedDb.id;
        final extra = _extraCollections[dbKey] ?? _extraCollections[selectedDb.id] ?? [];
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
            subtitle:
                'Koleksiyon eklemek için yukarıdaki butonu kullanabilirsiniz.',
            isDark: isDark,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Koleksiyon chip'leri + Mod Seçici
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cols.map((c) {
                      final isSelected = c == _selectedCollection;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : AppColors.textPrimary),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _selectedCollection = c;
                              _lastSelectedCollection = c;
                              _selectedFields.clear();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.schema_outlined),
                      label: Text('Genel Şema'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.badge_outlined),
                      label: Text('Kayıt Bazlı Düzenle'),
                    ),
                  ],
                  selected: {_isRecordLevelMode},
                  onSelectionChanged: (val) {
                    setState(() {
                      _isRecordLevelMode = val.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedCollection != null)
              _isRecordLevelMode
                  ? _buildRecordLevelTypeEditor(
                      selectedDb.name, _selectedCollection!, isDark)
                  : _buildSchemaSection(
                      selectedDb.name, _selectedCollection!, isDark),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Şema Yönetim Bölümü: İstatistikler + Arama + Toplu İşlem + Tablo
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSchemaSection(String dbName, String colName, bool isDark) {
    return FutureBuilder<List<DataRecord>>(
      future: ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbName,
            collectionName: colName,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return _buildEmptyBox(
            icon: Icons.table_rows_outlined,
            title: 'Bu koleksiyonda henüz kayıt bulunmamaktadır.',
            subtitle:
                'Kayıt eklendikçe şema ve veri tipleri burada otomatik olarak yönetilebilir hale gelecektir.',
            isDark: isDark,
          );
        }

        // ── Tüm kayıtlardan alan adlarını ve otomatik tiplerini çıkar ──
        final fieldsMap = <String, _FieldInfo>{};
        for (final r in records) {
          r.data.forEach((key, val) {
            if (fieldsMap.containsKey(key)) {
              fieldsMap[key]!.sampleCount++;
            } else {
              fieldsMap[key] = _FieldInfo(
                inferredType: _inferType(val),
                sampleCount: 1,
              );
            }
          });
        }

        // Arama filtresi
        final filteredEntries = fieldsMap.entries.where((e) {
          if (_searchQuery.isEmpty) return true;
          return e.key.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // İstatistik hesaplamaları
        int customCount = 0;
        for (final key in fieldsMap.keys) {
          final customKey = '${dbName}_${colName}_$key';
          if (_customTypes.containsKey(customKey) &&
              _customTypes[customKey] != fieldsMap[key]!.inferredType) {
            customCount++;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst İstatistik Kartları ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      icon: Icons.tune_outlined,
                      label: 'Toplam Alan',
                      value: '${fieldsMap.length}',
                      color: AppColors.primary,
                      isDark: isDark,
                      width: isNarrow ? constraints.maxWidth : 160,
                    ),
                    _buildStatCard(
                      icon: Icons.edit_note_outlined,
                      label: 'Özel Atanan Tip',
                      value: '$customCount',
                      color: customCount > 0 ? Colors.amber.shade700 : Colors.blueGrey,
                      isDark: isDark,
                      width: isNarrow ? constraints.maxWidth : 160,
                    ),
                    _buildStatCard(
                      icon: Icons.check_box_outlined,
                      label: 'Seçili Alan',
                      value: '${_selectedFields.length}',
                      color: _selectedFields.isNotEmpty ? Colors.green : Colors.grey,
                      isDark: isDark,
                      width: isNarrow ? constraints.maxWidth : 160,
                    ),
                    _buildStatCard(
                      icon: Icons.auto_graph_outlined,
                      label: 'Kayıt Sayısı',
                      value: '${records.length}',
                      color: Colors.purple,
                      isDark: isDark,
                      width: isNarrow ? constraints.maxWidth : 160,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Arama Barı ve Kod Aktarma Butonu ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Alan adına göre ara...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showExportCodeDialog(dbName, colName, fieldsMap),
                  icon: const Icon(Icons.code),
                  label: const Text('Şemayı Kod Olarak Aktar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_canUpdateType) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSavingToDb
                        ? null
                        : () => _confirmAndSaveTypesToDatabase(
                              dbName, colName, records, fieldsMap),
                    icon: _isSavingToDb
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSavingToDb
                        ? 'Veritabanına Kaydediliyor...'
                        : 'Değişiklikleri Veritabanına Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Toplu İşlem Barı (Bulk Action Bar) ──
            if (_canUpdateType && _selectedFields.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.checklist, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedFields.length} alan seçildi',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const Text('Toplu Tip:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _bulkTargetType,
                      underline: const SizedBox(),
                      items: _typeOptions
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _bulkTargetType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _applyBulkTypeChange(dbName, colName),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Toplu Uygula'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _resetSelectedTypes(dbName, colName, fieldsMap),
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Varsayılana Dön'),
                    ),
                  ],
                ),
              ),

            // ── Şema Tablosu ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tablo Başlık Barı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schema_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$colName — ${filteredEntries.length} alan gösteriliyor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fare desteği ile Tablo Görünümü
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                            ),
                            columns: [
                              if (_canUpdateType)
                                DataColumn(
                                  label: Checkbox(
                                    value: filteredEntries.isNotEmpty &&
                                        filteredEntries.every(
                                            (e) => _selectedFields.contains(e.key)),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedFields.addAll(
                                              filteredEntries.map((e) => e.key));
                                        } else {
                                          _selectedFields.removeAll(
                                              filteredEntries.map((e) => e.key));
                                        }
                                      });
                                    },
                                  ),
                                ),
                              const DataColumn(
                                label: Text('Alan Adı',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Otomatik Algılanan Tip',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Atanan Tip (Düzenle)',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Varlık Oranı',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const DataColumn(
                                label: Text('Durum',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: filteredEntries.map((entry) {
                              final key = entry.key;
                              final info = entry.value;
                              final customKey = '${dbName}_${colName}_$key';
                              final customType = _customTypes[customKey];
                              final activeType = customType ?? info.inferredType;
                              final isOverridden = customType != null &&
                                  customType != info.inferredType;

                              final isSelected = _selectedFields.contains(key);
                              final percent = (info.sampleCount / records.length * 100).toStringAsFixed(0);

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: _canUpdateType
                                    ? (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedFields.add(key);
                                          } else {
                                            _selectedFields.remove(key);
                                          }
                                        });
                                      }
                                    : null,
                                cells: [
                                  if (_canUpdateType)
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedFields.add(key);
                                            } else {
                                              _selectedFields.remove(key);
                                            }
                                          });
                                        },
                                      ),
                                    ),

                                  // Alan adı
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_iconForType(activeType),
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Otomatik algılanan tip
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _colorForType(info.inferredType)
                                            .withOpacity(0.1),
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

                                  // Atanan tip (dropdown)
                                  DataCell(
                                    DropdownButton<String>(
                                      value: _validTypeValue(activeType),
                                      underline: const SizedBox(),
                                      items: _typeOptions
                                          .map((t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t,
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ))
                                          .toList(),
                                      onChanged: _canUpdateType
                                          ? (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _customTypes[customKey] = val;
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "'$key' alanının tipi '$val' olarak güncellendi."),
                                                    duration:
                                                        const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                    ),
                                  ),

                                  // Varlık oranı
                                  DataCell(
                                    Text(
                                      '${info.sampleCount} / ${records.length} kayıt (%$percent)',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),

                                  // Durum rozeti
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOverridden
                                            ? Colors.amber.withOpacity(0.15)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isOverridden ? 'Özel' : 'Otomatik',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isOverridden
                                              ? Colors.amber.shade800
                                              : Colors.green.shade700,
                                        ),
                                      ),
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

                  if (!_canUpdateType)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Veri tiplerini değiştirmek için güncelleme yetkiniz bulunmamaktadır.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Toplu İşlemler & Sıfırlama
  // ════════════════════════════════════════════════════════════════════════

  void _applyBulkTypeChange(String dbName, String colName) {
    if (_selectedFields.isEmpty) return;

    setState(() {
      for (final key in _selectedFields) {
        final customKey = '${dbName}_${colName}_$key';
        _customTypes[customKey] = _bulkTargetType;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "${_selectedFields.length} alanın tipi topluca '$_bulkTargetType' olarak güncellendi."),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetSelectedTypes(
      String dbName, String colName, Map<String, _FieldInfo> fieldsMap) {
    if (_selectedFields.isEmpty) return;

    setState(() {
      for (final key in _selectedFields) {
        final customKey = '${dbName}_${colName}_$key';
        _customTypes.remove(customKey);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "${_selectedFields.length} alanın tipi varsayılana sıfırlandı."),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Veri Tiplerini Tüm Kayıtlarda Dönüştürüp Veritabanına Kaydetme
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _confirmAndSaveTypesToDatabase(
    String dbName,
    String colName,
    List<DataRecord> records,
    Map<String, _FieldInfo> fieldsMap,
  ) async {
    final modifiedFields = <String, String>{};
    fieldsMap.forEach((key, info) {
      final customKey = '${dbName}_${colName}_$key';
      final customType = _customTypes[customKey];
      if (customType != null) {
        modifiedFields[key] = customType;
      }
    });

    if (modifiedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz veritabanında değiştirilecek özel veri tipi atamadınız.'),
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Veri Tiplerini Veritabanına Kaydet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "'$colName' koleksiyonundaki ${records.length} kaydın değerleri aşağıdaki tiplere dönüştürülüp veritabanına kaydedilecek:",
              ),
              const SizedBox(height: 12),
              ...modifiedFields.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 18),
                      Text(
                        '${e.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(e.value, style: const TextStyle(color: AppColors.primary)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Bu işlem koleksiyondaki kayıtların gerçek veri türlerini değiştirecektir.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.save),
              label: const Text('Evet, Dönüştür ve Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isSavingToDb = true;
    });

    try {
      final creds = ref.read(credentialsProvider);
      final tcpRepo = ref.read(socketServiceProvider);

      int updatedCount = 0;
      for (final rec in records) {
        final Map<String, dynamic> updatedData = Map<String, dynamic>.from(rec.data);
        bool recordChanged = false;

        modifiedFields.forEach((fieldKey, targetType) {
          if (updatedData.containsKey(fieldKey)) {
            final oldVal = updatedData[fieldKey];
            final newVal = _convertValueToType(oldVal, targetType);
            updatedData[fieldKey] = newVal;
            recordChanged = true;
          }
        });

        if (recordChanged && creds != null) {
          await tcpRepo.send(
            action: 'UPDATE',
            username: creds.username,
            password: creds.password,
            database: dbName,
            collection: colName,
            filter: {'_id': rec.id},
            document: updatedData,
          );
          updatedCount++;
        }
      }

      // Veritabanı ve Data Explorer durumlarını yenile
      ref.invalidate(dataExplorerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Başarılı! '$colName' koleksiyonundaki $updatedCount kaydın tipleri veritabanında dönüştürüldü ve kaydedildi.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kaydetme hatası: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToDb = false;
        });
      }
    }
  }

  dynamic _convertValueToType(dynamic val, String targetType) {
    if (val == null) return null;
    var strVal = val.toString().trim();

    switch (targetType) {
      case 'Integer':
        if (val is List && val.isNotEmpty) {
          return int.tryParse(val.first.toString()) ?? 0;
        }
        return int.tryParse(strVal) ?? num.tryParse(strVal)?.toInt() ?? val;

      case 'Double':
        if (val is List && val.isNotEmpty) {
          return double.tryParse(val.first.toString()) ?? 0.0;
        }
        return double.tryParse(strVal) ?? num.tryParse(strVal)?.toDouble() ?? val;

      case 'Boolean':
        final lower = strVal.toLowerCase();
        return (lower == 'true' || lower == '1' || val == true || val == 1);

      case 'String':
        if (val is List) {
          return val.map((e) => _cleanQuotesAndBrackets(e.toString())).join(', ');
        }
        if (val is Map) {
          return jsonEncode(val);
        }
        // Eğer string başında/sonunda [ ] parantezleri veya tırnaklar varsa temizle
        if (strVal.startsWith('[') && strVal.endsWith(']')) {
          try {
            final decoded = jsonDecode(strVal);
            if (decoded is List) {
              return decoded.map((e) => _cleanQuotesAndBrackets(e.toString())).join(', ');
            }
          } catch (_) {}
        }
        return _cleanQuotesAndBrackets(strVal);

      case 'DateTime':
        return strVal;

      case 'Array':
        if (val is List) return val;
        try {
          final decoded = jsonDecode(strVal);
          if (decoded is List) return decoded;
        } catch (_) {}
        if (strVal.contains(',')) {
          return strVal.split(',').map((e) => e.trim()).toList();
        }
        return [val];

      case 'Object':
        if (val is Map) return val;
        try {
          final decoded = jsonDecode(strVal);
          if (decoded is Map) return decoded;
        } catch (_) {}
        return {'value': val};

      default:
        return val;
    }
  }

  String _cleanQuotesAndBrackets(String text) {
    var t = text.trim();
    if (t.startsWith('[') && t.endsWith(']')) {
      t = t.substring(1, t.length - 1).trim();
    }
    if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
      t = t.substring(1, t.length - 1).trim();
    }
    return t;
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Şemayı Kod Olarak Dışa Aktarma Diyaloğu
  // ════════════════════════════════════════════════════════════════════════

  void _showExportCodeDialog(
      String dbName, String colName, Map<String, _FieldInfo> fieldsMap) {
    final className = colName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final capitalizedName = className.isEmpty
        ? 'Model'
        : className[0].toUpperCase() + className.substring(1);

    // 1. Dart Sınıfı
    final dartBuffer = StringBuffer();
    dartBuffer.writeln('class $capitalizedName {');
    fieldsMap.forEach((key, info) {
      final customKey = '${dbName}_${colName}_$key';
      final type = _customTypes[customKey] ?? info.inferredType;
      final dartType = _mapToDartType(type);
      dartBuffer.writeln('  final $dartType $key;');
    });
    dartBuffer.writeln('\n  const $capitalizedName({');
    fieldsMap.forEach((key, _) {
      dartBuffer.writeln('    required this.$key,');
    });
    dartBuffer.writeln('  });\n}');

    // 2. TypeScript Interface
    final tsBuffer = StringBuffer();
    tsBuffer.writeln('interface $capitalizedName {');
    fieldsMap.forEach((key, info) {
      final customKey = '${dbName}_${colName}_$key';
      final type = _customTypes[customKey] ?? info.inferredType;
      final tsType = _mapToTsType(type);
      tsBuffer.writeln('  $key: $tsType;');
    });
    tsBuffer.writeln('}');

    // 3. JSON Schema
    final jsonSchemaMap = <String, dynamic>{
      '\$schema': 'http://json-schema.org/draft-07/schema#',
      'title': capitalizedName,
      'type': 'object',
      'properties': <String, dynamic>{},
    };
    fieldsMap.forEach((key, info) {
      final customKey = '${dbName}_${colName}_$key';
      final type = _customTypes[customKey] ?? info.inferredType;
      jsonSchemaMap['properties'][key] = {'type': type.toLowerCase()};
    });
    final jsonSchemaText =
        const JsonEncoder.withIndent('  ').convert(jsonSchemaMap);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.code, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('$colName Şemasını Aktar'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 450),
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Dart Class'),
                      Tab(text: 'TypeScript'),
                      Tab(text: 'JSON Schema'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCodeSnippet(dartBuffer.toString()),
                        _buildCodeSnippet(tsBuffer.toString()),
                        _buildCodeSnippet(jsonSchemaText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF38BDF8),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kod panoya kopyalandı!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Panoya Kopyala'),
          ),
        ),
      ],
    );
  }

  String _mapToDartType(String type) {
    switch (type) {
      case 'Integer':
        return 'int';
      case 'Double':
        return 'double';
      case 'Boolean':
        return 'bool';
      case 'DateTime':
        return 'DateTime';
      case 'Array':
        return 'List<dynamic>';
      case 'Object':
        return 'Map<String, dynamic>';
      default:
        return 'String';
    }
  }

  String _mapToTsType(String type) {
    switch (type) {
      case 'Integer':
      case 'Double':
        return 'number';
      case 'Boolean':
        return 'boolean';
      case 'DateTime':
        return 'Date | string';
      case 'Array':
        return 'any[]';
      case 'Object':
        return 'Record<string, any>';
      default:
        return 'string';
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Özet İstatistik Kartı
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 48,
              color: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Yardımcılar
  // ════════════════════════════════════════════════════════════════════════

  static const _typeOptions = [
    'String',
    'Integer',
    'Double',
    'Boolean',
    'DateTime',
    'Array',
    'Object'
  ];

  String _validTypeValue(String type) {
    return _typeOptions.contains(type) ? type : 'String';
  }

  String _inferType(dynamic val) {
    if (val is int) return 'Integer';
    if (val is double) return 'Double';
    if (val is bool) return 'Boolean';
    if (val is List) return 'Array';
    if (val is Map) return 'Object';
    if (val != null &&
        DateTime.tryParse(val.toString()) != null &&
        val.toString().contains('-') &&
        val.toString().length >= 10) return 'DateTime';
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
  //  Kayıt Bazlı Tip Düzenleyici (Her Kaydın Alan Tiplerini Ayrı Ayrı Yönetme)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildRecordLevelTypeEditor(
      String dbName, String colName, bool isDark) {
    return FutureBuilder<List<DataRecord>>(
      future: ref.read(dataExplorerRepositoryProvider).getRecords(
            databaseId: dbName,
            collectionName: colName,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return _buildEmptyBox(
            icon: Icons.table_rows_outlined,
            title: 'Bu koleksiyonda henüz kayıt bulunmamaktadır.',
            subtitle:
                'Kayıt eklendikçe her kaydın alan tiplerini ayrı ayrı burada düzenleyebilirsiniz.',
            isDark: isDark,
          );
        }

        final filteredRecords = records.where((r) {
          if (_searchQuery.isEmpty) return true;
          final matchId =
              r.id.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchData = r.data.entries.any((e) =>
              e.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.value.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
          return matchId || matchData;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bilgi + Kaydet Butonu
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Kayıt ID veya alan içeriğine göre ara...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_canUpdateType)
                  ElevatedButton.icon(
                    onPressed: _isSavingToDb
                        ? null
                        : () => _saveAllRecordLevelTypes(
                              dbName, colName, records),
                    icon: _isSavingToDb
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSavingToDb
                        ? 'Veritabanına Kaydediliyor...'
                        : 'Tüm Kayıt Değişikliklerini Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Kayıt Kartları Listesi
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final rec = filteredRecords[index];
                return _buildSingleRecordTypeCard(dbName, colName, rec, isDark);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleRecordTypeCard(
    String dbName,
    String colName,
    DataRecord rec,
    bool isDark,
  ) {
    _recordCustomTypes.putIfAbsent(rec.id, () => {});
    final recTypes = _recordCustomTypes[rec.id]!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart Başlığı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Kayıt ID: ${rec.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (_canUpdateType)
                  ElevatedButton.icon(
                    onPressed: () => _saveSingleRecordType(dbName, colName, rec),
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text('Bu Kaydı Güncelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),

          // Alanlar Listesi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: rec.data.entries.map((entry) {
                final key = entry.key;
                final val = entry.value;
                final currentInferred = _inferType(val);
                final assignedType = recTypes[key] ?? currentInferred;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Alan Adı
                      SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            Icon(_iconForType(assignedType),
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Mevcut Değer Gösterimi
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            val.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Tip Seçici Dropdown
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          value: _validTypeValue(assignedType),
                          isDense: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: _typeOptions
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: _canUpdateType
                              ? (valType) {
                                  if (valType != null) {
                                    setState(() {
                                      recTypes[key] = valType;
                                      rec.data[key] =
                                          _convertValueToType(val, valType);
                                    });
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSingleRecordType(
      String dbName, String colName, DataRecord rec) async {
    try {
      final creds = ref.read(credentialsProvider);
      final tcpRepo = ref.read(socketServiceProvider);

      if (creds != null) {
        await tcpRepo.send(
          action: 'UPDATE',
          username: creds.username,
          password: creds.password,
          database: dbName,
          collection: colName,
          filter: {'_id': rec.id},
          document: rec.data,
        );

        ref.invalidate(dataExplorerProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "ID '${rec.id}' kaydının veri tipleri güncellendi ve veritabanına kaydedildi!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Güncelleme hatası: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveAllRecordLevelTypes(
      String dbName, String colName, List<DataRecord> records) async {
    setState(() {
      _isSavingToDb = true;
    });

    try {
      final creds = ref.read(credentialsProvider);
      final tcpRepo = ref.read(socketServiceProvider);

      int updatedCount = 0;
      for (final rec in records) {
        if (creds != null) {
          await tcpRepo.send(
            action: 'UPDATE',
            username: creds.username,
            password: creds.password,
            database: dbName,
            collection: colName,
            filter: {'_id': rec.id},
            document: rec.data,
          );
          updatedCount++;
        }
      }

      ref.invalidate(dataExplorerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Tüm $updatedCount kaydın özel tipleri veritabanına başarıyla kaydedildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kaydetme hatası: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToDb = false;
        });
      }
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

class _FieldInfo {
  final String inferredType;
  int sampleCount;

  _FieldInfo({
    required this.inferredType,
    this.sampleCount = 1,
  });
}