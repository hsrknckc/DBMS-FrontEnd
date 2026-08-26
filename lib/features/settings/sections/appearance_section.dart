import 'package:flutter/material.dart';
import '../../../main.dart';

class AppearanceSection extends StatefulWidget {
  const AppearanceSection({super.key});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  @override
  Widget build(BuildContext context) {
    final myApp = DatabaseManagementApp.of(context);
    final isDark = myApp?.themeMode == ThemeMode.dark;
    final isCompact = myApp?.isCompactSidebar ?? false;

    // Temaya duyarlı dinamik renklerimizi tanımlıyoruz
    final theme = Theme.of(context);
    final Color boxBgColor =
        isDark ? const Color(0xFF111827) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF253246) : const Color(0xFFDCE3EC);
    final Color titleColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF111827));
    final Color subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Görünüm ve Tema', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Uygulamanın temasını ve yerleşim düzenini kişiselleştirin.',
            style: TextStyle(color: subtitleColor),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  title: Text(
                    "Koyu Tema",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    "Gece modu arayüzünü aktif edin.",
                    style: TextStyle(color: subtitleColor),
                  ),
                  value: isDark,
                  onChanged: (val) {
                    setState(() {
                      myApp?.toggleTheme(val);
                    });
                  },
                ),
                Divider(color: borderColor, height: 1, thickness: 1),
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  title: Text(
                    "Daraltılmış Menü",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    "Sol navigasyonu ikon moduna alın; üzerine gelince otomatik genişler.",
                    style: TextStyle(color: subtitleColor),
                  ),
                  value: isCompact,
                  onChanged: (val) {
                    setState(() {
                      myApp?.setCompactSidebar(val);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
