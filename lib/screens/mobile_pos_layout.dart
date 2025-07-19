import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/models/menu_item.dart';
import 'package:kapitan_pos/models/order.dart';
import 'package:kapitan_pos/models/order_item.dart';

class MobilePOSLayout extends StatefulWidget {
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
  final Function(OrderType)
  mapOrderTypeToEnglish; // Passed for print dialog logic

  const MobilePOSLayout({
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

  @override
  State<MobilePOSLayout> createState() => _MobilePOSLayoutState();
}

class _MobilePOSLayoutState extends State<MobilePOSLayout> {
  // Widget to display the products grid
  Widget _buildProductsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4), // Reduced padding
      child: Column(
        children: [
          // Category Filter
          if (widget.categories.isNotEmpty)
            SizedBox(
              height: 40, // Reduced height for categories
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  final isSelected =
                      widget.selectedCategory == category ||
                      (widget.selectedCategory == null && category == 'هەمووی');

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ), // Reduced horizontal padding
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14,
                        ), // Reduced font size
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          widget.onCategorySelected(
                            (category == 'هەمووی') ? null : category,
                          );
                        } else {
                          if (category != 'هەمووی') {
                            widget.onCategorySelected(null);
                          }
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10, // Reduced padding for touch
                        vertical: 6, // Reduced vertical padding
                      ),
                    ),
                  );
                },
              ),
            ),
          // Products grid
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: widget.menuItemsBox.listenable(),
              builder: (context, Box<MenuItem> box, _) {
                final allMenuItems = box.values.toList();
                final filteredMenuItems =
                    widget.selectedCategory == null
                        ? allMenuItems
                        : allMenuItems
                            .where(
                              (item) =>
                                  item.category == widget.selectedCategory,
                            )
                            .toList();

                if (filteredMenuItems.isEmpty) {
                  return Center(
                    child: Text(
                      widget.selectedCategory == null
                          ? 'هیچ شتێکی مینیو بەردەست نییە. لە شاشەی بەڕێوەبردنی مینیوەوە هەندێکیان زیاد بکە!'
                          : 'هیچ شتێک لە کەتێگۆری "${widget.selectedCategory!}" بەردەست نییە.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14), // Reduced font size
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(4), // Reduced padding
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Optimized for mobile portrait
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 4, // Reduced spacing
                    mainAxisSpacing: 4, // Reduced spacing
                  ),
                  itemCount: filteredMenuItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredMenuItems[index];
                    return Card(
                      elevation: 2, // Reduced elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // Reduced roundedness
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.onAddToOrder(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  (item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty)
                                      ? (item.imageUrl!.startsWith('http'))
                                          ? Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              debugPrint(
                                                'Error loading network image for ${item.name}: $error',
                                              );
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ), // Reduced icon size
                                              );
                                            },
                                            loadingBuilder: (
                                              BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
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
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              debugPrint(
                                                'Error loading local image for ${item.name}: $error',
                                              );
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ), // Reduced icon size
                                              );
                                            },
                                          )
                                      : const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 40,
                                          color: Colors.grey,
                                        ), // Reduced icon size
                                      ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical:
                                            4.0, // Reduced vertical padding
                                        horizontal:
                                            8.0, // Reduced horizontal padding
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(
                                              0.6,
                                            ), // Slightly less opaque
                                          ],
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(8),
                                            ),
                                      ),
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12, // Reduced font size
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
                                padding: const EdgeInsets.all(
                                  4.0,
                                ), // Reduced padding
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.price.toStringAsFixed(0),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14, // Reduced price font
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

  // Widget to display the order details (now directly in the layout)
  Widget _buildOrderDetails(BuildContext context, double total) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            // Border on top for portrait layout
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(
        8.0,
      ), // Padding for the entire order details section
      child: Column(
        mainAxisSize:
            MainAxisSize
                .max, // Ensures the column takes max height of its parent
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0), // Adjusted padding
            child: Text(
              'داواکاری ئێستا',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
              ), // Adjusted title size
            ),
          ),
          if (widget.currentOrder.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 4.0,
              ), // Adjusted vertical padding
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'کاڵا',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 14, // Adjusted font
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90, // Adjusted width for quantity controls
                    child: Text(
                      'بڕ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 60, // Adjusted width for total
                    child: Text(
                      'کۆ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            // Now Expanded is used here to make ListView fill available space
            child:
                widget.currentOrder.isEmpty
                    ? const Center(
                      child: Text(
                        'هیچ کاڵایەک زیاد نەکراوە',
                        style: TextStyle(fontSize: 14), // Adjusted font
                      ),
                    )
                    : ListView.separated(
                      shrinkWrap: true, // Still useful if content is small
                      physics:
                          const ClampingScrollPhysics(), // Prevents nested scrolling issues
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ), // Reduced padding
                      itemCount: widget.currentOrder.length,
                      itemBuilder: (context, index) {
                        final item = widget.currentOrder[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                            vertical: 1.0,
                          ), // Reduced vertical padding
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.menuItem.name,
                                  style: const TextStyle(fontSize: 14),
                                ), // Adjusted font
                              ),
                              SizedBox(
                                width:
                                    90, // Adjusted width to fit buttons and text
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        size: 18,
                                      ), // Smaller icon
                                      onPressed:
                                          () => widget.onRemoveFromOrder(
                                            index,
                                          ), // Use decrement for this button
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ), // Min touch target
                                    ),
                                    Text(
                                      item.quantity.toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ), // Adjusted font
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        size: 18,
                                      ), // Smaller icon
                                      onPressed:
                                          () => widget.onAddToOrder(
                                            item.menuItem,
                                          ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ), // Min touch target
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 60, // Adjusted width
                                child: Text(
                                  (item.menuItem.price * item.quantity)
                                      .toStringAsFixed(0),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ), // Adjusted font
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                    ),
          ),
          // Customer info (for delivery)
          if (widget.orderType == OrderType.delivery) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              child: TextField(
                controller: widget.customerNameController,
                decoration: const InputDecoration(
                  labelText: 'ناوی کڕیار',
                  border: OutlineInputBorder(),
                  hintText: 'ناوی کڕیار سەرپشک',
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 8.0,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              child: TextField(
                controller: widget.deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'ناونیشانی گەیاندن *',
                  border: OutlineInputBorder(),
                  hintText: 'ناونیشان داخلبکە',
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 8.0,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
          ],
          // Total and Action Buttons - fixed at the bottom of the section
          if (widget.currentOrder.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'کۆ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      onPressed: widget.onClearOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      label: const Text(
                        'سڕینەوەی هەموو',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      onPressed: widget.onSubmitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      label: const Text(
                        'ناردنی داواکاری',
                        style: TextStyle(fontSize: 14),
                      ),
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
    // Calculate total here, so it's accessible to both sections
    final total = widget.currentOrder.fold(
      0.0,
      (sum, item) => sum + (item.menuItem.price * item.quantity),
    );

    return Scaffold(
      body: Column(
        // Main Column for the Scaffold body
        children: [
          // Order Type Selection - Moved to the top of the main page
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children: [
                const Text('جۆری داواکاری:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text(
                          'لەشوين',
                          style: TextStyle(fontSize: 14),
                        ),
                        selected: widget.orderType == OrderType.onsite,
                        onSelected: (selected) {
                          if (selected) {
                            widget.onOrderTypeChanged(OrderType.onsite);
                          }
                        },
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(
                          color:
                              widget.orderType == OrderType.onsite
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text(
                          'گەیاندن',
                          style: TextStyle(fontSize: 14),
                        ),
                        selected: widget.orderType == OrderType.delivery,
                        onSelected: (selected) {
                          if (selected) {
                            widget.onOrderTypeChanged(OrderType.delivery);
                          }
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color:
                              widget.orderType == OrderType.delivery
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2, // Products grid takes more space
            child: _buildProductsGrid(context),
          ),
          Expanded(
            flex: 2, // Order details take less space
            child: _buildOrderDetails(
              context,
              total,
            ), // Pass total to the order details widget
          ),
        ],
      ),
      // Removed FloatingActionButton as order details are now always visible
      // Removed FloatingActionButtonLocation
    );
  }
}
