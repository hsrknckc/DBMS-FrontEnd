import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
    final accent = isDark ? AppColors.warning : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: subtitleColor),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 14,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle, 
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: accent,
        ),
      ),
    );
  }
}
