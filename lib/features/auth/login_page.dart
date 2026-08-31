import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'controllers/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _resetFormKey = GlobalKey<FormState>();
  final _resetConfirmFormKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showForgotPassword = false;
  bool _isResetLoading = false;
  bool _isResetSuccess = false;
  bool _isResetConfirmLoading = false;
  bool _isPasswordResetCompleted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetRequest() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isResetLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .requestPasswordReset(_resetEmailController.text.trim());

      if (!mounted) return;

      setState(() {
        _isResetLoading = false;
        _isResetSuccess = true;
        _isPasswordResetCompleted = false;
        _resetCodeController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isResetLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleResetConfirmation() async {
    if (!_resetConfirmFormKey.currentState!.validate()) return;

    setState(() => _isResetConfirmLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .confirmPasswordReset(
            email: _resetEmailController.text.trim(),
            resetCode: _resetCodeController.text.trim(),
            newPassword: _newPasswordController.text,
          );

      if (!mounted) return;

      setState(() {
        _isResetConfirmLoading = false;
        _isPasswordResetCompleted = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isResetConfirmLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050816)
          : const Color(0xFFF6F8FB),
      body: CustomPaint(
        painter: _LoginBackdropPainter(isDark: isDark),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrandLockup(isDark: isDark),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.055)
                          : const Color(0xFAFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFD9E2EC),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.34 : 0.08,
                          ),
                          blurRadius: 34,
                          offset: const Offset(0, 22),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _showForgotPassword
                          ? _buildForgotPasswordView(context, accent)
                          : _buildLoginView(context, accent),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'TCP JSON protocol secured access',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('login_form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            eyebrow: 'AUTHENTICATION',
            title: 'Giriş Yap',
            subtitle: 'Yetkili kullanıcı bilgileriyle devam edin.',
            accent: accent,
          ),
          const SizedBox(height: 26),
          _LabeledField(
            label: 'E-posta',
            child: TextFormField(
              controller: _emailController,
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'admin@company.com',
                prefixIcon: Icon(Icons.alternate_email_rounded, color: muted),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'E-posta adresi boş bırakılamaz';
                }
                if (!value.contains('@')) return 'Geçersiz e-posta formatı';
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Text('Şifre')),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showForgotPassword = true;
                    _isResetSuccess = false;
                  });
                },
                child: const Text('Şifremi unuttum'),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: muted),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: muted,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre alanı boş bırakılamaz';
              }
              if (value.length < 4) return 'Şifre çok kısa';
              return null;
            },
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 18),
              label: Text(_isLoading ? 'Doğrulanıyor' : 'Giriş Yap'),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordView(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    if (_isResetSuccess) {
      if (_isPasswordResetCompleted) {
        return Column(
          key: const ValueKey('reset_completed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: accent, size: 48),
            const SizedBox(height: 18),
            Text('Şifre Değiştirildi', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              'Şifreniz başarıyla değiştirildi. Yeni şifrenizle giriş yapabilirsiniz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showForgotPassword = false;
                    _isResetSuccess = false;
                    _isPasswordResetCompleted = false;
                    _resetEmailController.clear();
                    _resetCodeController.clear();
                    _newPasswordController.clear();
                    _confirmNewPasswordController.clear();
                  });
                },
                child: const Text('Giriş Ekranına Dön'),
              ),
            ),
          ],
        );
      }

      return Form(
        key: _resetConfirmFormKey,
        child: Column(
          key: const ValueKey('reset_confirm'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Yeni kod iste',
              onPressed: _isResetConfirmLoading
                  ? null
                  : () {
                      setState(() {
                        _isResetSuccess = false;
                        _resetCodeController.clear();
                        _newPasswordController.clear();
                        _confirmNewPasswordController.clear();
                      });
                    },
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
            ),
            const SizedBox(height: 8),
            _PanelHeader(
              eyebrow: 'ACCOUNT RECOVERY',
              title: 'Şifreyi Sıfırla',
              subtitle: 'Oluşturulan sıfırlama kodunu ve yeni şifrenizi girin.',
              accent: accent,
            ),
            const SizedBox(height: 24),
            _LabeledField(
              label: 'Sıfırlama kodu',
              child: TextFormField(
                controller: _resetCodeController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Sıfırlama kodunu girin',
                  prefixIcon: Icon(Icons.key_rounded, color: muted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sıfırlama kodunu girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),
            _LabeledField(
              label: 'Yeni şifre',
              child: TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_reset_rounded, color: muted),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Yeni şifreyi girin';
                  if (password.length < 8) {
                    return 'Şifre en az 8 karakter olmalı';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(password)) {
                    return 'En az 1 büyük harf içermeli';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(password)) {
                    return 'En az 1 küçük harf içermeli';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(password)) {
                    return 'En az 1 rakam içermeli';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),
            _LabeledField(
              label: 'Yeni şifre tekrar',
              child: TextFormField(
                controller: _confirmNewPasswordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: muted),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifreyi tekrar girin';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isResetConfirmLoading
                    ? null
                    : _handleResetConfirmation,
                icon: _isResetConfirmLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_reset_rounded, size: 18),
                label: Text(
                  _isResetConfirmLoading
                      ? 'Değiştiriliyor'
                      : 'Şifreyi Değiştir',
                ),
                style: ElevatedButton.styleFrom(backgroundColor: accent),
              ),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset_form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Geri dön',
            onPressed: () {
              setState(() {
                _showForgotPassword = false;
                _isResetSuccess = false;
                _isPasswordResetCompleted = false;
              });
            },
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
          ),
          const SizedBox(height: 8),
          _PanelHeader(
            eyebrow: 'ACCOUNT RECOVERY',
            title: 'Şifre Talebi',
            subtitle: 'Kayıtlı e-posta adresinizle sıfırlama talebi oluşturun.',
            accent: accent,
          ),
          const SizedBox(height: 24),
          _LabeledField(
            label: 'Kayıtlı e-posta',
            child: TextFormField(
              controller: _resetEmailController,
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'admin@company.com',
                prefixIcon: Icon(Icons.alternate_email_rounded, color: muted),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'E-posta adresi boş bırakılamaz';
                }
                if (!email.contains('@')) return 'Geçersiz e-posta formatı';
                return null;
              },
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isResetLoading ? null : _handleResetRequest,
              icon: _isResetLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isResetLoading ? 'Gönderiliyor' : 'Sıfırlama Kodu İste',
              ),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  final bool isDark;

  const _BrandLockup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
    final accent = isDark ? AppColors.accent : AppColors.primary;

    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.055)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.accent.withValues(alpha: 0.26)
                  : const Color(0xFFD7E0EA),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.accent : Colors.black).withValues(
                  alpha: isDark ? 0.12 : 0.07,
                ),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: CustomPaint(painter: _ServerMarkPainter(accent: accent)),
        ),
        const SizedBox(height: 16),
        Text(
          'Data Manager',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Secure Database Console',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;

  const _PanelHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 24, height: 2, color: accent),
            const SizedBox(width: 9),
            Text(
              eyebrow,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  final bool isDark;

  const _LoginBackdropPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (isDark ? AppColors.accent : AppColors.primary).withValues(
            alpha: isDark ? 0.16 : 0.06,
          ),
          Colors.transparent,
          (isDark ? AppColors.violet : AppColors.accent).withValues(
            alpha: isDark ? 0.12 : 0.05,
          ),
        ],
      ).createShader(Offset.zero & size);

    final sweepPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.72, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height)
      ..lineTo(0, size.height * 0.36)
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _ServerMarkPainter extends CustomPainter {
  final Color accent;

  const _ServerMarkPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final startY = size.height * 0.28;
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.2;

    for (var i = 0; i < 3; i++) {
      linePaint.color = i == 0
          ? accent
          : const Color(0xFF94A3B8).withValues(alpha: 0.82 - i * 0.18);
      final y = startY + i * 10;
      canvas.drawLine(
        Offset(centerX - 12, y),
        Offset(centerX + 12, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ServerMarkPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
