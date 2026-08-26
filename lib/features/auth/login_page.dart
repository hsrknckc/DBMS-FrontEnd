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
  final _resetFormKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showForgotPassword = false;
  bool _isResetLoading = false;
  bool _isResetSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
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

  void _handleResetRequest() {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isResetLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isResetLoading = false;
        _isResetSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.warning : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF080A0F) : const Color(0xFFF6F8FB),
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
                          ? const Color(0xF20E1117)
                          : const Color(0xFAFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
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
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
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
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    if (_isResetSuccess) {
      return Column(
        key: const ValueKey('reset_success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mark_email_read_outlined, color: accent, size: 44),
          const SizedBox(height: 18),
          Text('Talep Gönderildi', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Şifre sıfırlama yönergeleri e-posta adresinize gönderildi.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _showForgotPassword = false),
              child: const Text('Giriş Ekranına Dön'),
            ),
          ),
        ],
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
            onPressed: () => setState(() => _showForgotPassword = false),
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
                if (value == null || value.isEmpty) {
                  return 'E-posta adresi boş bırakılamaz';
                }
                if (!value.contains('@')) return 'Geçersiz e-posta formatı';
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
              label: Text(_isResetLoading ? 'Gönderiliyor' : 'Talebi Gönder'),
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
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
    final accent = isDark ? AppColors.warning : AppColors.primary;

    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10131A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFD7E0EA),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.07),
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
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
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF64748B))
          .withValues(alpha: isDark ? 0.035 : 0.045)
      ..strokeWidth = 1;

    const step = 52.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (isDark ? AppColors.warning : AppColors.primary)
          .withValues(alpha: isDark ? 0.10 : 0.055);

    for (double x = -size.height; x < size.width; x += 240) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        accent,
      );
    }
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
