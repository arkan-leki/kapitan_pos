import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kapitan_pos/blueprint/command_tool.dart';

class BluetoothPrintPage extends StatefulWidget {
  final List<Map<String, dynamic>> printData;

  const BluetoothPrintPage({Key? key, required this.printData})
    : super(key: key);

  @override
  State<BluetoothPrintPage> createState() =>
      _BluetoothPrintPageState(printData);
}

class _BluetoothPrintPageState extends State<BluetoothPrintPage> {
  BluetoothDevice? _device;
  late StreamSubscription _connectStateSub;
  List<Map<String, dynamic>> printData;

  _BluetoothPrintPageState(this.printData);

  @override
  void initState() {
    super.initState();
    initListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadSavedDevice());
  }

  Future<void> loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_printer_device');
    if (jsonStr != null) {
      final map = json.decode(jsonStr);
      _device = BluetoothDevice.fromJson(Map<String, dynamic>.from(map));
      await BluetoothPrintPlus.connect(_device!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No saved printer. Please connect first."),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void initListeners() {
    _connectStateSub = BluetoothPrintPlus.connectState.listen((state) async {
      if (state == ConnectState.connected && _device != null) {
        final cmd = await CommandTool.tscFoodReceiptCmd(printData);
        if (cmd != null) await BluetoothPrintPlus.write(cmd);
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _connectStateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Connecting and printing...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
