import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../databases/controllers/databases_notifier.dart';
import '../users/controllers/users_notifier.dart';

class DashboardPage extends ConsumerWidget {
  final AppUser? currentUser;

  const DashboardPage({super.key, this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dbs = ref.watch(databasesProvider).valueOrNull ?? [];
    final users = ref.watch(usersProvider).valueOrNull ?? [];

    var totalCollections = 0;
    var totalRecords = 0;
    for (final db in dbs) {
      totalCollections += db.collectionCount;
      totalRecords += db.recordCount;
    }

    final activeUsers = users.where((user) => user.isActive).length;
    final stats = [
      _StatItem('Databases', dbs.length.toString(), Icons.dns_rounded),
      _StatItem('Collections', totalCollections.toString(), Icons.folder_rounded),
      _StatItem('Records', totalRecords.toString(), Icons.view_list_rounded),
      _StatItem('Active Users', activeUsers.toString(), Icons.groups_rounded),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPanel(
            userName: currentUser?.name ?? 'Kullanıcı',
            stats: stats,
            isDark: isDark,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1050;
              if (isNarrow) {
                return Column(
                  children: [
                    _OperationsPanel(isDark: isDark),
                    const SizedBox(height: 18),
                    _SystemPanel(isDark: isDark),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _OperationsPanel(isDark: isDark)),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: _SystemPanel(isDark: isDark)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String userName;
  final List<_StatItem> stats;
  final bool isDark;

  const _HeroPanel({
    required this.userName,
    required this.stats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelColor =
        isDark ? Colors.white.withValues(alpha: 0.055) : const Color(0xF7FFFFFF);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD8E0EA);
    final accent = isDark ? AppColors.accent : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.violet : Colors.black)
                .withValues(alpha: isDark ? 0.16 : 0.07),
            blurRadius: 38,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CircuitPainter(isDark))),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(
                              label: 'DATABASE COMMAND CENTER',
                              color: accent,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Hoş geldiniz, $userName',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Text(
                                'Database, collection ve kullanıcı hareketlerini tek merkezden izleyin.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SignalBadge(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      if (compact) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: stats
                              .map((item) => SizedBox(
                                    width: 210,
                                    child: _MetricTile(item: item, isDark: isDark),
                                  ))
                              .toList(),
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            Expanded(
                              child: _MetricTile(item: stats[i], isDark: isDark),
                            ),
                            if (i != stats.length - 1) const SizedBox(width: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _StatItem item;
  final bool isDark;

  const _MetricTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColors.primary;
    return Container(
      height: 104,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDCE3EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: accent, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
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

class _OperationsPanel extends StatelessWidget {
  final bool isDark;

  const _OperationsPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      isDark: isDark,
      title: 'Son Hareketler',
      icon: Icons.timeline_rounded,
      child: SizedBox(
        height: 245,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radar_rounded,
                size: 42,
                color: (isDark ? AppColors.accent : AppColors.primary)
                    .withValues(alpha: 0.72),
              ),
              const SizedBox(height: 12),
              Text(
                'Henüz hareket kaydı yok',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemPanel extends StatelessWidget {
  final bool isDark;

  const _SystemPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      isDark: isDark,
      title: 'Sistem Durumu',
      icon: Icons.health_and_safety_rounded,
      child: Column(
        children: [
          _StatusRow(
            label: 'TCP Soket Bağlantısı',
            value: 'Aktif',
            icon: Icons.settings_input_antenna_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'MongoDB Servisi',
            value: 'Bağlı',
            icon: Icons.dataset_linked_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: CustomPaint(
              painter: _MiniGraphPainter(isDark),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Widget child;

  const _PanelShell({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.055) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD8E0EA),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.accent : Colors.black)
                .withValues(alpha: isDark ? 0.12 : 0.055),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 26, height: 2, color: color),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SignalBadge extends StatelessWidget {
  final bool isDark;

  const _SignalBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.accent : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            'LIVE',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;

  const _StatItem(this.title, this.value, this.icon);
}

class _CircuitPainter extends CustomPainter {
  final bool isDark;

  const _CircuitPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (isDark ? AppColors.accent : AppColors.primary)
          .withValues(alpha: isDark ? 0.13 : 0.07);

    for (var i = 0; i < 8; i++) {
      final y = 28.0 + i * 28;
      final startX = size.width * 0.58 + (i.isEven ? 0 : 34);
      canvas.drawLine(Offset(startX, y), Offset(size.width - 36, y), paint);
      canvas.drawCircle(Offset(startX, y), 2.5, paint);
      canvas.drawCircle(Offset(size.width - 36, y), 2.5, paint);
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? AppColors.accent : AppColors.accent)
          .withValues(alpha: isDark ? 0.10 : 0.08);

    final path = Path()
      ..moveTo(size.width * 0.70, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.82, size.height)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _MiniGraphPainter extends CustomPainter {
  final bool isDark;

  const _MiniGraphPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = (isDark ? Colors.white : AppColors.textSecondary)
          .withValues(alpha: isDark ? 0.055 : 0.09)
      ..strokeWidth = 1;
    for (double x = 14; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final line = Paint()
      ..color = isDark ? AppColors.accent : AppColors.primary
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(14, size.height * 0.68)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.22,
        size.width * 0.42,
        size.height * 0.82,
        size.width * 0.62,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.12,
        size.width * 0.86,
        size.height * 0.48,
        size.width - 14,
        size.height * 0.24,
      );
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MiniGraphPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
