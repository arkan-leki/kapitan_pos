import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/models/menu_item.dart';
import 'package:kapitan_pos/models/order.dart';
import 'package:kapitan_pos/models/order_item.dart';
import '../blueprint/bluetooth_print_page.dart';


class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final List<OrderItem> _currentOrder = [];
  OrderType _orderType = OrderType.onsite;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();

  late Box<MenuItem> _menuItemsBox;
  late Box<Order> _ordersBox;

  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _initHiveBoxes().then((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _initHiveBoxes() async {
    try {
      // Ensure Hive is initialized globally (e.g., in main.dart) before opening boxes
      // await Hive.initFlutter();
      // Hive.registerAdapter(MenuItemAdapter()); // Register your adapters
      // Hive.registerAdapter(OrderAdapter());
      // Hive.registerAdapter(OrderItemAdapter());
      // Hive.registerAdapter(OrderTypeAdapter());

      _menuItemsBox = await Hive.openBox<MenuItem>('menuItems');
      _ordersBox = await Hive.openBox<Order>('orders');
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing Hive boxes: $e');
      _showSnackBar(
        'Failed to load data. Please restart the app.',
        isError: true,
      );
    }
  }

  void _loadCategories() {
    if (Hive.isBoxOpen('menuItems')) {
      final uniqueCategories = <String>{};
      _menuItemsBox.listenable().addListener(() {
        final newUniqueCategories = <String>{};
        for (var item in _menuItemsBox.values) {
          if (item.category != null && item.category!.isNotEmpty) {
            newUniqueCategories.add(item.category!);
          }
        }
        if (newUniqueCategories.length != uniqueCategories.length ||
            !newUniqueCategories.containsAll(uniqueCategories)) {
          setState(() {
            _categories = ['هەمووی', ...newUniqueCategories.toList()..sort()];
            if (_selectedCategory != null &&
                !_categories.contains(_selectedCategory)) {
              _selectedCategory = null;
            }
          });
          uniqueCategories.clear();
          uniqueCategories.addAll(newUniqueCategories);
        }
      });

      for (var item in _menuItemsBox.values) {
        if (item.category != null && item.category!.isNotEmpty) {
          uniqueCategories.add(item.category!);
        }
      }
      setState(() {
        _categories = [
          'هەمووی',
          ...uniqueCategories.toList()..sort(),
        ];
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _addToOrder(MenuItem item) {
    setState(() {
      final existingItemIndex = _currentOrder.indexWhere(
            (orderItem) => orderItem.menuItem.id == item.id,
      );
      if (existingItemIndex >= 0) {
        _currentOrder[existingItemIndex] = _currentOrder[existingItemIndex]
            .copyWith(quantity: _currentOrder[existingItemIndex].quantity + 1);
      } else {
        _currentOrder.add(OrderItem(menuItem: item, quantity: 1));
      }
    });
  }

  void _removeFromOrder(int index) {
    setState(() {
      if (_currentOrder[index].quantity > 1) {
        _currentOrder[index] = _currentOrder[index].copyWith(
          quantity: _currentOrder[index].quantity - 1,
        );
      } else {
        _currentOrder.removeAt(index);
      }
    });
  }

  void _clearOrder() {
    setState(() {
      _currentOrder.clear();
      _customerNameController.clear();
      _deliveryAddressController.clear();
      _orderType = OrderType.onsite;
    });
  }

  void _submitOrder() async {
    if (_currentOrder.isEmpty) {
      _showSnackBar('Please add items to the order', isError: true);
      return;
    }

    if (_orderType == OrderType.delivery &&
        _deliveryAddressController.text.isEmpty) {
      _showSnackBar('Please enter delivery address', isError: true);
      return;
    }

    final order = Order(
      items: List.from(_currentOrder),
      orderType: _orderType,
      customerName: _customerNameController.text,
      deliveryAddress: _deliveryAddressController.text,
      timestamp: DateTime.now(),
    );

    try {
      await _ordersBox.add(order); // Hive automatically assigns an integer key
      _showSnackBar('Order submitted successfully!');
      _printOrder(order);
      _clearOrder();
    } catch (e) {
      debugPrint('Error saving order: $e');
      _showSnackBar('Failed to submit order. Please try again.', isError: true);
    }
  }

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
                'id': order.key?.toString() ?? 'N/A', // Use order.key for the ID
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

  @override
  Widget build(BuildContext context) {
    final total = _currentOrder.fold(
      0.0,
          (sum, item) => sum + (item.menuItem.price * item.quantity),
    );

    if (!Hive.isBoxOpen('menuItems') || !Hive.isBoxOpen('orders')) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading menu and orders...'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Order type selection
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('جۆری داواکاری:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 14),
                    ChoiceChip(
                      label: const Text('لەشوين',style: TextStyle(fontSize: 14)),
                      selected: _orderType == OrderType.onsite,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _orderType = OrderType.onsite);
                        }
                      },
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(
                        color: _orderType == OrderType.onsite
                            ? Colors.white
                            : Colors.black,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Slightly reduced padding
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('گەیاندن',style: TextStyle(fontSize: 14)),
                      selected: _orderType == OrderType.delivery,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _orderType = OrderType.delivery);
                        }
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: _orderType == OrderType.delivery
                            ? Colors.white
                            : Colors.black,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Slightly reduced padding
                    ),
                  ],
                ),
              ),

              // Customer info (for delivery)
              if (_orderType == OrderType.delivery) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'ناوی کڕیار',
                      border: OutlineInputBorder(),
                      hintText: 'ناوی کڕیار سەرپشک',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _deliveryAddressController,
                    decoration: const InputDecoration(
                      labelText: 'ناونیشانی گەیاندن *',
                      border: OutlineInputBorder(),
                      hintText: 'ناونیشان داخلبکە',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Category Filter
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected =
                          _selectedCategory == category ||
                              (_selectedCategory == null && category == 'هەمووی');

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category,style: const TextStyle(fontSize: 14)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategory =
                                (category == 'هەمووی') ? null : category;
                              } else {
                                if (category != 'هەمووی') {
                                  _selectedCategory = null;
                                }
                              }
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Slightly reduced padding
                        ),
                      );
                    },
                  ),
                ),

              // Menu items grid (Enhanced UI)
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _menuItemsBox.listenable(),
                  builder: (context, Box<MenuItem> box, _) {
                    final allMenuItems = box.values.toList();
                    final filteredMenuItems = _selectedCategory == null
                        ? allMenuItems
                        : allMenuItems
                        .where((item) => item.category == _selectedCategory)
                        .toList();

                    if (filteredMenuItems.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedCategory == null
                              ? 'هیچ شتێکی مینیو بەردەست نییە. لە شاشەی بەڕێوەبردنی مینیوەوە هەندێکیان زیاد بکە!'
                              : 'هیچ شتێک لە کەتێگۆری "${_selectedCategory!}" بەردەست نییە.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        MediaQuery.of(context).size.width < 450 ? 3 : 5, // Adjusted for better view on larger screens
                        childAspectRatio: 0.8, // Slightly taller cards
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredMenuItems[index];
                        return Card(
                          elevation: 4, // Slightly more elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // More rounded corners
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _addToOrder(item),
                            borderRadius: BorderRadius.circular(8), // Match card border radius
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack( // Use Stack for image and potential overlay
                                    fit: StackFit.expand,
                                    children: [
                                      (item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty)
                                          ? (item.imageUrl!.startsWith('http'))
                                          ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                            stackTrace) {
                                          debugPrint(
                                              'Error loading network image for ${item.name}: $error');
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 50, // Larger icon
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                        loadingBuilder: (BuildContext
                                        context,
                                            Widget child,
                                            ImageChunkEvent?
                                            loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child:
                                            CircularProgressIndicator(
                                              value: loadingProgress
                                                  .expectedTotalBytes !=
                                                  null
                                                  ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      )
                                          : Image.file(
                                        File(item.imageUrl!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                            stackTrace) {
                                          debugPrint(
                                              'Error loading local image for ${item.name}: $error');
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 50, // Larger icon
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      )
                                          : const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 50, // Larger icon
                                          color: Colors.grey,
                                        ),
                                      ),
                                      // Gradient overlay for better text readability on image
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                            ),
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                          ),
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14, // Larger font size
                                              color: Colors.white, // White text for contrast
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1, // Reduced flex for text area
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0), // Increased padding
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.price.toStringAsFixed(0), // Added currency
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor, // Use primary color for price
                                            fontWeight: FontWeight.w800, // Bolder
                                            fontSize: 12, // Larger font size
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

              // This spacer pushes the content up to make room for the order summary
              if (_currentOrder.isNotEmpty)
                const SizedBox(height: 120), // Height of the order summary
            ],
          ),

          // Order summary container that sticks to the bottom
          if (_currentOrder.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'داواکاری ئێستا',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200, // Fixed height for the items list
                      child: ListView.separated(
                        scrollDirection: Axis.vertical,
                        itemCount: _currentOrder.length,
                        itemBuilder: (context, index) {
                          final item = _currentOrder[index];
                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ListTile(
                              leading: (item.menuItem.imageUrl != null &&
                                  item.menuItem.imageUrl!.isNotEmpty)
                                  ? (item.menuItem.imageUrl!.startsWith('http'))
                                  ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  item.menuItem.imageUrl!,
                                ),
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  debugPrint(
                                      'Image load error for network image in current order: $exception');
                                },
                              )
                                  : CircleAvatar(
                                backgroundImage: FileImage(
                                  File(item.menuItem.imageUrl!),
                                ),
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  debugPrint(
                                      'Image load error for local image in current order: $exception');
                                },
                              )
                                  : const CircleAvatar(
                                child: Icon(Icons.fastfood),
                              ),
                              title: Text(
                                '${item.menuItem.name} x${item.quantity}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                (item.menuItem.price * item.quantity)
                                    .toStringAsFixed(0),
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 24, // Slightly reduced icon size
                                ),
                                onPressed: () => _removeFromOrder(index),
                              ),
                            ),
                          );
                        },
                        // Corrected: separator for vertical list should be height
                        separatorBuilder: (context, index) => const SizedBox(height: 4),
                      ),
                    ),
                    const Divider(thickness: 1.5),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'کۆ:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            total.toStringAsFixed(0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded( // Makes the button take up available space
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep, size: 24), // Smaller icon
                            onPressed: _currentOrder.isEmpty
                                ? null
                                : _clearOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, // Reduced horizontal padding
                                vertical: 10,   // Reduced vertical padding
                              ),
                              textStyle: const TextStyle(fontSize: 15), // Slightly smaller font
                            ),
                            label: const Text('سڕینەوەی هەموو'),
                          ),
                        ),
                        const SizedBox(width: 16), // Add space between buttons
                        Expanded( // Makes the button take up available space
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 24), // Smaller icon
                            onPressed: _currentOrder.isEmpty
                                ? null
                                : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, // Reduced horizontal padding
                                vertical: 10,   // Reduced vertical padding
                              ),
                              textStyle: const TextStyle(fontSize: 15), // Slightly smaller font
                            ),
                            label: const Text('ناردنی داواکاری'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _mapOrderTypeToEnglish(OrderType type) {
  switch (type) {
    case OrderType.onsite:
      return 'On Site'; // Onsite
    case OrderType.delivery:
      return 'Delivery'; // Delivery
    default:
      return '';
  }
}