import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoş geldiniz, Ayşe',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Sisteminizdeki database, collection ve kullanıcı hareketlerini buradan takip edebilirsiniz.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildStatCards() {
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
              child: _StatCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;

        if (isNarrow) {
          return const Column(
            children: [
              _RecentActivityCard(),
              SizedBox(height: 16),
              _SystemStatusCard(),
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _RecentActivityCard(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _SystemStatusCard(),
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

  const _StatCard({
    required this.item,
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
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

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

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

    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(
            'Son İşlemler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Sistemde gerçekleştirilen son hareketler.',
            style: Theme.of(context).textTheme.bodyMedium,
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.icon,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    activity.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
  const _SystemStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(
            'Sistem Durumu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          const _StatusRow(
            title: 'MongoDB',
            status: 'Bağlı',
            isActive: true,
          ),
          const SizedBox(height: 16),
          const _StatusRow(
            title: 'Spring Boot API',
            status: 'Çevrimdışı',
            isActive: false,
          ),
          const SizedBox(height: 16),
          const _StatusRow(
            title: 'Son yedekleme',
            status: 'Bugün 09:30',
            isActive: true,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Son güncelleme: 10 Temmuz 2026, 14:20',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

  const _StatusRow({
    required this.title,
    required this.status,
    required this.isActive,
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}