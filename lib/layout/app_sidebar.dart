import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';
import 'logout_confirmation_dialog.dart';

class AppSidebar extends StatefulWidget {
  final AppPage selectedPage;
  final ValueChanged<AppPage> onPageSelected;
  final AppUser currentUser;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoPressed;

  const AppSidebar({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.currentUser,
    this.onProfilePressed,
    this.onLogoPressed,
  });

  static const List<NavigationItem> superAdminItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.space_dashboard_rounded,
      page: AppPage.dashboard,
    ),
    NavigationItem(
      title: 'Databases',
      icon: Icons.dns_rounded,
      page: AppPage.databases,
    ),
    NavigationItem(
      title: 'Data Explorer',
      icon: Icons.table_view_rounded,
      page: AppPage.dataExplorer,
    ),
    NavigationItem(
      title: 'Data Type Explorer',
      icon: Icons.account_tree_rounded,
      page: AppPage.dataTypeExplorer,
    ),
    NavigationItem(
      title: 'Users',
      icon: Icons.group_rounded,
      page: AppPage.users,
    ),
    NavigationItem(
      title: 'Permissions',
      icon: Icons.enhanced_encryption_rounded,
      page: AppPage.permissions,
    ),
    NavigationItem(
      title: 'Audit Logs',
      icon: Icons.manage_history_rounded,
      page: AppPage.auditLogs,
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.tune_rounded,
      page: AppPage.settings,
    ),
  ];

  static const List<NavigationItem> userItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.space_dashboard_rounded,
      page: AppPage.dashboard,
    ),
    NavigationItem(
      title: 'Databases',
      icon: Icons.dns_rounded,
      page: AppPage.databases,
    ),
    NavigationItem(
      title: 'Data Explorer',
      icon: Icons.table_view_rounded,
      page: AppPage.dataExplorer,
    ),
    NavigationItem(
      title: 'Data Type Explorer',
      icon: Icons.account_tree_rounded,
      page: AppPage.dataTypeExplorer,
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.tune_rounded,
      page: AppPage.settings,
    ),
  ];

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isHovered = false;

  List<NavigationItem> get _navigationItems {
    return widget.currentUser.isSuperAdmin
        ? AppSidebar.superAdminItems
        : AppSidebar.userItems;
  }

  @override
  Widget build(BuildContext context) {
    final appState = DatabaseManagementApp.of(context);
    final compactPreference = appState?.isCompactSidebar ?? false;
    final isCompact = compactPreference && !_isHovered;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: isCompact ? 78 : 292,
        decoration: BoxDecoration(
          color: surface,
          border: Border(right: BorderSide(color: border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
              blurRadius: 30,
              offset: const Offset(10, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildLogoArea(context, isCompact),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 10 : 16,
                  12,
                  isCompact ? 10 : 16,
                  12,
                ),
                itemCount: _navigationItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  return _SidebarMenuItem(
                    item: item,
                    isSelected: widget.selectedPage == item.page,
                    isCompact: isCompact,
                    onTap: () => widget.onPageSelected(item.page),
                  );
                },
              ),
            ),
            _buildUserArea(context, isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    return InkWell(
      onTap: widget.onLogoPressed,
      child: Container(
        height: 104,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 18),
        child: Row(
          mainAxisAlignment:
              isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dns_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Manager',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Secure DB Console',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserArea(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
    final panel = isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 10 : 16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: panel,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment:
              isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onProfilePressed,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.accent.withValues(alpha: 0.95),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.currentUser.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: widget.onProfilePressed,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentUser.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.currentUser.roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Çıkış yap',
                onPressed: () {
                  LogoutConfirmationDialog.show(
                    context,
                    onConfirm: () {
                      DatabaseManagementApp.of(context)?.logout();
                    },
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                color: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.warning : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final selectedBg =
        isDark ? activeColor.withValues(alpha: 0.16) : activeColor.withValues(alpha: 0.10);
    final hoverBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.isSelected ? selectedBg : (_hovered ? hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.24)
                : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Tooltip(
              message: widget.isCompact ? widget.item.title : '',
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 0 : 13,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisAlignment: widget.isCompact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? activeColor.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.item.icon,
                        size: 20,
                        color: widget.isSelected ? activeColor : textColor,
                      ),
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: widget.isSelected ? activeColor : textColor,
                          ),
                        ),
                      ),
                      if (widget.isSelected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
