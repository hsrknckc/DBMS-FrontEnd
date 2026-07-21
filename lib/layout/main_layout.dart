import 'package:dmbs_frontend/features/audit_logs/audit_log_page.dart';
import 'package:dmbs_frontend/features/dashboard/dashboard_page.dart';
import 'package:dmbs_frontend/features/data_explorer/data_explorer_page.dart';
import 'package:dmbs_frontend/features/databases/databases_page.dart';
import 'package:dmbs_frontend/features/permissions/permissions_page.dart';
import 'package:dmbs_frontend/features/settings/settings_page.dart';
import 'package:dmbs_frontend/features/users/users_page.dart';
import 'package:dmbs_frontend/models/permission.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';


import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'user_profile_dialog.dart';
import 'logout_confirmation_dialog.dart';
import '../main.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  AppPage _selectedPage = AppPage.dashboard;
  bool _showSuperAdmin = true;

  // Profil bilgilerini dinamik yapabilmek için late değişken tanımladık
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
    // İlk başlangıç verileri
    _currentUser = const AppUser(
      id: '1',
      name: 'Ahmet Yılmaz',
      email: 'ahmet.yilmaz@company.com',
      role: UserRole.superAdmin,
      departments: <String>{'IT', 'Database Admin'},
      permissions: <Permission>{},
      isActive: true,
    );
  }

  // Profil bilgilerini içeride güncelleyen metod
  void _updateProfile({required String newName, required String newEmail}) {
    setState(() {
      _currentUser = AppUser(
        id: _currentUser.id,
        name: newName,
        email: newEmail,
        role: _currentUser.role,
        departments: _currentUser.departments,
        permissions: _currentUser.permissions,
        isActive: _currentUser.isActive,
      );
    });
  }

  // Şık alt profil düzenleme ekranı (BottomSheet)
  void _showEditProfileBottomSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController(text: _currentUser.name);
    final emailController = TextEditingController(text: _currentUser.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Klavyenin üstüne taşır
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil Bilgilerini Düzenle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal', style: TextStyle(color: AppColors.danger)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _updateProfile(
                        newName: nameController.text,
                        newEmail: emailController.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil başarıyla güncellendi!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
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

  void _changePage(AppPage page) {
    setState(() {
      _selectedPage = page;
    });
  }

  void _changeRole(bool isSuperAdmin) {
    setState(() {
      _showSuperAdmin = isSuperAdmin;
      _currentUser = _currentUser.copyWith(
        role: isSuperAdmin ? UserRole.superAdmin : UserRole.user,
      );
      if (!isSuperAdmin) {
        if (_selectedPage == AppPage.users ||
            _selectedPage == AppPage.permissions ||
            _selectedPage == AppPage.auditLogs) {
          _selectedPage = AppPage.dashboard;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sol Sidebar
          AppSidebar(
            selectedPage: _selectedPage,
            onPageSelected: _changePage,
            currentUser: _currentUser,
            // Buraya tetikleyicileri ekledik. app_sidebar.dart dosyasında constructor'a ekleyebilirsin:
            // final VoidCallback? onProfilePressed; gibi.
            onProfilePressed: () => _showEditProfileBottomSheet(context, isDark),
            onLogoPressed: () {
              // Logo/Sol üst tıklandığında istersen menüyü daraltabilir ya da dashboard'a yollayabilirsin:
              _changePage(AppPage.dashboard);
            },
          ),

          // Sağ İçerik Alanı
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  pageTitle: _currentPageTitle,
                  isSuperAdminMode: _showSuperAdmin,
                  onRoleChanged: _changeRole,
                  currentUser: _currentUser,
                  onProfilePressed: () => UserProfileDialog.show(context, _currentUser),
                  onLogoutPressed: () {
                    LogoutConfirmationDialog.show(
                      context,
                      onConfirm: () {
                        DatabaseManagementApp.of(context)?.logout();
                      },
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _buildPageContent(textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(Color textColor) {
    // Tüm sayfalara güncel profil yansıyabilsin diye 'const' yapılarını tamamen kaldırdık.
    switch (_selectedPage) {
      case AppPage.dashboard:
        return const DashboardPage();
      case AppPage.databases:
        return DatabasesPage(currentUser: _currentUser);
      case AppPage.dataExplorer:
        return DataExplorerPage(currentUser: _currentUser);
      case AppPage.users:
        return const UsersPage();
      case AppPage.permissions:
        return const PermissionsPage();
      case AppPage.auditLogs:
        return const AuditLogsPage();
      case AppPage.settings:
        return const SettingsPage();
    }
  }
}