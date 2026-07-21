import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'layout/main_layout.dart';
import 'features/auth/login_page.dart';
import 'features/auth/controllers/auth_notifier.dart';

void main() {
  runApp(
    // Riverpod'un tüm widget ağacında çalışması için ProviderScope zorunlu.
    const ProviderScope(
      child: DatabaseManagementApp(),
    ),
  );
}

class DatabaseManagementApp extends ConsumerStatefulWidget {
  const DatabaseManagementApp({super.key});

  static DatabaseManagementAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<DatabaseManagementAppState>();
  }

  @override
  ConsumerState<DatabaseManagementApp> createState() =>
      DatabaseManagementAppState();
}

class DatabaseManagementAppState
    extends ConsumerState<DatabaseManagementApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isCompactSidebar = false;
  String _apiBaseUrl = 'http://localhost:8080/api/v1';
  int _timeoutSeconds = 30;

  ThemeMode get themeMode => _themeMode;
  bool get isCompactSidebar => _isCompactSidebar;
  String get apiBaseUrl => _apiBaseUrl;
  int get timeoutSeconds => _timeoutSeconds;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void setCompactSidebar(bool compact) {
    setState(() {
      _isCompactSidebar = compact;
    });
  }

  void updateApiSettings(String url, int timeout) {
    setState(() {
      _apiBaseUrl = url;
      _timeoutSeconds = timeout;
    });
  }

  /// AuthNotifier üzerinden logout — tüm provider state'leri temizlenir.
  void logout() {
    ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    // AuthNotifier'dan giriş durumunu dinle
    final authState = ref.watch(authNotifierProvider);
    final isLoggedIn = authState.valueOrNull != null;

    return MaterialApp(
      key: ValueKey(_themeMode),
      title: 'Database Management',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: isLoggedIn
          ? const MainLayout()
          : LoginPage(
              onLoginSuccess: () {
                // Login işlemi AuthNotifier tarafından yapılıyor,
                // bu callback UI geçişi için tetikleyici.
              },
            ),
    );
  }
}