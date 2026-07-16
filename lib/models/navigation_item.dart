import 'package:flutter/material.dart';

enum AppPage {
  dashboard,
  databases,
  dataExplorer,
  users,
  permissions,
  auditLogs,
  settings,
}

class NavigationItem {
  final String title;
  final IconData icon;
  final AppPage page;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}