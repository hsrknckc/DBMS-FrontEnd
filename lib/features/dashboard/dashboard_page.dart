import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../databases/controllers/databases_notifier.dart';
import '../users/controllers/users_notifier.dart';

class DashboardPage extends ConsumerWidget {
  final AppUser? currentUser;

  const DashboardPage({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dinamik Tema Renkleri
    final Color boxBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, titleColor, subtitleColor),
          const SizedBox(height: 24),
          _buildStatCards(ref, boxBgColor, borderColor, titleColor, subtitleColor),
          const SizedBox(height: 24),
          _buildBottomSection(context, boxBgColor, borderColor, titleColor, subtitleColor, isDark),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, Color titleColor, Color subtitleColor) {
    final userName = currentUser?.name ?? 'Kullanıcı';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş geldiniz, $userName',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sisteminizdeki database, collection ve kullanıcı hareketlerini buradan takip edebilirsiniz.',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(WidgetRef ref, Color boxBgColor, Color borderColor, Color titleColor, Color subtitleColor) {
    final dbsAsync = ref.watch(databasesProvider);
    final usersAsync = ref.watch(usersProvider);

    final dbs = dbsAsync.valueOrNull ?? [];
    final users = usersAsync.valueOrNull ?? [];

    final totalDbs = dbs.length;
    int totalCols = 0;
    int totalRecs = 0;

    for (final db in dbs) {
      totalCols += db.collectionCount;
      totalRecs += db.recordCount;
    }

    final activeUsers = users.where((u) => u.isActive).length;

    final stats = [
      _StatItem(
        title: 'Toplam Database',
        value: totalDbs.toString(),
        icon: Icons.storage_outlined,
      ),
      _StatItem(
        title: 'Toplam Collection',
        value: totalCols.toString(),
        icon: Icons.folder_copy_outlined,
      ),
      _StatItem(
        title: 'Toplam Kayıt',
        value: totalRecs.toString(),
        icon: Icons.table_rows_outlined,
      ),
      _StatItem(
        title: 'Aktif Kullanıcı',
        value: activeUsers.toString(),
        icon: Icons.people_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats.map((item) {
            return SizedBox(
              width: cardWidth < 240 ? 240 : cardWidth,
              child: _StatCard(
                item: item,
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    Color boxBgColor,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;

        if (isNarrow) {
          return Column(
            children: [
              _RecentActivityCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _SystemStatusCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _RecentActivityCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: _SystemStatusCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final Color boxBgColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;

  const _StatCard({
    required this.item,
    required this.boxBgColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
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

class _RecentActivityCard extends StatelessWidget {
  final Color boxBgColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool isDark;

  const _RecentActivityCard({
    required this.boxBgColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Hareketler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Henüz hareket kaydı yok',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  final Color boxBgColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool isDark;

  const _SystemStatusCard({
    required this.boxBgColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistem Durumu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow('TCP Soket Bağlantısı', true, 'Aktif (54.154.220.190:5150)'),
          const SizedBox(height: 12),
          _buildStatusRow('MongoDB Servisi', true, 'Bağlı'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk, String statusText) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle_outline : Icons.error_outline,
          color: isOk ? AppColors.success : AppColors.danger,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: titleColor),
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOk ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}