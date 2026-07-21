import 'package:flutter/material.dart';

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
    // Masaüstünde Switch'in doğru render edilmesi için mutlaka Material widget'ı altında olmalıdır.
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF64748B)), // Slate 500 rengi
        title: Text(
          title, 
          style: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 14,
            color: Color(0xFF1E293B), // Koyu slate rengi
          ),
        ),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(
            color: Color(0xFF94A3B8), // Açık gri/slate rengi
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3F51B5), // Senin uygulamanın ana mavi tonu
        ),
      ),
    );
  }
}