import 'package:flutter/material.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_switch_tile.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool _dbAlerts = true;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bildirim Ayarları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hangi durumlarda anlık bildirim almak istediğinizi belirleyin.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "Sistem Bildirimleri",
            children: [
              SettingsSwitchTile(
                icon: Icons.storage_outlined,
                title: "Veritabanı Durum Bildirimleri",
                subtitle: "Yeni koleksiyon, indeks veya şema değişikliklerinde uyar.",
                value: _dbAlerts,
                onChanged: (val) => setState(() => _dbAlerts = val),
              ),
              SettingsSwitchTile(
                icon: Icons.security_outlined,
                title: "Güvenlik ve Erişim Uyarıları",
                subtitle: "Şüpheli giriş denemelerinde ve yetki değişimlerinde e-posta gönder.",
                value: _securityAlerts,
                onChanged: (val) => setState(() => _securityAlerts = val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}