import 'package:hive/hive.dart';
import 'package:kapitan_pos/models/order_item.dart';

part 'order.g.dart';

@HiveType(typeId: 1) // Assign a unique type ID for this enum
enum OrderType {
  @HiveField(0) // Assign a unique field ID for each enum value
  onsite,
  @HiveField(1)
  delivery,
}

@HiveType(typeId: 3) // Assign a unique type ID for this class
class Order extends HiveObject { // Extend HiveObject to access key/id directly if needed
  // Removed the explicit 'id' field.
  // Hive's auto-incrementing key can be accessed via 'this.key'
  // after the object has been added to a Hive box.

  @HiveField(1) // Shifted field IDs up as field 0 is removed
  final List<OrderItem> items;
  @HiveField(2)
  final OrderType orderType;
  @HiveField(3)
  final String customerName;
  @HiveField(4)
  final String deliveryAddress;
  @HiveField(5)
  final DateTime timestamp;

  Order({
    required this.items,
    required this.orderType,
    this.customerName = '', // Default empty string
    this.deliveryAddress = '', // Default empty string
    required this.timestamp,
  });

  // A getter to calculate the total price of the order.
  double get total => items.fold(
    0.0,
        (sum, item) => sum + (item.menuItem.price * item.quantity),
  );
}
