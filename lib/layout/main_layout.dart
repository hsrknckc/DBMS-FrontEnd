import 'package:flutter/material.dart';
import '../features/users/users_page.dart';
import '../core/widgets/placeholder_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';
import '../models/permission.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import '../features/permissions/permissions_page.dart';
import '../features/audit_logs/audit_log_page.dart';
import '../features/databases/databases_page.dart';
import '../features/data_explorer/data_explorer_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  AppPage _selectedPage = AppPage.dashboard;

  /// false yapılırsa uygulama User olarak başlar.
  /// true yapılırsa Super Admin olarak başlar.
  bool _showSuperAdmin = true;

  AppUser get _currentUser {
    if (_showSuperAdmin) {
      return AppUser(
        id: 'super-admin-1',
        name: 'Ayşe Yılmaz',
        email: 'ayse@company.com',
        role: UserRole.superAdmin,
        departments: const {},
        permissions: Permission.values.toSet(),
        isActive: true,
        lastLoginAt: DateTime(2026, 7, 15, 9, 12),
        lastLogoutAt: DateTime(2026, 7, 14, 17, 48),
      );
    }

    return AppUser(
      id: 'user-1',
      name: 'Mehmet Kaya',
      email: 'mehmet@company.com',
      role: UserRole.user,
      departments: const {'Sensor', 'Signal'},
      permissions: const {
        Permission.databaseView,
        Permission.dataView,
        Permission.dataExport,
      },
      isActive: true,
      lastLoginAt: DateTime(2026, 7, 15, 8, 45),
      lastLogoutAt: DateTime(2026, 7, 14, 17, 20),
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
      AppPage.permissions,
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

      case AppPage.permissions:
        return 'Permissions';

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
        return DatabasesPage(currentUser: _currentUser);

      case AppPage.dataExplorer:
        return DataExplorerPage(
        currentUser: _currentUser,
        );
        
      case AppPage.users:
        return const UsersPage();

      case AppPage.permissions:
        return const PermissionsPage();

      case AppPage.auditLogs:
        return const AuditLogsPage();

      case AppPage.settings:
        return const PlaceholderPage(
          title: 'Settings',
          description: 'Hesap ve uygulama ayarları burada yönetilecek.',
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
