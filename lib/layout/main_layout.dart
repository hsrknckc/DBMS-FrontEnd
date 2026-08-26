import 'package:dmbs_frontend/features/audit_logs/audit_log_page.dart';
import 'package:dmbs_frontend/features/dashboard/dashboard_page.dart';
import '../features/databases/databases_page.dart';
import '../features/data_explorer/data_explorer_page.dart';
import '../features/data_type_explorer/data_type_explorer_page.dart';
import '../features/permissions/permissions_page.dart';
import 'package:dmbs_frontend/features/settings/settings_page.dart';
import 'package:dmbs_frontend/features/users/users_page.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';
import '../models/navigation_item.dart';


import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'user_profile_dialog.dart';
import 'logout_confirmation_dialog.dart';
import '../main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/controllers/auth_notifier.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  AppPage _selectedPage = AppPage.dashboard;
  bool _showSuperAdmin = true;

  // Profil bilgilerini dinamik yapabilmek için late değişken tanımladık
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
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
      case AppPage.dataTypeExplorer:
        return 'Data Type Explorer';
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    // Auth provider'dan mevcut kullanıcıyı dinliyoruz
    final userAsync = ref.watch(authNotifierProvider);
    final user = userAsync.valueOrNull;

    // Eğer henüz yüklenmemişse geçici boş bir model oluştur veya bekle
    final displayUser = user ?? const AppUser(
      id: '0', 
      name: 'Yükleniyor...', 
      email: '', 
      role: UserRole.superAdmin, 
      departments: {}, 
      permissions: {}, 
      isActive: true,
    );
    _currentUser = displayUser;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final Color backgroundStart =
        isDark ? const Color(0xFF050816) : const Color(0xFFF7FAFF);
    final Color backgroundMid =
        isDark ? const Color(0xFF07132B) : const Color(0xFFEEF5FF);
    final Color backgroundEnd =
        isDark ? const Color(0xFF12091F) : const Color(0xFFEAF7FB);

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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundStart,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [backgroundStart, backgroundMid, backgroundEnd],
                        stops: const [0, 0.58, 1],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _WorkspaceBackdropPainter(isDark: isDark),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 28.0 : 18.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildPageContent(textColor),
                        ),
                      ),
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
      case AppPage.dataTypeExplorer:
        return DataTypeExplorerPage(currentUser: _currentUser);
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

class _WorkspaceBackdropPainter extends CustomPainter {
  final bool isDark;

  const _WorkspaceBackdropPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (isDark ? AppColors.accent : AppColors.primary)
              .withValues(alpha: isDark ? 0.16 : 0.06),
          Colors.transparent,
          (isDark ? AppColors.violet : AppColors.accent)
              .withValues(alpha: isDark ? 0.12 : 0.05),
        ],
      ).createShader(Offset.zero & size);
    final sweepPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.72, 0)
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width * 0.34, size.height)
      ..lineTo(0, size.height * 0.34)
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);


    final veilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.025 : 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    final veilPath = Path()
      ..moveTo(size.width * 0.58, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width * 0.74, size.height)
      ..close();
    canvas.drawPath(veilPath, veilPaint);
  }

  @override
  bool shouldRepaint(covariant _WorkspaceBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
