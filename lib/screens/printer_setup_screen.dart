import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as LocationHandler;

class PrinterSetupScreen extends StatefulWidget {
  const PrinterSetupScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  late StreamSubscription _scanSub;
  String _statusMessage = "بلوتوس لە کاردایە..."; // Initializing Bluetooth...
  bool _isLoading = true;
  final LocationHandler.Location _location = LocationHandler.Location();

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _scanSub.cancel();
    BluetoothPrintPlus.stopScan();
    super.dispose();
  }

  /// Initializes Bluetooth, checks permissions, and starts scanning for devices.
  Future<void> _initializeBluetooth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "ڕێگەپێدانەکان پشکنین دەکرێن..."; // Checking permissions...
      _devices = [];
    });

    try {
      if (Platform.isAndroid) {
        if (!await _checkAndRequestBluetoothPermissions()) {
          setState(
                () => _statusMessage =
            "ڕێگەپێدانی بلوتوس ڕێگری لێکراوە. تکایە لە ڕێکخستنەکانی ئەپەکەدا چاڵاکی بکە.", // Bluetooth permissions denied. Please enable them in app settings.
          );
          return;
        }

        if (!await _checkAndRequestLocationPermissions()) {
          setState(
                () => _statusMessage =
            "ڕێگەپێدانی شوێن پێویستە بۆ گەڕان. تکایە لە ڕێکخستنەکانی ئەپەکەدا چاڵاکی بکە.", // Location permission required for scanning. Please enable in app settings.
          );
          return;
        }

        if (!await _location.serviceEnabled()) {
          setState(
                () => _statusMessage =
            "خزمەتگوزارییەکانی شوێن پێویستن بۆ گەڕان. داوا دەکرێت...", // Location services required for scanning. Requesting...
          );
          if (!await _location.requestService()) {
            setState(
                  () => _statusMessage =
              "خزمەتگوزارییەکانی شوێن ناچاڵاک کراون. تکایە بۆ گەڕان چاڵاکی بکە.", // Location services disabled. Please enable to scan.
            );
            return;
          }
        }
      }

      await _loadSavedDevice();
      await _startScanning();
      setState(() => _statusMessage = "گەڕان بەدوای ئامێرەکاندا..."); // Scanning for devices...
    } catch (e) {
      debugPrint('Bluetooth initialization error: $e');
      setState(
            () => _statusMessage =
        "هەڵە لە کارپێکردنی بلوتوس: ${e.toString()}", // Error initializing Bluetooth
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Checks and requests necessary Bluetooth permissions for Android.
  Future<bool> _checkAndRequestBluetoothPermissions() async {
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();

    return bluetoothConnectStatus.isGranted && bluetoothScanStatus.isGranted;
  }

  /// Checks and requests location permissions, which are required for Bluetooth scanning.
  Future<bool> _checkAndRequestLocationPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Starts the Bluetooth device scanning process.
  Future<void> _startScanning() async {
    _scanSub = BluetoothPrintPlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _devices = results);
      }
    });

    try {
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "هەڵەی گەڕان: $e"); // Scan error:
      }
    }
  }

  /// Saves the selected Bluetooth device's details to SharedPreferences.
  Future<void> _saveDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_printer_device', json.encode(device.toJson()));
    if (mounted) {
      setState(
            () => _selectedDevice = device,
      );
      _showSnackBar(
        "چاپکەر پاشەکەوت کرا: ${device.name ?? 'ئامێری نەناسراو'}", // Printer saved: Unknown Device
        isError: false,
      );
    }
  }

  void _showSnackBar(String s, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Loads the previously saved Bluetooth device from SharedPreferences.
  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedDeviceJson = prefs.getString('saved_printer_device');
    if (savedDeviceJson != null) {
      try {
        final Map<String, dynamic> deviceMap = json.decode(savedDeviceJson);
        setState(() {
          _selectedDevice = BluetoothDevice.fromJson(deviceMap);
        });
        _statusMessage =
        "چاپکەری پاشەکەوتکراو بارکرا: ${_selectedDevice!.name ?? 'نەناسراو'}"; // Saved printer loaded: Unknown
      } catch (e) {
        debugPrint('هەڵە لە بارکردنی ئامێری پاشەکەوتکراو: $e'); // Error loading saved device
        _statusMessage =
        "هەڵە لە بارکردنی چاپکەری پاشەکەوتکراو. تکایە دووبارە هەڵبژێرە."; // Error loading saved printer. Please select again.
      }
    } else {
      _statusMessage = "هیچ چاپکەرێک پاشەکەوت نەکراوە."; // No printer saved.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ڕێکخستنەکانی چاپکەر"), // Printer Settings
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            if (_statusMessage.contains("ڕێگەپێدان") || // "permissions"
                _statusMessage.contains("ناچاڵاک")) // "disabled"
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    openAppSettings();
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  label: const Text(
                    "کردنەوەی ڕێکخستنەکانی ئەپ", // Open App Settings
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بار: $_statusMessage', // Status:
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _statusMessage.contains("هەڵە") || // "Error"
                          _statusMessage.contains("ڕێگری") // "denied"
                          ? Colors.red.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Display the currently selected/saved printer
          if (_selectedDevice != null)
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'چاپکەری دیاریکراو:', // Selected Printer:
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.print, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDevice!.name ?? 'ئامێری نەناسراو', // Unknown Device
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDevice!.address ?? 'هیچ ناونیشانێک نییە', // No Address
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDevice = null;
                            SharedPreferences.getInstance().then(
                                  (prefs) =>
                                  prefs.remove('saved_printer_device'),
                            );
                            _statusMessage = 'هیچ چاپکەرێک پاشەکەوت نەکراوە.'; // No printer saved.
                          });
                          _showSnackBar(
                            'چاپکەری پاشەکەوتکراو سڕایەوە.', // Saved printer cleared.
                            isError: true,
                          );
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('سڕینەوەی چاپکەری پاشەکەوتکراو'), // Clear Saved Printer
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'ئامێرە بەردەستەکان:', // Available Devices:
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: _devices.isEmpty && !_isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_disabled, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "هیچ ئامێرێک نەدۆزرایەوە. کرتە لە نوێکردنەوە بکە بۆ گەڕان.", // No devices found. Tap refresh to scan.
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (_, i) {
                final device = _devices[i];
                final isSelected =
                    _selectedDevice?.address == device.address;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  elevation: isSelected ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isSelected
                        ? const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(
                      Icons.bluetooth,
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.grey.shade600,
                      size: 28,
                    ),
                    title: Text(
                      device.name ?? 'ئامێری نەناسراو', // Unknown Device
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      device.address ?? 'هیچ ناونیشانێک نییە', // No address
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    onTap: () => _saveDevice(device),
                    trailing: isSelected
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _initializeBluetooth,
        tooltip: 'دووبارە گەڕان بەدوای ئامێرەکاندا', // Rescan for Devices
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text(
          'نوێکردنەوە', // Refresh
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Center the FAB
    );
  }
}