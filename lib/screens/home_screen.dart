import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kapitan_pos/screens/menu_management.dart';
import 'package:kapitan_pos/screens/pos_screen.dart';
import 'package:kapitan_pos/screens/reports_screen.dart';
import 'package:kapitan_pos/screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var name = getAppName();
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepOrange, // A vibrant color
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Use a Builder to get a context below the Scaffold
          Builder(
            builder: (BuildContext builderContext) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(builderContext).openDrawer(); // Changed to openDrawer for RTL
                },
              );
            },
          ),
        ],
      ),
      drawer: const NavigationDrawer(), // Changed to drawer for RTL
      body: const POSScreen(),
    );
  }
}

String getAppName() {
  final appSettingsBox = Hive.box('appSettings');
  return appSettingsBox.get('appName', defaultValue: 'KAPITAN POS');
}

// Your NavigationDrawer class remains the same
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    var name = getAppName();
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6, // Set appropriate width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // For better RTL layout
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name, textDirection: TextDirection.rtl),
            accountEmail: const Text("KAPITAN POS", textDirection: TextDirection.rtl),
            currentAccountPicture: CircleAvatar(
              child: Text(name.substring(0,2), style: TextStyle(fontSize: 20)),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              image: DecorationImage(
                image: AssetImage('assets/images/drawer.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('ڕاپۆرتەکان'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('مینو'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('رێخستنەکان'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('دەربارە'),
            onTap: () {
              // Navigator.pop(context); // Not needed before showAboutDialog if you want the drawer to stay open during
              showAboutDialog(
                context: context,
                applicationName: 'KapitanPOS',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Kapitan Fast Food',
              );
            },
          ),
        ],
      ),
    );
  }
}
