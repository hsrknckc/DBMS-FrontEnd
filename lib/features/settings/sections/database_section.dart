import 'package:flutter/material.dart';
import '../../../main.dart';
import '../widgets/settings_group.dart';

class DatabaseSection extends StatefulWidget {
  const DatabaseSection({super.key});

  @override
  State<DatabaseSection> createState() => _DatabaseSectionState();
}

class _DatabaseSectionState extends State<DatabaseSection> {
  late TextEditingController _urlController;
  late TextEditingController _timeoutController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final myApp = DatabaseManagementApp.of(context);
    _urlController = TextEditingController(text: myApp?.apiBaseUrl ?? '');
    _timeoutController = TextEditingController(text: myApp?.timeoutSeconds.toString() ?? '30');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final myApp = DatabaseManagementApp.of(context);
    final timeoutVal = int.tryParse(_timeoutController.text) ?? 30;
    
    myApp?.updateApiSettings(_urlController.text, timeoutVal);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veritabanı ve Servis ayarları başarıyla yerel olarak kaydedildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Veritabanı & Servis Ayarları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Java ara katmanı (API) ve veritabanı bağlantı limitlerini yapılandırın.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            title: "JAVA BACKEND ENTEGRASYONU",
            children: [
              ListTile(
                leading: const Icon(Icons.link, color: Colors.blueAccent),
                title: const Text('API Base URL', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Java Spring Boot servis adresi'),
                trailing: SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'http://localhost:8080/api/v1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroup(
            title: "BAĞLANTI ZAMAN AŞIMI",
            children: [
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.orange),
                title: const Text('Timeout Süresi (Saniye)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('MongoDB yanıt verme sınırı'),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _timeoutController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}