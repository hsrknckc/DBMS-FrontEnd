import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../main.dart';
import '../models/app_user.dart';

class AppTopBar extends StatelessWidget {
  final String pageTitle;
  final bool isSuperAdminMode;
  final ValueChanged<bool> onRoleChanged;
  final AppUser currentUser;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoutPressed;

  const AppTopBar({
    super.key,
    required this.pageTitle,
    required this.isSuperAdminMode,
    required this.onRoleChanged,
    required this.currentUser,
    this.onProfilePressed,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
    final surface = isDark ? const Color(0xFF0D0F14) : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.98),
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    _pageIcon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _pageSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(
            icon: Icons.verified_user_outlined,
            label: isSuperAdminMode ? 'Super Admin' : 'User Mode',
            color: isSuperAdminMode
                ? (isDark ? AppColors.warning : AppColors.accent)
                : AppColors.primary,
          ),
          const SizedBox(width: 10),
          _ThemeToggle(isDark: isDark),
          const SizedBox(width: 10),
          _buildNotificationButton(context, textColor),
          const SizedBox(width: 12),
          _buildProfileMenu(context, textColor, subTextColor),
        ],
      ),
    );
  }

  IconData get _pageIcon {
    switch (pageTitle) {
      case 'Dashboard':
        return Icons.dashboard_customize_outlined;
      case 'Databases':
        return Icons.storage_outlined;
      case 'Data Explorer':
        return Icons.table_chart_outlined;
      case 'Data Type Explorer':
        return Icons.schema_outlined;
      case 'Users':
        return Icons.group_outlined;
      case 'Permissions':
        return Icons.admin_panel_settings_outlined;
      case 'Audit Logs':
        return Icons.manage_history_outlined;
      case 'Settings':
        return Icons.tune_outlined;
      default:
        return Icons.dns_outlined;
    }
  }

  String get _pageSubtitle {
    switch (pageTitle) {
      case 'Dashboard':
        return 'Operational overview and system health';
      case 'Databases':
        return 'Manage database definitions and lifecycle';
      case 'Data Explorer':
        return 'Browse, filter and operate on records';
      case 'Data Type Explorer':
        return 'Define schema and field contracts';
      case 'Users':
        return 'Create, recover and manage accounts';
      case 'Permissions':
        return 'Control scoped access and action rights';
      case 'Audit Logs':
        return 'Trace activity, changes and recovery actions';
      case 'Settings':
        return 'Workspace preferences and environment controls';
      default:
        return 'Database management console';
    }
  }

  Widget _buildNotificationButton(BuildContext context, Color iconColor) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 46),
      tooltip: 'Bildirimler',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          _TopIconButtonFrame(
            child: Icon(Icons.notifications_none_rounded, color: iconColor),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          enabled: false,
          child: Text(
            'Bildirimler',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Veritabanı bağlantısı aktif.')),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        _showSnackBar(context, 'Bildirim seçildi: #$value');
      },
    );
  }

  Widget _buildProfileMenu(
    BuildContext context,
    Color textColor,
    Color subTextColor,
  ) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 52),
      tooltip: 'Profil menüsü',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 42,
          padding: const EdgeInsets.only(left: 6, right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF151922)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.18
                      : 0.045,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.warning.withValues(alpha: 0.14)
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.warning.withValues(alpha: 0.34)
                        : AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  currentUser.initials,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.warning
                        : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  currentUser.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more_rounded, color: subTextColor, size: 19),
            ],
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                currentUser.email,
                style: TextStyle(fontSize: 11, color: subTextColor),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18),
              SizedBox(width: 10),
              Text('Profil Bilgilerim'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
              SizedBox(width: 10),
              Text('Çıkış Yap', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          onProfilePressed?.call();
        } else if (value == 2) {
          onLogoutPressed?.call();
        }
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;

  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDark ? 'Aydınlık moda geç' : 'Gece moduna geç',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => DatabaseManagementApp.of(context)?.toggleTheme(!isDark),
        child: _TopIconButtonFrame(
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: isDark ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TopIconButtonFrame extends StatelessWidget {
  final Widget child;

  const _TopIconButtonFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
