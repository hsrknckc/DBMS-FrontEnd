import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/settings_group.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.warning : AppColors.primary;
    final iconColor = isDark ? AppColors.darkTextMuted : AppColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hakkında', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Data Manager uygulaması ve lisans bilgileri.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "Uygulama Bilgileri",
            children: [
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: iconColor),
                title: const Text("Sürüm", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text("v1.0.0", style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
              ),
              ListTile(
                leading: Icon(Icons.copyright_rounded, color: iconColor),
                title: const Text("Lisans", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text("MIT Lisansı", style: TextStyle(color: iconColor)),
              ),
              ListTile(
                leading: Icon(Icons.system_update_alt_rounded, color: iconColor),
                title: const Text("Güncellemeleri Denetle", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uygulama güncel!')),
                    );
                  },
                  child: const Text("Denetle"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
