import 'package:flutter/material.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_switch_tile.dart';

class GeneralSection extends StatefulWidget {
  const GeneralSection({super.key});

  @override
  State<GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<GeneralSection> {
  bool _autoRefresh = true;
  String _selectedLanguage = 'Türkçe';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Genel Ayarlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Uygulamanın temel çalışma ve dil ayarlarını yapılandırın.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "Uygulama Tercihleri",
            children: [
              SettingsSwitchTile(
                icon: Icons.sync_outlined,
                title: "Otomatik Yenileme",
                subtitle: "Tablo ve şema verilerini arka planda otomatik günceller.",
                value: _autoRefresh,
                onChanged: (val) => setState(() => _autoRefresh = val),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined, color: Color(0xFF64748B)),
                title: const Text("Sistem Dili", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text("Uygulama arayüz dili", style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => _selectedLanguage = newValue);
                  },
                  items: <String>['Türkçe', 'English', 'Deutsch']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}