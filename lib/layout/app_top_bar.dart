import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class AppTopBar extends StatelessWidget {
  final String pageTitle;
  final bool isSuperAdminMode;
  final ValueChanged<bool> onRoleChanged;
  final AppUser currentUser;

  // Profil Bilgilerim ve Çıkış Yap aksiyonları için callback'ler
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

    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sol taraf boş bırakıldı (Başlık ve arama çubuğu kaldırıldı)
          const Spacer(),

          // Sağ Taraf: Bildirimler ve Profil
          Row(
            children: [
              // Aktif Bildirim Butonu
              _buildNotificationButton(context, textColor),
              const SizedBox(width: 16),

              // Dikey Ayraç
              Container(
                height: 24,
                width: 1,
                color: theme.dividerColor,
              ),
              const SizedBox(width: 16),

              // Aktif Profil Menüsü
              _buildProfileMenu(context, textColor, subTextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, Color iconColor) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: iconColor,
            size: 24,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 4, height: 4),
            ),
          ),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Bildirimler',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.backup_outlined, color: AppColors.success, size: 20),
              SizedBox(width: 8),
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

  Widget _buildProfileMenu(BuildContext context, Color textColor, Color subTextColor) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                currentUser.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              currentUser.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: subTextColor,
            ),
          ],
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                currentUser.email,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 8),
              Text('Profil Bilgilerim'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.logout, color: AppColors.danger, size: 18),
              SizedBox(width: 8),
              Text('Çıkış Yap', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          if (onProfilePressed != null) {
            onProfilePressed!();
          } else {
            _showSnackBar(context, 'Profil menüsü tıklandı.');
          }
        } else if (value == 2) {
          if (onLogoutPressed != null) {
            onLogoutPressed!();
          } else {
            _showSnackBar(context, 'Çıkış yapıldı.');
          }
        }
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}