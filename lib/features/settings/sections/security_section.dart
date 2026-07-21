import 'package:flutter/material.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_switch_tile.dart';

class SecuritySection extends StatefulWidget {
  const SecuritySection({super.key});

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Güvenlik Ayarları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hesap güvenliğinizi ve erişim kurallarınızı yönetin.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "Kimlik Doğrulama",
            children: [
              SettingsSwitchTile(
                icon: Icons.phonelink_lock_outlined,
                title: "İki Adımlı Doğrulama (2FA)",
                subtitle: "Giriş yaparken Google Authenticator kodunu zorunlu kılın.",
                value: _twoFactor,
                onChanged: (val) => setState(() => _twoFactor = val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}