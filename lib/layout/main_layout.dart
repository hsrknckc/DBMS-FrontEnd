import 'package:flutter/material.dart';

import '../core/widgets/placeholder_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';
import '../models/permission.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  AppPage _selectedPage = AppPage.dashboard;
  bool _showSuperAdmin = true;

  AppUser get _currentUser {
    if (_showSuperAdmin) {
      return AppUser(
        id: 'super-admin-1',
        name: 'Ayşe Yılmaz',
        email: 'ayse@company.com',
        department: 'System Management',
        role: UserRole.superAdmin,
        permissions: Permission.values.toSet(),
        isActive: true,
        lastLoginAt: DateTime(2026, 7, 10, 9, 12),
        lastLogoutAt: DateTime(2026, 7, 9, 17, 48),
      );
    }

    return const AppUser(
      id: 'user-1',
      name: 'Mehmet Kaya',
      email: 'mehmet@company.com',
      department: 'Sensor',
      role: UserRole.user,
      permissions: {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: false,
    );
  }

  void _changePage(AppPage page) {
    if (!_canAccessPage(page)) {
      return;
    }

    setState(() {
      _selectedPage = page;
    });
  }

  void _changeRole(bool showSuperAdmin) {
    setState(() {
      _showSuperAdmin = showSuperAdmin;
      _selectedPage = AppPage.dashboard;
    });
  }

  bool _canAccessPage(AppPage page) {
    if (_currentUser.isSuperAdmin) {
      return true;
    }

    const restrictedPages = {
      AppPage.users,
      AppPage.rolesPermissions,
      AppPage.auditLogs,
    };

    return !restrictedPages.contains(page);
  }

  String get _currentPageTitle {
    switch (_selectedPage) {
      case AppPage.dashboard:
        return 'Dashboard';

      case AppPage.databases:
        return 'Databases';

      case AppPage.dataExplorer:
        return 'Data Explorer';

      case AppPage.users:
        return 'Users';

      case AppPage.rolesPermissions:
        return 'Roles & Permissions';

      case AppPage.auditLogs:
        return 'Audit Logs';

      case AppPage.settings:
        return 'Settings';
    }
  }

  Widget get _currentPage {
    switch (_selectedPage) {
      case AppPage.dashboard:
        return const DashboardPage();

      case AppPage.databases:
        return const PlaceholderPage(
          title: 'Databases',
          description:
              'Database oluşturma, görüntüleme ve yönetim işlemleri burada yapılacak.',
          icon: Icons.storage_outlined,
        );

      case AppPage.dataExplorer:
        return const PlaceholderPage(
          title: 'Data Explorer',
          description:
              'Veriler Excel benzeri bir tablo üzerinde burada görüntülenecek.',
          icon: Icons.table_chart_outlined,
        );

      case AppPage.users:
        return const PlaceholderPage(
          title: 'Users',
          description:
              'Kullanıcı bilgileri, durumları, son giriş ve çıkış zamanları burada gösterilecek.',
          icon: Icons.people_outline,
        );

      case AppPage.rolesPermissions:
        return const PlaceholderPage(
          title: 'Roles & Permissions',
          description:
              'Super Admin, kullanıcıların yetkilerini burada seçerek düzenleyecek.',
          icon: Icons.admin_panel_settings_outlined,
        );

      case AppPage.auditLogs:
        return const PlaceholderPage(
          title: 'Audit Logs',
          description:
              'Kullanıcı ve sistem hareketleri burada görüntülenecek.',
          icon: Icons.history_outlined,
        );

      case AppPage.settings:
        return const PlaceholderPage(
          title: 'Settings',
          description:
              'Hesap ve uygulama ayarları burada yönetilecek.',
          icon: Icons.settings_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedPage: _selectedPage,
            onPageSelected: _changePage,
            currentUser: currentUser,
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  pageTitle: _currentPageTitle,
                  currentUser: currentUser,
                  isSuperAdminMode: _showSuperAdmin,
                  onRoleChanged: _changeRole,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _currentPage,
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