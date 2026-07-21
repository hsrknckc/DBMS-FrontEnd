import 'package:flutter/material.dart';
import '../widgets/settings_group.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hakkında', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Data Manager uygulaması ve lisans bilgileri.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "Uygulama Bilgileri",
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline, color: Color(0xFF64748B)),
                title: Text("Sürüm", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text("v1.0.0", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
              const ListTile(
                leading: Icon(Icons.copyright_outlined, color: Color(0xFF64748B)),
                title: Text("Lisans", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text("MIT Lisansı", style: TextStyle(color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.system_update_outlined, color: Color(0xFF64748B)),
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