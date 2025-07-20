import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive initialization and Flutter integration
import 'package:path_provider/path_provider.dart'; // Import for getting the application directory
import 'package:flutter_localization/flutter_localization.dart';

// Import your custom model classes
import 'package:kapitan_pos/models/menu_item.dart';
import 'package:kapitan_pos/models/order.dart'; // This file likely contains Order and OrderType
import 'package:kapitan_pos/models/order_item.dart';

// Import your screen files
import 'package:kapitan_pos/screens/home_screen.dart';
// Note: menu_management, pos_screen, reports_screen, settings_screen
// are typically imported by home_screen or its children, not directly by main.dart
// unless they are explicitly navigated to from the main MaterialApp routes.
// For this example, I'll keep only what's necessary for the entry point.
final FlutterLocalization localization = FlutterLocalization.instance;

void main() async {
  // Ensure that Flutter's widget binding is initialized.
  // This is crucial before performing any platform-specific operations like getting paths.
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();

  // Get the application's document directory. This is where Hive will store its data files.
  final appDocumentDir = await getApplicationDocumentsDirectory();

  // Initialize Hive. You must do this once at the start of your application.
  await Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('appSettings');

  // Register the generated adapters for your custom classes.
  // This tells Hive how to serialize and deserialize your MenuItem, OrderType, OrderItem, and Order objects.
  Hive.registerAdapter(MenuItemAdapter());
  Hive.registerAdapter(OrderTypeAdapter()); // Register the adapter for the enum
  Hive.registerAdapter(OrderItemAdapter());
  Hive.registerAdapter(OrderAdapter());

  // Run the main Flutter application.
  runApp(const KapitanPOS());
}

class KapitanPOS extends StatelessWidget {
  const KapitanPOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KapitanPOS',
      locale: const Locale('ar', 'IQ'), // or 'ku' for Kurdish if supported
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: localization.localizationsDelegates,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const HomeScreen(), // Your app's starting screen
      debugShowCheckedModeBanner:
          false, // Hides the debug banner in release mode
    );
  }
}
