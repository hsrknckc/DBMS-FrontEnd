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
    final Color boxBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color titleColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF1E293B));
    final Color subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Görünüm ve Tema', 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uygulamanın temasını ve yerleşim düzenini kişiselleştirin.', 
            style: TextStyle(color: subtitleColor),
          ),
          const SizedBox(height: 24),
          
          // Bildirim ayarlarındaki gibi şık bir kutu (Container) sarmalayıcısı ekledik
          Container(
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // 1. Switch Seçeneği: Koyu Tema
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    "Koyu Tema",
                    style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  subtitle: Text(
                    "Gece modu arayüzünü aktif edin.",
                    style: TextStyle(color: subtitleColor),
                  ),
                  value: isDark,
                  activeThumbColor: const Color(0xFF4F46E5), // Projenin ana buton rengiyle eşleyebilirsiniz
                  onChanged: (val) {
                    setState(() {
                      myApp?.toggleTheme(val);
                    });
                  },
                ),
                
                // İki seçenek arasına diğer ekranlara uyumlu ince bölücü çizgi
                Divider(color: borderColor, height: 1, thickness: 1),
                
                // 2. Switch Seçeneği: Daraltılmış Menü
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    "Daraltılmış Menü",
                    style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  subtitle: Text(
                    "Sol navigasyon barını küçültün.",
                    style: TextStyle(color: subtitleColor),
                  ),
                  value: isCompact,
                  activeThumbColor: const Color(0xFF4F46E5),
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