import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../main.dart'; // DatabaseManagementApp'e erişmek için ekledik
import '../models/app_user.dart';
import '../models/navigation_item.dart';
import 'logout_confirmation_dialog.dart';

class AppSidebar extends StatelessWidget {
  final AppPage selectedPage;
  final ValueChanged<AppPage> onPageSelected;
  final AppUser currentUser;

  const AppSidebar({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.currentUser, required void Function() onProfilePressed, required Null Function() onLogoPressed,
  });

  static const List<NavigationItem> superAdminItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      page: AppPage.dashboard,
    ),
    NavigationItem(
      title: 'Databases',
      icon: Icons.storage_outlined,
      page: AppPage.databases,
    ),
    NavigationItem(
      title: 'Data Explorer',
      icon: Icons.table_chart_outlined,
      page: AppPage.dataExplorer,
    ),
    NavigationItem(
      title: 'Data Type Explorer',
      icon: Icons.schema_outlined,
      page: AppPage.dataTypeExplorer,
    ),
    NavigationItem(
      title: 'Users',
      icon: Icons.people_outline,
      page: AppPage.users,
    ),
    NavigationItem(
      title: 'Permissions',
      icon: Icons.admin_panel_settings_outlined,
      page: AppPage.permissions,
    ),
    NavigationItem(
      title: 'Audit Logs',
      icon: Icons.history_outlined,
      page: AppPage.auditLogs,
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      page: AppPage.settings,
    ),
  ];

  static const List<NavigationItem> userItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      page: AppPage.dashboard,
    ),
    NavigationItem(
      title: 'Databases',
      icon: Icons.storage_outlined,
      page: AppPage.databases,
    ),
    NavigationItem(
      title: 'Data Explorer',
      icon: Icons.table_chart_outlined,
      page: AppPage.dataExplorer,
    ),
    NavigationItem(
      title: 'Data Type Explorer',
      icon: Icons.schema_outlined,
      page: AppPage.dataTypeExplorer,
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      page: AppPage.settings,
    ),
  ];

  List<NavigationItem> get navigationItems {
    if (currentUser.isSuperAdmin) {
      return superAdminItems;
    }

    return userItems;
  }

  @override
  Widget build(BuildContext context) {
    final items = navigationItems;
    final theme = Theme.of(context);
    
    // main.dart'ta tanımladığımız state'ten genişlik bilgisini alıyoruz
    final appState = DatabaseManagementApp.of(context);
    final isCompact = appState?.isCompactSidebar ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Daralırken/açılırken akıcı geçiş sağlar
      width: isCompact ? 76 : 260,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogoArea(context, isCompact),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: 18,
              ),
              itemCount: items.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 6);
              },
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedPage == item.page;

                return _SidebarMenuItem(
                  item: item,
                  isSelected: isSelected,
                  isCompact: isCompact, // Butonların kendini küçültmesi için paslıyoruz
                  onTap: () {
                    onPageSelected(item.page);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildUserArea(context, isCompact),
        ],
      ),
    );
  }

  Widget _buildLogoArea(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 80,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
        child: Row(
          mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                child: Icon(
                  Icons.storage_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            // Eğer sidebar daraltılmışsa "Data Manager" yazısını gizle
            if (!isCompact) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data Manager',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.titleMedium?.color ?? AppColors.textPrimary,
                  ),
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
    
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 16),
      child: Row(
        mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.scaffoldBackgroundColor,
            child: Text(
              currentUser.initials,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Daraltılmış modda kullanıcı detaylarını ve çıkış butonunu gizle/düzenle
          if (!isCompact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentUser.roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                    ),
                  ),
                ],
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
              icon: Icon(
                Icons.logout,
                size: 20,
                color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isCompact; // Menü elemanının dar olup olmadığı bilgisi
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          // Menü daraldığında ikonun üzerine gelince ne olduğunu gösterir
          message: isCompact ? item.title : '',
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 0 : 14,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 21,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                ),
                // Eğer menü daralmışsa metin alanını tamamen kaldır
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}