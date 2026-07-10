import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';

class AppSidebar extends StatelessWidget {
  final AppPage selectedPage;
  final ValueChanged<AppPage> onPageSelected;
  final AppUser currentUser;

  const AppSidebar({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.currentUser,
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
      title: 'Users',
      icon: Icons.people_outline,
      page: AppPage.users,
    ),
    NavigationItem(
      title: 'Roles & Permissions',
      icon: Icons.admin_panel_settings_outlined,
      page: AppPage.rolesPermissions,
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
      title: 'Settings',
      icon: Icons.settings_outlined,
      page: AppPage.settings,
    ),
  ];

  List<NavigationItem> get navigationItems {
    return currentUser.isSuperAdmin ? superAdminItems : userItems;
  }

  @override
  Widget build(BuildContext context) {
    final items = navigationItems;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogoArea(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
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
                  onTap: () {
                    onPageSelected(item.page);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildUserArea(),
        ],
      ),
    );
  }

  Widget _buildLogoArea() {
    return const SizedBox(
      height: 80,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data Manager',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.background,
            child: Text(
              currentUser.initials,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentUser.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: () {},
            icon: const Icon(
              Icons.logout,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 21,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}