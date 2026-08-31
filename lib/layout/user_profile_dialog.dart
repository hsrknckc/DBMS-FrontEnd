import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class UserProfileDialog extends StatefulWidget {
  final AppUser user;

  const UserProfileDialog({
    super.key,
    required this.user,
  });

  static void show(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 24,
        backgroundColor: isDark ? const Color(0xFF0C1224) : Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: UserProfileDialog(user: user),
          ),
        ),
      ),
    );
  }

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  bool _isLoading = false;
  bool _isSuccess = false;

  void _sendPasswordChangeRequest() {
    setState(() {
      _isLoading = true;
    });

    // Simulating API network call
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final Color dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final Color cardColor = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : const Color(0xFFF8FAFC);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Üst Tasarım Alanı (Header Banner)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101A33) : primaryColor,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // 2. Profil Resmi ve Temel Bilgiler
          Transform.translate(
            offset: const Offset(0, -45),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0C1224) : Colors.white,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor:
                        isDark ? const Color(0xFF17213A) : const Color(0xFFE2E8F0),
                    child: Text(
                      widget.user.initials,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),

          // 3. İçerik & Detay Kartı
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Column(
              children: [
                // Bilgiler Bölümü
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: dividerColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context: context,
                        icon: Icons.badge_outlined,
                        label: 'Kullanıcı ID',
                        value: '#${widget.user.id}',
                        isDark: isDark,
                      ),
                      Divider(color: dividerColor, height: 24),
                      _buildDetailRow(
                        context: context,
                        icon: Icons.shield_outlined,
                        label: 'Erişim Rolü',
                        valueWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.user.roleLabel,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      Divider(color: dividerColor, height: 24),
                      _buildDetailRow(
                        context: context,
                        icon: Icons.business_outlined,
                        label: 'Departmanlar',
                        value: widget.user.departmentLabel,
                        isDark: isDark,
                      ),
                      Divider(color: dividerColor, height: 24),
                      _buildDetailRow(
                        context: context,
                        icon: Icons.check_circle_outline,
                        label: 'Hesap Durumu',
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Aktif Kullanıcı',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Şifre Değiştirme / İstek Alanı
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildActionArea(isDark, primaryColor, textColor, subTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(bool isDark, Color primaryColor, Color textColor, Color subTextColor) {
    if (_isSuccess) {
      return Container(
        key: const ValueKey('success'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Talep Başarıyla İletildi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Şifre sıfırlama ve güncelleme yönergeleri sisteme kayıtlı e-posta adresinize gönderilmiştir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Şifre değişiklik talebi gönderiliyor...',
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('button'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _sendPasswordChangeRequest,
          icon: const Icon(Icons.lock_reset, color: Colors.white),
          label: const Text(
            'Şifre Değişikliği Talebi Gönder',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    required bool isDark,
  }) {
    final Color labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color valColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 14),
        if (valueWidget != null)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          )
        else if (value != null)
          Expanded(
            child: Tooltip(
              message: value,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
