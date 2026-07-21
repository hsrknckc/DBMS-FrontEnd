import 'package:flutter/material.dart';
import 'sections/database_section.dart';
import 'sections/general_section.dart';
import 'sections/appearance_section.dart';
import 'sections/notification_section.dart';
import 'sections/security_section.dart';
import 'sections/about_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _activeTab = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Genel', 'icon': Icons.settings_applications_outlined, 'widget': const GeneralSection()},
    {'title': 'Görünüm', 'icon': Icons.palette_outlined, 'widget': const AppearanceSection()},
    {'title': 'Veritabanı', 'icon': Icons.dns_outlined, 'widget': const DatabaseSection()},
    {'title': 'Bildirimler', 'icon': Icons.notifications_none_outlined, 'widget': const NotificationSection()},
    {'title': 'Güvenlik', 'icon': Icons.security_outlined, 'widget': const SecuritySection()},
    {'title': 'Hakkında', 'icon': Icons.info_outline, 'widget': const AboutSection()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern açık gri/mavi tonlu arka plan
      body: Row(
        children: [
          // Sol Bölüm: Ayarlar Navigasyon Menüsü
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _activeTab == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _tabs[index]['icon'],
                            color: isSelected ? Colors.blueAccent.shade700 : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _tabs[index]['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.blueAccent.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Sağ Bölüm: Seçili Sekmenin Detay Sayfası
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _tabs[_activeTab]['widget'],
            ),
          ),
        ],
      ),
    );
  }
}