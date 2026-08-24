import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/audit_log.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final TextEditingController _searchController = TextEditingController();

  AuditAction? _selectedAction;
  bool _showOnlyRevertible = false;

  final List<AuditLog> _logs = [
    AuditLog(
      id: 'log-1',
      action: AuditAction.permissionsUpdated,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-1',
      targetUserName: 'Mehmet Kaya',
      createdAt: DateTime(2026, 7, 15, 14, 40),
      description:
          'Mehmet Kaya kullanıcısının departman ve işlem yetkileri güncellendi.',
      oldValues: {
        'Departmanlar': ['Sensor'],
        'Yetkiler': ['Database görüntüleme', 'Veri görüntüleme'],
      },
      newValues: {
        'Departmanlar': ['Sensor', 'Signal'],
        'Yetkiler': [
          'Database görüntüleme',
          'Veri görüntüleme',
          'Veri dışa aktarma',
        ],
      },
    ),
    AuditLog(
      id: 'log-2',
      action: AuditAction.userSoftDeleted,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-3',
      targetUserName: 'Ahmet Yıldız',
      createdAt: DateTime(2026, 7, 15, 13, 20),
      description: 'Ahmet Yıldız silinen kullanıcılar bölümüne taşındı.',
      oldValues: {'Silindi': false, 'Aktif': true},
      newValues: {'Silindi': true, 'Aktif': false},
    ),
    AuditLog(
      id: 'log-3',
      action: AuditAction.passwordResetRequested,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-2',
      targetUserName: 'Zeynep Demir',
      createdAt: DateTime(2026, 7, 15, 11, 15),
      description: 'Zeynep Demir için şifre yenileme anahtarı oluşturuldu.',
    ),
    AuditLog(
      id: 'log-4',
      action: AuditAction.userStatusChanged,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      targetUserId: 'user-4',
      targetUserName: 'Elif Arslan',
      createdAt: DateTime(2026, 7, 14, 16, 50),
      description: 'Elif Arslan kullanıcısı pasif duruma getirildi.',
      oldValues: {'Aktif': true},
      newValues: {'Aktif': false},
    ),
    AuditLog(
      id: 'log-5',
      action: AuditAction.dataExported,
      performedById: 'user-1',
      performedByName: 'Mehmet Kaya',
      targetUserId: 'user-1',
      targetUserName: 'Mehmet Kaya',
      createdAt: DateTime(2026, 7, 14, 15, 10),
      description: 'Signal departmanındaki veriler CSV olarak dışa aktarıldı.',
      newValues: {'Format': 'CSV', 'Departman': 'Signal', 'Kayıt sayısı': 1240},
    ),
    AuditLog(
      id: 'log-6',
      action: AuditAction.databaseCreated,
      performedById: 'super-admin-1',
      performedByName: 'Ayşe Yılmaz',
      createdAt: DateTime(2026, 7, 14, 10, 30),
      description: 'sensor_archive isimli yeni bir database oluşturuldu.',
      newValues: {'Database adı': 'sensor_archive', 'Departman': 'Sensor'},
    ),
  ];

  List<AuditLog> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();

    final filteredLogs = _logs.where((log) {
      final matchesSearch =
          query.isEmpty ||
          log.description.toLowerCase().contains(query) ||
          log.performedByName.toLowerCase().contains(query) ||
          (log.targetUserName?.toLowerCase().contains(query) ?? false);

      final matchesAction =
          _selectedAction == null || log.action == _selectedAction;

      final matchesRevertible = !_showOnlyRevertible || log.canBeReverted;

      return matchesSearch && matchesAction && matchesRevertible;
    }).toList();

    filteredLogs.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    return filteredLogs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSummaryCards(),
        const SizedBox(height: 18),
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(child: _buildLogList(filteredLogs)),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İşlem Geçmişi', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Sistemde gerçekleştirilen kullanıcı, yetki ve veri işlemlerini inceleyin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final revertibleCount = _logs.where((log) => log.canBeReverted).length;

    final revertedCount = _logs.where((log) => log.isReverted).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Toplam İşlem',
          value: _logs.length.toString(),
          icon: Icons.history_outlined,
        ),
        _SummaryCard(
          title: 'Geri Alınabilir',
          value: revertibleCount.toString(),
          icon: Icons.undo_outlined,
          iconColor: AppColors.warning,
        ),
        _SummaryCard(
          title: 'Geri Alınmış',
          value: revertedCount.toString(),
          icon: Icons.restore_outlined,
          iconColor: AppColors.success,
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Kullanıcı veya işlem ara...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: isNarrow ? constraints.maxWidth : 230,
                child: DropdownButtonFormField<AuditAction?>(
                  initialValue: _selectedAction,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'İşlem türü'),
                  items: [
                    const DropdownMenuItem<AuditAction?>(
                      value: null,
                      child: Text('Tüm işlemler'),
                    ),
                    ...AuditAction.values.map((action) {
                      return DropdownMenuItem<AuditAction?>(
                        value: action,
                        child: Text(
                          action.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value;
                    });
                  },
                ),
              ),
              FilterChip(
                label: const Text('Sadece geri alınabilir'),
                avatar: const Icon(Icons.undo_outlined, size: 18),
                selected: _showOnlyRevertible,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyRevertible = selected;
                  });
                },
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Filtreleri temizle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogList(List<AuditLog> logs) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 14),
              Text(
                'İşlem kaydı bulunamadı',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Arama veya filtre kriterlerini değiştirin.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          separatorBuilder: (_, _) {
            return const Divider(height: 1);
          },
          itemBuilder: (context, index) {
            return _buildLogItem(logs[index]);
          },
        ),
      ),
    );
  }

  Widget _buildLogItem(AuditLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActionIcon(action: log.action),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          log.action.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (log.isReverted) const _RevertedBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.description,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _MetadataItem(
                          icon: Icons.person_outline,
                          label: 'Yapan: ${log.performedByName}',
                        ),
                        if (log.targetUserName != null)
                          _MetadataItem(
                            icon: Icons.flag_outlined,
                            label: 'Hedef: ${log.targetUserName}',
                          ),
                        _MetadataItem(
                          icon: Icons.schedule_outlined,
                          label: _formatDateTime(log.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final buttons = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showLogDetails(log);
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Detay'),
              ),
              if (log.canBeReverted)
                ElevatedButton.icon(
                  onPressed: () {
                    _showRevertDialog(log);
                  },
                  icon: const Icon(Icons.undo_outlined, size: 18),
                  label: const Text('Geri Al'),
                ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                information,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: buttons),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 18),
              buttons,
            ],
          );
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedAction = null;
      _showOnlyRevertible = false;
    });
  }

  Future<void> _showLogDetails(AuditLog log) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(log.action.label),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Açıklama', value: log.description),
                  _DetailRow(label: 'İşlemi yapan', value: log.performedByName),
                  _DetailRow(
                    label: 'Hedef kullanıcı',
                    value: log.targetUserName ?? 'Bulunmuyor',
                  ),
                  _DetailRow(
                    label: 'Tarih',
                    value: _formatDateTime(log.createdAt),
                  ),
                  if (log.oldValues.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Eski Değerler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ValuesCard(values: log.oldValues),
                  ],
                  if (log.newValues.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Yeni Değerler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ValuesCard(values: log.newValues),
                  ],
                  if (log.isReverted) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Bu işlem ${log.revertedByName ?? 'bir Super Admin'} tarafından geri alındı.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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

  Future<void> _showRevertDialog(AuditLog log) async {
    final shouldRevert = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Değişikliği geri al'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'İşlemin eski değerleri yeniden uygulanacaktır. Geri alma işlemi de geçmişe kaydedilir.',
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
              icon: const Icon(Icons.undo_outlined),
              label: const Text('Geri Al'),
            ),
          ],
        );
      },
    );

    if (shouldRevert != true) {
      return;
    }

    final index = _logs.indexWhere((item) => item.id == log.id);

    if (index == -1) {
      return;
    }

    final revertedAt = DateTime.now();

    setState(() {
      _logs[index] = log.copyWith(
        isReverted: true,
        revertedAt: revertedAt,
        revertedByName: 'Ayşe Yılmaz',
      );

      _logs.insert(
        0,
        AuditLog(
          id: revertedAt.millisecondsSinceEpoch.toString(),
          action: AuditAction.permissionsReverted,
          performedById: 'super-admin-1',
          performedByName: 'Ayşe Yılmaz',
          targetUserId: log.targetUserId,
          targetUserName: log.targetUserName,
          createdAt: revertedAt,
          description: '${log.action.label} işlemi geri alındı.',
          oldValues: log.newValues,
          newValues: log.oldValues,
        ),
      );
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Değişiklik geri alındı.')));
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
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
          Expanded(
            child: Column(
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

class _ActionIcon extends StatelessWidget {
  final AuditAction action;

  const _ActionIcon({required this.action});

  @override
  Widget build(BuildContext context) {
    final IconData icon;

    switch (action) {
      case AuditAction.userCreated:
        icon = Icons.person_add_alt_outlined;
        break;

      case AuditAction.userUpdated:
        icon = Icons.edit_outlined;
        break;

      case AuditAction.userStatusChanged:
        icon = Icons.toggle_on_outlined;
        break;

      case AuditAction.userSoftDeleted:
        icon = Icons.delete_outline;
        break;

      case AuditAction.userRestored:
        icon = Icons.restore_outlined;
        break;

      case AuditAction.userPermanentlyDeleted:
        icon = Icons.delete_forever_outlined;
        break;

      case AuditAction.permissionsUpdated:
        icon = Icons.admin_panel_settings_outlined;
        break;

      case AuditAction.permissionsReverted:
        icon = Icons.undo_outlined;
        break;

      case AuditAction.passwordResetRequested:
        icon = Icons.key_outlined;
        break;

      case AuditAction.dataExported:
        icon = Icons.download_outlined;
        break;

      case AuditAction.databaseCreated:
        icon = Icons.storage_outlined;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RevertedBadge extends StatelessWidget {
  const _RevertedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Geri alındı',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }

          return Row(
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
          );
        },
      ),
    );
  }
}

class _ValuesCard extends StatelessWidget {
  final Map<String, dynamic> values;

  const _ValuesCard({required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatValue(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }

    return value.toString();
  }
}
