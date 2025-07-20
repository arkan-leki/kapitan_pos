import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppNameSettingsScreen extends StatefulWidget {
  const AppNameSettingsScreen({super.key});

  @override
  State<AppNameSettingsScreen> createState() => _AppNameSettingsScreenState();
}

class _AppNameSettingsScreenState extends State<AppNameSettingsScreen> {
  final TextEditingController _appNameController = TextEditingController();
  late Box _appSettingsBox;

  @override
  void initState() {
    super.initState();
    _appSettingsBox = Hive.box('appSettings');
    _appNameController.text = _appSettingsBox.get('appName', defaultValue: 'KAPITAN POS');
  }

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  void _saveAppName() {
    _appSettingsBox.put('appName', _appNameController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ناوی ئەپەکە بە سەرکەوتوویی پاشەکەوت کرا.'), // App name saved successfully.
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ڕێکخستنەکانی ناوی ئەپ'), // App Name Settings
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(
                labelText: 'ناوی ئەپ', // App Name
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'ناوی ئەپەکەت لێرە بنووسە', // Enter your app name here
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAppName,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, // Button color
                foregroundColor: Colors.white, // Text color
                minimumSize: const Size(double.infinity, 50), // Full width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'پاشەکەوتکردن', // Save
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}