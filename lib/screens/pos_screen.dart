import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/models/menu_item.dart';
import 'package:kapitan_pos/models/order.dart';
import 'package:kapitan_pos/models/order_item.dart';
import '../blueprint/bluetooth_print_page.dart'; // Ensure this path is correct

// Import the new layout files
import 'mobile_pos_layout.dart';
import 'tablet_pos_layout.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // --- State Variables ---
  final List<OrderItem> _currentOrder = []; // List of items in the current order
  OrderType _orderType = OrderType.onsite; // Type of order (On-site or Delivery)
  final TextEditingController _customerNameController = TextEditingController(); // Controller for customer name input
  final TextEditingController _deliveryAddressController = TextEditingController(); // Controller for delivery address input

  late Box<MenuItem> _menuItemsBox; // Hive box for menu items
  late Box<Order> _ordersBox; // Hive box for orders

  String? _selectedCategory; // Currently selected menu category filter
  List<String> _categories = []; // List of available menu categories

  @override
  void initState() {
    super.initState();
    // Initialize Hive boxes and load categories when the widget is created
    _initHiveBoxes().then((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    // Dispose of text editing controllers to prevent memory leaks
    _customerNameController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  // --- Hive Box Initialization ---
  Future<void> _initHiveBoxes() async {
    try {
      // Open Hive boxes for menu items and orders
      _menuItemsBox = await Hive.openBox<MenuItem>('menuItems');
      _ordersBox = await Hive.openBox<Order>('orders');
      setState(() {}); // Trigger a rebuild to show content once boxes are open
    } catch (e) {
      debugPrint('Error initializing Hive boxes: $e');
      _showSnackBar(
        'Failed to load data. Please restart the app.',
        isError: true,
      );
    }
  }

  // --- Category Loading Logic ---
  void _loadCategories() {
    if (Hive.isBoxOpen('menuItems')) {
      final uniqueCategories = <String>{};
      // Listen for changes in the menuItems box to update categories dynamically
      _menuItemsBox.listenable().addListener(() {
        final newUniqueCategories = <String>{};
        for (var item in _menuItemsBox.values) {
          if (item.category != null && item.category!.isNotEmpty) {
            newUniqueCategories.add(item.category!);
          }
        }
        // Update categories if there are changes
        if (newUniqueCategories.length != uniqueCategories.length ||
            !newUniqueCategories.containsAll(uniqueCategories)) {
          setState(() {
            _categories = ['هەمووی', ...newUniqueCategories.toList()..sort()];
            // Reset selected category if it no longer exists
            if (_selectedCategory != null &&
                !_categories.contains(_selectedCategory)) {
              _selectedCategory = null;
            }
          });
          uniqueCategories.clear();
          uniqueCategories.addAll(newUniqueCategories);
        }
      });

      // Initial load of categories
      for (var item in _menuItemsBox.values) {
        if (item.category != null && item.category!.isNotEmpty) {
          uniqueCategories.add(item.category!);
        }
      }
      setState(() {
        _categories = ['هەمووی', ...uniqueCategories.toList()..sort()];
      });
    }
  }

  // --- UI Feedback (SnackBar) ---
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- Order Management Methods ---
  void _addToOrder(MenuItem item) {
    setState(() {
      final existingItemIndex = _currentOrder.indexWhere(
            (orderItem) => orderItem.menuItem.id == item.id,
      );
      if (existingItemIndex >= 0) {
        // If item exists, increment quantity
        _currentOrder[existingItemIndex] = _currentOrder[existingItemIndex]
            .copyWith(quantity: _currentOrder[existingItemIndex].quantity + 1);
      } else {
        // If item is new, add it to the order
        _currentOrder.add(OrderItem(menuItem: item, quantity: 1));
      }
    });
  }

  void _removeFromOrder(int index) {
    setState(() {
      if (_currentOrder[index].quantity > 1) {
        // If quantity > 1, decrement quantity
        _currentOrder[index] = _currentOrder[index].copyWith(
          quantity: _currentOrder[index].quantity - 1,
        );
      } else {
        // If quantity is 1, remove the item from order
        _currentOrder.removeAt(index);
      }
    });
  }

  void _clearOrder() {
    setState(() {
      _currentOrder.clear(); // Clear all items from the order
      _customerNameController.clear(); // Clear customer name
      _deliveryAddressController.clear(); // Clear delivery address
      _orderType = OrderType.onsite; // Reset order type to on-site
    });
  }

  void _submitOrder() async {
    if (_currentOrder.isEmpty) {
      _showSnackBar('Please add items to the order', isError: true);
      return;
    }

    // Validate delivery address if order type is delivery
    if (_orderType == OrderType.delivery &&
        _deliveryAddressController.text.isEmpty) {
      _showSnackBar('Please enter delivery address', isError: true);
      return;
    }

    // Create a new Order object
    final order = Order(
      items: List.from(_currentOrder), // Create a copy of current order items
      orderType: _orderType,
      customerName: _customerNameController.text,
      deliveryAddress: _deliveryAddressController.text,
      timestamp: DateTime.now(),
    );

    try {
      await _ordersBox.add(order); // Save the order to Hive
      _showSnackBar('Order submitted successfully!');
      _printOrder(order); // Show print dialog
      _clearOrder(); // Clear the order after submission
    } catch (e) {
      debugPrint('Error saving order: $e');
      _showSnackBar('Failed to submit order. Please try again.', isError: true);
    }
  }

  // --- Order Printing Logic ---
  void _printOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پسوڵەی داواکاری'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('جۆری داواکاری: ${order.orderType.name.toUpperCase()}'),
              if (order.customerName.isNotEmpty)
                Text('کڕیار: ${order.customerName}'),
              if (order.deliveryAddress.isNotEmpty)
                Text('ناونیشان: ${order.deliveryAddress}'),
              const SizedBox(height: 16),
              const Text(
                'کالاکان:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map(
                    (item) => Text(
                  '${item.menuItem.name} x${item.quantity} - ${(item.menuItem.price * item.quantity).toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'کۆ: ${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشە'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              var printReceipt = <Map<String, dynamic>>[];
              printReceipt.add({
                'id': order.key?.toString() ?? 'N/A',
                'order_title': '#${order.key?.toString() ?? 'N/A'}',
                'order_type': _mapOrderTypeToEnglish(order.orderType),
                'customer_name': order.customerName,
                'delivery_address': order.deliveryAddress,
                'date':
                '${order.timestamp.day}/${order.timestamp.month}/${order.timestamp.year}',
                'time':
                '${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}',
                'total': order.total.toStringAsFixed(0),
                'items': order.items.map((item) {
                  return {
                    'name': item.menuItem.name,
                    'quantity': item.quantity,
                    'price': item.menuItem.price.toStringAsFixed(0),
                    'subtotal': (item.menuItem.price * item.quantity)
                        .toStringAsFixed(0),
                  };
                }).toList(),
              });

              if (printReceipt.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BluetoothPrintPage(printData: printReceipt),
                  ),
                );
              }
            },
            child: const Text('چاپ'),
          ),
        ],
      ),
    );
  }

  // --- Build Method for Device Detection ---
  @override
  Widget build(BuildContext context) {
    // Show loading indicator if Hive boxes are not yet open
    if (!Hive.isBoxOpen('menuItems') || !Hive.isBoxOpen('orders')) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading menu and orders...'),
            ],
          ),
        ),
      );
    }

    // Determine if it's a tablet based on shortest side (common breakpoint is 600dp)
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // Pass all necessary data and callbacks to the appropriate layout widget
    final commonProps = {
      'currentOrder': _currentOrder,
      'orderType': _orderType,
      'customerNameController': _customerNameController,
      'deliveryAddressController': _deliveryAddressController,
      'menuItemsBox': _menuItemsBox,
      'categories': _categories,
      'selectedCategory': _selectedCategory,
      'onCategorySelected': (String? category) {
        setState(() {
          _selectedCategory = category;
        });
      },
      'onAddToOrder': _addToOrder,
      'onRemoveFromOrder': _removeFromOrder,
      'onClearOrder': _clearOrder,
      'onSubmitOrder': _submitOrder,
      'showSnackBar': _showSnackBar,
      'mapOrderTypeToEnglish': _mapOrderTypeToEnglish,
      'onOrderTypeChanged': (OrderType type) {
        setState(() {
          _orderType = type;
        });
      },
    };

    return Scaffold(
      body: isTablet
          ? TabletPOSLayout(
        // Cast the map values to their specific types
        currentOrder: commonProps['currentOrder'] as List<OrderItem>,
        orderType: commonProps['orderType'] as OrderType,
        customerNameController: commonProps['customerNameController'] as TextEditingController,
        deliveryAddressController: commonProps['deliveryAddressController'] as TextEditingController,
        menuItemsBox: commonProps['menuItemsBox'] as Box<MenuItem>,
        categories: commonProps['categories'] as List<String>,
        selectedCategory: commonProps['selectedCategory'] as String?,
        onCategorySelected: commonProps['onCategorySelected'] as Function(String?),
        onAddToOrder: commonProps['onAddToOrder'] as Function(MenuItem),
        onRemoveFromOrder: commonProps['onRemoveFromOrder'] as Function(int),
        onClearOrder: commonProps['onClearOrder'] as VoidCallback,
        onSubmitOrder: commonProps['onSubmitOrder'] as VoidCallback,
        showSnackBar: commonProps['showSnackBar'] as Function(String, {bool isError}),
        mapOrderTypeToEnglish: commonProps['mapOrderTypeToEnglish'] as Function(OrderType),
        onOrderTypeChanged: commonProps['onOrderTypeChanged'] as Function(OrderType),
      )
          : MobilePOSLayout(
        // Cast the map values to their specific types
        currentOrder: commonProps['currentOrder'] as List<OrderItem>,
        orderType: commonProps['orderType'] as OrderType,
        customerNameController: commonProps['customerNameController'] as TextEditingController,
        deliveryAddressController: commonProps['deliveryAddressController'] as TextEditingController,
        menuItemsBox: commonProps['menuItemsBox'] as Box<MenuItem>,
        categories: commonProps['categories'] as List<String>,
        selectedCategory: commonProps['selectedCategory'] as String?,
        onCategorySelected: commonProps['onCategorySelected'] as Function(String?),
        onAddToOrder: commonProps['onAddToOrder'] as Function(MenuItem),
        onRemoveFromOrder: commonProps['onRemoveFromOrder'] as Function(int),
        onClearOrder: commonProps['onClearOrder'] as VoidCallback,
        onSubmitOrder: commonProps['onSubmitOrder'] as VoidCallback,
        showSnackBar: commonProps['showSnackBar'] as Function(String, {bool isError}),
        mapOrderTypeToEnglish: commonProps['mapOrderTypeToEnglish'] as Function(OrderType),
        onOrderTypeChanged: commonProps['onOrderTypeChanged'] as Function(OrderType),
      ),
    );
  }
}

// Utility function to map OrderType to English string (can be moved to a utils file if needed elsewhere)
String _mapOrderTypeToEnglish(OrderType type) {
  switch (type) {
    case OrderType.onsite:
      return 'On Site';
    case OrderType.delivery:
      return 'Delivery';
    default:
      return '';
  }
}
