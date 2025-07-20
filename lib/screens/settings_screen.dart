import 'package:flutter/material.dart';
import 'package:kapitan_pos/screens/printer_setup_screen.dart'; // Import the new printer setup screen
import 'package:kapitan_pos/screens/app_name_settings_screen.dart'; // Import the new printer setup screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ڕێکخستنەکان'), // Settings
        centerTitle: true,
        backgroundColor: Colors.deepOrange, // Consistent with other screens
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Printer Settings
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text(
                'ڕێکخستنەکانی چاپکەر', // Printer Settings
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text(
                'چاپکەری وەسڵەکەت ببەستەرەوە و ڕێکی بخە', // Connect and configure your receipt printer
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              leading: Icon(Icons.print, color: Colors.blue.shade700, size: 30),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrinterSetupScreen(),
                  ),
                );
              },
            ),
          ),
          // App Name Settings
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text(
                'ڕێکخستنەکانی ناوی ئەپ', // App Name Settings
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text(
                'ناوی ئەپڵیکەیشنەکەت دیاری بکە', // Set your application's name
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              leading: Icon(Icons.abc, color: Colors.purple.shade700, size: 30), // Changed icon for app name
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppNameSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          // About App
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text(
                'دەربارەی کاپیتان پۆس', // About KapitanPOS
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: const Text(
                'وەشانی 1.0.0', // Version 1.0.0
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              leading: Icon(Icons.info_outline, color: Colors.grey.shade700, size: 30), // Changed icon for info
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'KAPITAN POS', // KapitanPOS
                  applicationVersion: '1.0.0',
                  applicationLegalese: '@2025 Arkan Leki', // © 2023 Kapitan Fast Food
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'ئەم ئەپڵیکەیشنە بۆ بەڕێوەبردنی خاڵی فرۆش (POS) دروستکراوە بۆ خواردنی خێرا.', // This application is designed for Point of Sale (POS) management for fast food.
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}