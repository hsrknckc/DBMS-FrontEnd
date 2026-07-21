import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';

class DashboardPage extends StatelessWidget {
  final AppUser? currentUser;

  const DashboardPage({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildStatCards(boxBgColor, borderColor, titleColor, subtitleColor),
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

  Widget _buildStatCards(Color boxBgColor, Color borderColor, Color titleColor, Color subtitleColor) {
    const stats = [
      _StatItem(
        title: 'Toplam Database',
        value: '8',
        icon: Icons.storage_outlined,
      ),
      _StatItem(
        title: 'Toplam Collection',
        value: '24',
        icon: Icons.folder_copy_outlined,
      ),
      _StatItem(
        title: 'Toplam Kayıt',
        value: '128.450',
        icon: Icons.table_rows_outlined,
      ),
      _StatItem(
        title: 'Aktif Kullanıcı',
        value: '16',
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
              const SizedBox(height: 16),
              _SystemStatusCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _RecentActivityCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SystemStatusCard(
                boxBgColor: boxBgColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storage_outlined,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
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
    const activities = [
      _ActivityItem(
        title: 'Yeni collection oluşturuldu',
        description: 'sensor_data collection oluşturuldu.',
        time: '5 dakika önce',
        icon: Icons.folder_copy_outlined,
      ),
      _ActivityItem(
        title: 'Kullanıcı yetkisi güncellendi',
        description: 'Mehmet Kaya, Sensor Admin olarak atandı.',
        time: '22 dakika önce',
        icon: Icons.admin_panel_settings_outlined,
      ),
      _ActivityItem(
        title: 'Veri dışa aktarıldı',
        description: 'signal_data verileri CSV olarak indirildi.',
        time: '1 saat önce',
        icon: Icons.download_outlined,
      ),
    ];

    final iconBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son İşlemler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistemde gerçekleştirilen son hareketler.',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 20),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.icon,
                      size: 20,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    activity.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });
}

class _SystemStatusCard extends StatelessWidget {
  final Color boxBgColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;

  const _SystemStatusCard({
    required this.boxBgColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 20),
          _StatusRow(
            title: 'MongoDB',
            status: 'Bağlı',
            isActive: true,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 16),
          _StatusRow(
            title: 'Spring Boot API',
            status: 'Çevrimdışı',
            isActive: false,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 16),
          _StatusRow(
            title: 'Son yedekleme',
            status: 'Bugün 09:30',
            isActive: true,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 20),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 18,
                color: subtitleColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Son güncelleme: 10 Temmuz 2026, 14:20',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final String status;
  final bool isActive;
  final Color titleColor;
  final Color subtitleColor;

  const _StatusRow({
    required this.title,
    required this.status,
    required this.isActive,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.success : AppColors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: titleColor,
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}