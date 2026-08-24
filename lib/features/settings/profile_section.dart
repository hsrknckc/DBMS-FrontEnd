import 'package:flutter/material.dart';
import '../../../models/app_user.dart';

class ProfileSection extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onEditProfile;

  const ProfileSection({
    super.key,
    this.currentUser,
    this.onEditProfile,
  });

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordChange() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simüle edilmiş API isteği
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _isLoading = false);

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dinamik Tema Renkleri
    final Color boxBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color inputBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final userName = widget.currentUser?.name ?? 'Ahmet Yılmaz';
    final userEmail = widget.currentUser?.email ?? 'ahmet.yilmaz@company.com';
    final userRole = widget.currentUser?.role.name.toUpperCase() ?? 'SUPER ADMIN';
    final isActive = widget.currentUser?.isActive ?? true;

    final initials = userName.isNotEmpty
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Profil Bilgileri & Güvenlik',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hesap bilgilerinizi görüntüleyin ve şifre değişiklik talebinizi iletin.',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // 1. KART: ÖZET VE KİŞİSEL BİLGİLER
          Container(
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Profil Üst Bilgi
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Durum Rozeti
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Pasif',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(userEmail, style: TextStyle(color: subtitleColor, fontSize: 14)),
                          ],
                        ),
                      ),
                      if (widget.onEditProfile != null)
                        OutlinedButton.icon(
                          onPressed: widget.onEditProfile,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Düzenle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ),

                Divider(color: borderColor, height: 1),

                // Bilgi Satırları
                _buildInfoRow(Icons.security, 'Erişim Rolü', userRole, titleColor, subtitleColor),
                Divider(color: borderColor, height: 1),
                _buildInfoRow(
                  Icons.business,
                  'Departmanlar',
                  widget.currentUser?.departments.join(', ') ?? 'Yazılım & Veritabanı',
                  titleColor,
                  subtitleColor,
                ),
                Divider(color: borderColor, height: 1),
                _buildInfoRow(Icons.access_time, 'Son Giriş', 'Bugün 09:15', titleColor, subtitleColor),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 2. KART: ŞİFRE DEĞİŞİKLİĞİ TALEBİ
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_reset_outlined, color: Color(0xFF4F46E5), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Şifre Değişiklik Talebi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hesap güvenliğiniz için şifrenizi en az 8 karakterli, harf ve rakam içerecek şekilde belirleyin.',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Mevcut Şifre
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Mevcut Şifre',
                    obscure: _obscureCurrent,
                    onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    inputBgColor: inputBgColor,
                    borderColor: borderColor,
                    validator: (v) => v == null || v.isEmpty ? 'Mevcut şifrenizi giriniz' : null,
                  ),
                  const SizedBox(height: 16),

                  // Yeni Şifre & Yeni Şifre Tekrar (Yan Yana veya Üst Üste)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;

                      final newPassWidget = _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'Yeni Şifre',
                        obscure: _obscureNew,
                        onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        inputBgColor: inputBgColor,
                        borderColor: borderColor,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Yeni şifrenizi giriniz';
                          if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                          return null;
                        },
                      );

                      final confirmPassWidget = _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Yeni Şifre (Tekrar)',
                        obscure: _obscureConfirm,
                        onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        inputBgColor: inputBgColor,
                        borderColor: borderColor,
                        validator: (v) {
                          if (v != _newPasswordController.text) return 'Şifreler uyuşmuyor';
                          return null;
                        },
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: newPassWidget),
                            const SizedBox(width: 16),
                            Expanded(child: confirmPassWidget),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          newPassWidget,
                          const SizedBox(height: 16),
                          confirmPassWidget,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Şifre Güncelle Butonu
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handlePasswordChange,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Güncelleniyor...' : 'Şifreyi Güncelle',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color titleColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: subtitleColor, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: titleColor, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required Color titleColor,
    required Color subtitleColor,
    required Color inputBgColor,
    required Color borderColor,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(color: titleColor, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            hintText: '••••••••',
            hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4F46E5)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: subtitleColor,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}