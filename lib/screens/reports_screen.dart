import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/blueprint/bluetooth_print_page.dart';
import 'package:kapitan_pos/models/order.dart'; // Contains Order and OrderType

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Box<Order> _ordersBox;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  OrderType? _selectedOrderType;

  @override
  void initState() {
    super.initState();
    _initHiveBox();
  }

  Future<void> _initHiveBox() async {
    try {
      _ordersBox = await Hive.openBox<Order>('orders');
      setState(() {
        // Rebuild the UI once the box is open
      });
    } catch (e) {
      debugPrint('هەڵە لە بارکردنی داواکارییەکان: $e'); // Error initializing orders Hive box
      _showSnackBar(
        'هەڵە لە بارکردنی داواکارییەکان. تکایە ئەپەکە دابخە و دوبارە بیکەرەوە.', // Failed to load orders. Please restart the app.
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Order> get _filteredOrders {
    if (!Hive.isBoxOpen('orders')) {
      return [];
    }

    final allOrders = _ordersBox.values.toList();

    // Sort orders by timestamp in descending order (newest first)
    allOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allOrders.where((order) {
      bool matchesDate = true;
      if (_selectedStartDate != null && _selectedEndDate != null) {
        // Normalize order date to start of day for comparison
        final orderDate = DateTime(
          order.timestamp.year,
          order.timestamp.month,
          order.timestamp.day,
        );
        final startDate = DateTime(
          _selectedStartDate!.year,
          _selectedStartDate!.month,
          _selectedStartDate!.day,
        );
        // Ensure end date includes the entire day
        final endDate = DateTime(
          _selectedEndDate!.year,
          _selectedEndDate!.month,
          _selectedEndDate!.day,
        ).add(const Duration(days: 1)); // Add one day to include the whole end day

        matchesDate = (orderDate.isAtSameMomentAs(startDate) ||
            orderDate.isAfter(startDate)) &&
            orderDate.isBefore(endDate); // Use isBefore for end date
      }

      bool matchesType = true;
      if (_selectedOrderType != null) {
        matchesType = order.orderType == _selectedOrderType;
      }
      return matchesDate && matchesType;
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
      _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(
        start: _selectedStartDate!,
        end: _selectedEndDate!,
      )
          : null,
      helpText: 'دیاریکردنی مەودای ڕێکەوتی داواکاری', // Select Order Date Range
      fieldStartHintText: 'ڕێکەوتی دەستپێک', // Start Date
      fieldEndHintText: 'ڕێکەوتی کۆتایی', // End Date
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepOrange, // Customize picker color
            colorScheme: const ColorScheme.light(primary: Colors.deepOrange),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null &&
        (picked.start != _selectedStartDate ||
            picked.end != _selectedEndDate)) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  double _getTotalSales() {
    return _filteredOrders.fold(0.0, (sum, order) => sum + order.total);
  }

  // Function to delete an order
  Future<void> _deleteOrder(int? orderId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دڵنیابوونەوە لە سڕینەوە'), // Confirm Deletion
        content: Text(
            'دڵنیایت دەتەوێت داواکارییەکەی #${orderId} بسڕیتەوە؟'), // Are you sure you want to delete order #...?
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Don't delete
            child: const Text('هەڵوەشاندنەوە'), // Cancel
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm delete
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('سڕینەوە'), // Delete
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _ordersBox.delete(orderId); // Delete the order from Hive
        _showSnackBar('داواکارییەکە سڕایەوە.', isError: false); // Order deleted.
      } catch (e) {
        debugPrint('هەڵە لە سڕینەوەی داواکاری: $e'); // Error deleting order
        _showSnackBar(
            'هەڵە لە سڕینەوەی داواکاری.', isError: true); // Error deleting order.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('orders')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ڕاپۆرتەکانی فرۆش'), // Sales Reports
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepOrange),
              SizedBox(height: 16),
              Text(
                'داواکارییەکان باردەکرێن...', // Loading orders...
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ڕاپۆرتەکانی فرۆش'), // Sales Reports
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: Text(
                      _selectedStartDate == null
                          ? 'دیاریکردنی مەودای ڕێکەوت' // Select Date Range
                          : '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - ${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}',
                      style: const TextStyle(fontSize: 13), // Smaller font
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade50,
                      foregroundColor: Colors.deepOrange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced vertical padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, // Reduced horizontal padding
                    vertical: 0, // Adjusted vertical padding
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<OrderType?>(
                      value: _selectedOrderType,
                      hint: const Text(
                        'جۆر', // Shorter hint for type
                        style: TextStyle(color: Colors.grey, fontSize: 13), // Smaller font
                      ),
                      onChanged: (OrderType? newValue) {
                        setState(() {
                          _selectedOrderType = newValue;
                        });
                      },
                      items: <DropdownMenuItem<OrderType?>>[
                        const DropdownMenuItem<OrderType?>(
                          value: null,
                          child: Text('هەموو جۆرەکان', style: TextStyle(fontSize: 13)), // Smaller font
                        ),
                        ...OrderType.values.map((type) {
                          return DropdownMenuItem<OrderType?>(
                            value: type,
                            child: Text(
                              _mapOrderTypeToKurdish(type),
                              style: const TextStyle(fontSize: 13), // Smaller font
                            ),
                          );
                        }).toList(),
                      ],
                      icon: const Icon(Icons.filter_list, color: Colors.deepOrange, size: 20), // Smaller icon
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13, // Smaller font
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- Summary Card ---
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced margins
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Slightly smaller border radius
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Reduced padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    'کۆی گشتی فرۆش', // Total Sales
                    _getTotalSales().toStringAsFixed(0), // No currency symbol for compactness, assume IQD
                    Colors.green.shade700,
                  ),
                  SizedBox(width: 10),
                  _buildStatCard(
                    'ژمارەی داواکارییەکان', // Number of Orders
                    _filteredOrders.length.toString(),
                    Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),
          // --- Order List ---
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _ordersBox.listenable(),
              builder: (context, Box<Order> box, _) {
                final orders = _filteredOrders;

                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'هیچ داواکارییەک نەدۆزرایەوە بۆ فلتەرە دیاریکراوەکان.', // No orders found for the selected filters.
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8, // Reduced horizontal margin
                        vertical: 4, // Reduced vertical margin
                      ),
                      elevation: 1, // Reduced elevation for more items
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Slightly smaller border radius
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${order.key}', // Shorter key prefix
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15, // Slightly smaller font
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _mapOrderTypeToKurdish(order.orderType),
                                    style: const TextStyle(color: Colors.white, fontSize: 11), // Smaller chip text
                                  ),
                                  backgroundColor:
                                  order.orderType == OrderType.delivery
                                      ? Colors.blue.shade600
                                      : Colors.green.shade600,
                                  visualDensity: VisualDensity.compact, // Make chip more compact
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Reduced spacing
                            Text(
                              '${order.timestamp.day}/${order.timestamp.month}/${order.timestamp.year} ${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}', // Combine date and time
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12, // Smaller font
                              ),
                            ),
                            if (order.customerName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'کڕیار: ${order.customerName}', // Customer:
                                  style: const TextStyle(fontSize: 13), // Smaller font
                                ),
                              ),
                            if (order.deliveryAddress.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0), // Reduced spacing
                                child: Text(
                                  'ناونیشان: ${order.deliveryAddress}', // Address:
                                  style: const TextStyle(fontSize: 13), // Smaller font
                                  maxLines: 1, // Limit to one line
                                  overflow: TextOverflow.ellipsis, // Add ellipsis
                                ),
                              ),
                            const SizedBox(height: 8), // Reduced spacing
                            const Text(
                              'کالاکان:', // Items:
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            // Displaying only top N items or a summary
                            ...order.items.take(2).map( // Show only top 2 items
                                  (item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1), // Reduced vertical padding
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• ${item.menuItem.name} x${item.quantity}',
                                        style: const TextStyle(fontSize: 13), // Smaller font
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${(item.menuItem.price * item.quantity).toStringAsFixed(0)}', // No currency symbol, assume IQD
                                      style: const TextStyle(fontSize: 13), // Smaller font
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (order.items.length > 2)
                              const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Text(
                                  '...زیاتر', // ...More
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            const Divider(height: 16, thickness: 0.5), // Thinner, shorter divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'کۆی گشتی: ${order.total.toStringAsFixed(0)}', // TOTAL:
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16, // Slightly smaller total font
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        var printReceipt = <Map<String, dynamic>>[];
                                        printReceipt.add({
                                          'id': order.key?.toString() ?? 'N/A', // Use order.key for the ID
                                          'order_title': '#${order.key?.toString() ?? 'N/A'}',
                                          'order_type': _mapOrderTypeToEnglish(order.orderType),
                                          'customer_name': order.customerName,
                                          'delivery_address': order.deliveryAddress,
                                          'date': '${order.timestamp.day}/${order.timestamp.month}/${order.timestamp.year}',
                                          'time': '${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}',
                                          'total': order.total.toStringAsFixed(0),
                                          'items': order.items.map((item) {
                                            return {
                                              'name': item.menuItem.name,
                                              'quantity': item.quantity,
                                              'price': item.menuItem.price.toStringAsFixed(0),
                                              'subtotal': (item.menuItem.price * item.quantity).toStringAsFixed(0),
                                            };
                                          }).toList(),
                                        });

                                        if (printReceipt.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BluetoothPrintPage(
                                                printData: printReceipt,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.print),
                                      tooltip: 'چاپکردنی وەسڵ', // Print Receipt
                                      color: Colors.deepOrange, // Icon color
                                      iconSize: 22, // Smaller icon size
                                      visualDensity: VisualDensity.compact, // Make button more compact
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteOrder(order.key),
                                      icon: const Icon(Icons.delete_forever),
                                      tooltip: 'سڕینەوەی داواکاری', // Delete Order
                                      color: Colors.red.shade700,
                                      iconSize: 22, // Smaller icon size
                                      visualDensity: VisualDensity.compact, // Make button more compact
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8), // Smaller border radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13), // Smaller font
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              value,
              style: TextStyle(
                fontSize: 18, // Smaller font
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to map OrderType to Kurdish text
  String _mapOrderTypeToKurdish(OrderType type) {
    switch (type) {
      case OrderType.onsite:
        return 'لە شوێن'; // Onsite
      case OrderType.delivery:
        return 'گەیاندن'; // Delivery
      default:
        return type.name.capitalize();
    }
  }
  String _mapOrderTypeToEnglish(OrderType type) {
    switch (type) {
      case OrderType.onsite:
        return 'On Site'; // Onsite
      case OrderType.delivery:
        return 'Delivery'; // Delivery
      default:
        return type.name.capitalize();
    }
  }
}

// Extension to capitalize the first letter of a string (already provided)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}