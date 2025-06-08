import 'package:flutter/material.dart';
import 'package:kapitan_pos/screens/menu_management.dart';
import 'package:kapitan_pos/screens/pos_screen.dart';
import 'package:kapitan_pos/screens/reports_screen.dart';
import 'package:kapitan_pos/screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fancy Pizza'),
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

// Your NavigationDrawer class remains the same
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6, // Set appropriate width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // For better RTL layout
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("Fancy Pizza", textDirection: TextDirection.rtl),
            accountEmail: const Text("arkan.leki@gmail.com", textDirection: TextDirection.rtl),
            currentAccountPicture: const CircleAvatar(
              child: Text("FP", style: TextStyle(fontSize: 20)),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              image: DecorationImage(
                image: AssetImage('assets/images/drawer_background.png'),
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
