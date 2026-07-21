import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class AppTopBar extends StatelessWidget {
  final String pageTitle;
  final bool isSuperAdminMode;
  final ValueChanged<bool> onRoleChanged;
  final AppUser currentUser;

  // Profil Bilgilerim ve Çıkış Yap aksiyonları için callback'ler eklendi
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

    // Yazı renklerini garanti altına alıyoruz (Çakışmaları önlemek için)
    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      height: 90, // Yüksekliği 80'den 90'a çıkararak sıkışıklığı giderdik
      padding: const EdgeInsets.symmetric(horizontal: 28), // İç boşlukları genişlettik
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
          // 1. Sol Taraf: Sayfa Başlığı
          Text(
            pageTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24, // Başlığı biraz daha büyüttük
              color: textColor,
            ),
          ),
          const SizedBox(width: 48), // Başlık ile arama çubuğu arası boşluğu artırdık

          // 2. Orta: Aktif Arama Çubuğu
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 450, // Arama çubuğunu biraz daha genişlettik
                height: 48, // Sıkışıklığı gidermek için yüksekliği artırdık
                child: TextField(
                  style: TextStyle(color: textColor, fontSize: 14), // Yazı rengini düzelttik
                  onSubmitted: (value) {
                    _showSnackBar(context, 'Aranan kelime: "$value"');
                  },
                  decoration: InputDecoration(
                    hintText: 'Hızlı arama yapın...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Sağ Taraf: Rol Değiştirici, Bildirimler ve Profil
          Row(
            children: [
              // Süper Admin Modu Switch/Chip
              Text(
                'Super Admin:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isSuperAdminMode,
                activeColor: AppColors.primary,
                onChanged: onRoleChanged,
              ),
              const SizedBox(width: 24), // Boşlukları rahatlattık
              
              // Dikey Ayraç
              Container(
                height: 28,
                width: 1,
                color: theme.dividerColor,
              ),
              const SizedBox(width: 24),

              // Aktif Bildirim Butonu
              _buildNotificationButton(context, textColor),
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
            size: 26,
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
              Expanded(child: Text('Veritabanı yedekleme işlemi başarıyla tamamlandı.')),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Yeni bir IP adresinden giriş denemesi yapıldı.')),
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
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                currentUser.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentUser.name,
              style: TextStyle(
                fontSize: 15,
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
          // Profil Bilgilerim seçildiğinde dışarıya haber verir
          if (onProfilePressed != null) {
            onProfilePressed!();
          } else {
          
            _showSnackBar(context, 'Profil menüsü tıklandı.');
          }
        } else if (value == 2) {
          // Çıkış Yap seçildiğinde dışarıya haber verir
          if (onLogoutPressed != null) {
            onLogoutPressed!();
          } else {
            _showSnackBar(context, 'Çıkış yapıldı! (Simüle Edildi)');
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