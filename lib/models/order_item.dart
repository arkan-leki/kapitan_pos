import 'package:hive/hive.dart';
import 'package:kapitan_pos/models/menu_item.dart'; // Import MenuItem as it's part of OrderItem

// This line tells Dart to look for a generated file named 'order_item.g.dart'
// which will contain the Hive adapter for this class.
part 'order_item.g.dart';

@HiveType(typeId: 2) // Assign a unique type ID for this class
class OrderItem {
  @HiveField(0) // Assign a unique field ID for each property
  final MenuItem menuItem;
  @HiveField(1)
  final int quantity;

  OrderItem({required this.menuItem, required this.quantity});

  // A helper method to create a new OrderItem instance with updated values.
  // This is useful for immutability and convenient updates, specifically for quantity.
  OrderItem copyWith({MenuItem? menuItem, int? quantity}) {
    return OrderItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}
