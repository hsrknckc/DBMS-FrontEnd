import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'layout/main_layout.dart';

void main() {
  runApp(const DatabaseManagementApp());
}

class DatabaseManagementApp extends StatelessWidget {
  const DatabaseManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}