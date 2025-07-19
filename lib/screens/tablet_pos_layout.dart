import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/models/menu_item.dart';
import 'package:kapitan_pos/models/order.dart';
import 'package:kapitan_pos/models/order_item.dart';

class TabletPOSLayout extends StatelessWidget {
  // --- Properties received from POSScreenState ---
  final List<OrderItem> currentOrder;
  final OrderType orderType;
  final TextEditingController customerNameController;
  final TextEditingController deliveryAddressController;
  final Box<MenuItem> menuItemsBox;
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final Function(MenuItem) onAddToOrder;
  final Function(int) onRemoveFromOrder;
  final VoidCallback onClearOrder;
  final VoidCallback onSubmitOrder;
  final Function(String, {bool isError}) showSnackBar;
  final Function(OrderType) onOrderTypeChanged;
  final Function(OrderType) mapOrderTypeToEnglish; // Passed for print dialog logic

  const TabletPOSLayout({
    super.key,
    required this.currentOrder,
    required this.orderType,
    required this.customerNameController,
    required this.deliveryAddressController,
    required this.menuItemsBox,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddToOrder,
    required this.onRemoveFromOrder,
    required this.onClearOrder,
    required this.onSubmitOrder,
    required this.showSnackBar,
    required this.onOrderTypeChanged,
    required this.mapOrderTypeToEnglish,
  });

  // Widget to display the products grid
  Widget _buildProductsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Slightly increased padding
      child: Column(
        children: [
          // Category Filter
          if (categories.isNotEmpty)
            SizedBox(
              height: 50, // Consistent height for categories
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category ||
                      (selectedCategory == null && category == 'هەمووی');

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: const TextStyle(fontSize: 16),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          onCategorySelected((category == 'هەمووی') ? null : category);
                        } else {
                          if (category != 'هەمووی') {
                            onCategorySelected(null);
                          }
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 18, // Increased padding for touch
                        vertical: 10,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Products grid
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: menuItemsBox.listenable(),
              builder: (context, Box<MenuItem> box, _) {
                final allMenuItems = box.values.toList();
                final filteredMenuItems = selectedCategory == null
                    ? allMenuItems
                    : allMenuItems
                    .where(
                      (item) => item.category == selectedCategory,
                )
                    .toList();

                if (filteredMenuItems.isEmpty) {
                  return Center(
                    child: Text(
                      selectedCategory == null
                          ? 'هیچ شتێکی مینیو بەردەست نییە. لە شاشەی بەڕێوەبردنی مینیوەوە هەندێکیان زیاد بکە!'
                          : 'هیچ شتێک لە کەتێگۆری "${selectedCategory!}" بەردەست نییە.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18), // Larger font for tablet
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12), // Increased padding
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 900 ? 3 : 4, // Adaptive for tablet landscape
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12, // Increased spacing
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredMenuItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredMenuItems[index];
                    return Card(
                      elevation: 6, // Slightly higher elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // More rounded corners
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onAddToOrder(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                      ? (item.imageUrl!.startsWith('http'))
                                      ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading network image for ${item.name}: $error');
                                      return const Center(
                                        child: Icon(Icons.broken_image, size: 70, color: Colors.grey),
                                      );
                                    },
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                      : Image.file(
                                    File(item.imageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading local image for ${item.name}: $error');
                                      return const Center(
                                        child: Icon(Icons.broken_image, size: 70, color: Colors.grey),
                                      );
                                    },
                                  )
                                      : const Center(
                                    child: Icon(Icons.fastfood, size: 70, color: Colors.grey), // Larger icon
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, // Increased vertical padding
                                        horizontal: 12.0,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20, // Larger font
                                          color: Colors.white,
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
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.price.toStringAsFixed(0),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22, // Larger price font
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
        ],
      ),
    );
  }

  // Widget to display the order details
  Widget _buildOrderDetails(BuildContext context) {
    final total = currentOrder.fold(
      0.0,
          (sum, item) => sum + (item.menuItem.price * item.quantity),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide( // Border on left for landscape layout
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0), // Increased padding
            child: Text(
              'داواکاری ئێستا',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28), // Larger title
            ),
          ),
          if (currentOrder.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 12.0), // Increased padding
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'کاڵا',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 18, // Larger font
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100, // Wider for quantity
                    child: Text(
                      'بڕ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 100, // Wider for total
                    child: Text(
                      'کۆ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: currentOrder.isEmpty
                ? const Center(
              child: Text(
                'هیچ کاڵایەک زیاد نەکراوە',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Increased padding
              itemCount: currentOrder.length,
              itemBuilder: (context, index) {
                final item = currentOrder[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // Increased vertical padding
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.menuItem.name, style: const TextStyle(fontSize: 18)), // Larger font
                      ),
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 24), // Smaller icon
                              onPressed: () => onRemoveFromOrder(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // Adjusted min touch target
                            ),
                            Text(item.quantity.toString(), style: const TextStyle(fontSize: 18)), // Larger font
                            IconButton(
                              icon: const Icon(Icons.add, size: 24), // Smaller icon
                              onPressed: () => onAddToOrder(item.menuItem),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // Adjusted min touch target
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          (item.menuItem.price * item.quantity).toStringAsFixed(0),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 18), // Larger font
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
          if (currentOrder.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 16.0), // Increased padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'کۆ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26, // Larger font
                    ),
                  ),
                  Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26, // Larger font
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                children: [
                  const Text(
                    'جۆری داواکاری:',
                    style: TextStyle(fontSize: 18), // Larger font
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text(
                            'لەشوين',
                            style: TextStyle(fontSize: 18), // Larger font
                          ),
                          selected: orderType == OrderType.onsite,
                          onSelected: (selected) {
                            if (selected) {
                              onOrderTypeChanged(OrderType.onsite);
                            }
                          },
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(
                            color: orderType == OrderType.onsite
                                ? Colors.white
                                : Colors.black,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text(
                            'گەیاندن',
                            style: TextStyle(fontSize: 18), // Larger font
                          ),
                          selected: orderType == OrderType.delivery,
                          onSelected: (selected) {
                            if (selected) {
                              onOrderTypeChanged(OrderType.delivery);
                            }
                          },
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: orderType == OrderType.delivery
                                ? Colors.white
                                : Colors.black,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Customer info (for delivery)
            if (orderType == OrderType.delivery) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: TextField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'ناوی کڕیار',
                    border: OutlineInputBorder(),
                    hintText: 'ناوی کڕیار سەرپشک',
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Larger input field
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: TextField(
                  controller: deliveryAddressController,
                  decoration: const InputDecoration(
                    labelText: 'ناونیشانی گەیاندن *',
                    border: OutlineInputBorder(),
                    hintText: 'ناونیشان داخلبکە',
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Larger input field
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Padding(
              padding: const EdgeInsets.all(20.0), // Increased padding
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 24), // Smaller icon
                      onPressed: onClearOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16), // Adjusted vertical padding
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // More rounded
                      ),
                      label: const Text('سڕینەوەی هەموو', style: TextStyle(fontSize: 18)), // Larger font
                    ),
                  ),
                  const SizedBox(width: 20), // Increased spacing
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 24), // Smaller icon
                      onPressed: onSubmitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16), // Adjusted vertical padding
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // More rounded
                      ),
                      label: const Text('ناردنی داواکاری', style: TextStyle(fontSize: 18)), // Larger font
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adjust flex values based on screen width for landscape mode
    int productsFlex = 3;
    int orderDetailsFlex = 2;

    if (MediaQuery.of(context).size.width < 900) {
      productsFlex = 2;
      orderDetailsFlex = 1;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: productsFlex,
          child: _buildProductsGrid(context),
        ),
        Expanded(
          flex: orderDetailsFlex,
          child: _buildOrderDetails(context),
        ),
      ],
    );
  }
}
