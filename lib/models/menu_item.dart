// TODO Implement this library.
import 'package:hive/hive.dart';

// This line tells Dart to look for a generated file named 'menu_item.g.dart'
// which will contain the Hive adapter for this class.
part 'menu_item.g.dart';

@HiveType(
  typeId: 0,
) // Assign a unique type ID for this class (important for Hive)
class MenuItem {
  @HiveField(0) // Assign a unique field ID for each property
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String? imageUrl; // Made nullable for flexibility

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  // A helper method to create a new MenuItem instance with updated values.
  // This is useful for immutability and convenient updates.
  MenuItem copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id, // Use the provided ID or the current one
      name: name ?? this.name, // Use the provided name or the current one
      price: price ?? this.price, // Use the provided price or the current one
      category:
          category ??
          this.category, // Use the provided category or the current one
      imageUrl:
          imageUrl ??
          this.imageUrl, // Use the provided image URL or the current one
    );
  }
}
