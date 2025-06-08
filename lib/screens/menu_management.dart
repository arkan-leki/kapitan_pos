import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kapitan_pos/models/menu_item.dart'; // Your MenuItem model with Hive annotations
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  late Box<MenuItem> _menuItemsBox;

  @override
  void initState() {
    super.initState();
    _initHiveBox();
  }

  Future<void> _initHiveBox() async {
    try {
      _menuItemsBox = await Hive.openBox<MenuItem>('menuItems');
      setState(() {
        // Rebuild the UI once the box is open
      });
    } catch (e) {
      debugPrint('هەڵە لە بارکردنی خشتەی خواردنەکان: $e'); // Error initializing menu items Hive box
      _showSnackBar(
        'هەڵە لە بارکردنی خشتەی خواردنەکان. تکایە ئەپەکە دابخە و دووبارە بیکەرەوە.', // Failed to load menu items. Please restart the app.
        isError: true,
      );
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

  void _addMenuItem() {
    showDialog(
      context: context,
      builder:
          (context) => AddEditMenuItemDialog(
        onSave: (newItem) async {
          // Generate a new unique ID for the item.
          // This ensures each new item has a distinct key in Hive.
          final newId =
          _menuItemsBox.isEmpty
              ? 1
              : (_menuItemsBox.keys.cast<int>().fold<int>(
            0,
                (max, id) => id > max ? id : max,
          ) +
              1);
          final itemToAdd = newItem.copyWith(
            id: newId,
          ); // Assign the new ID
          await _menuItemsBox.put(itemToAdd.id, itemToAdd); // Save to Hive
          // No need for setState() if using ValueListenableBuilder, but it's good practice
          // to call it if you want immediate state changes in your widget's local state.
          setState(() {});
          _showSnackBar('Menu item added successfully!');
        },
      ),
    );
  }

  void _editMenuItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AddEditMenuItemDialog(
        item: item,
        onSave: (updatedItem) async {
          // Use the original item's ID when updating
          await _menuItemsBox.put(item.id, updatedItem);
          _showSnackBar('خواردنەکە بە سەرکەوتوویی نوێکرایەوە!'); // Menu item updated successfully!
        },
      ),
    );
  }

  void _deleteMenuItem(MenuItem item) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دڵنیابوونەوە لە سڕینەوە'), // Confirm Deletion
        content: Text('دڵنیایت دەتەوێت "${item.name}" بسڕیتەوە؟'), // Are you sure you want to delete...?
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('هەڵوەشاندنەوە'), // Cancel
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('سڕینەوە'), // Delete
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _menuItemsBox.delete(item.id);
      _showSnackBar('خواردنەکە سڕایەوە.'); // Menu item deleted.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('menuItems')) {
      return Scaffold(
        appBar: AppBar(title: const Text('ڕێکخستنی خشتەی خواردن')), // Menu Management
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('خشتەی خواردنەکان باردەکرێن...'), // Loading menu items...
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ڕێکخستنی خشتەی خواردن'), // Menu Management
        backgroundColor: Colors.deepOrange, // A vibrant color
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28), // Larger icon
            onPressed: _addMenuItem,
            tooltip: 'زیادکردنی خواردنی نوێ', // Add new item
          ),
          const SizedBox(width: 8), // Spacing
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _menuItemsBox.listenable(),
        builder: (context, Box<MenuItem> box, _) {
          final items = box.values.toList();

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'هیچ خواردنێک لە خشتەکەدا نییە. کرتە لە دوگمەی "+" بکە بۆ زیادکردنی خواردنی نوێ!', // No menu items available. Tap the "+" button to add new items!
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Image/Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            ? (item.imageUrl!.startsWith('http'))
                            ? Image.network(
                          item.imageUrl!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('هەڵە لە بارکردنی وێنەی تۆڕ: $error'); // Error loading network image
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        )
                            : Image.file(
                          File(item.imageUrl!),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('هەڵە لە بارکردنی وێنەی ناوخۆیی: $error'); // Error loading local image
                            return Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        )
                            : Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(Icons.fastfood, size: 40, color: Colors.deepOrange.shade400),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'نرخ: \$${item.price.toStringAsFixed(0)}', // Price
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'پۆل: ${item.category}', // Category
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade600),
                            onPressed: () => _editMenuItem(item),
                            tooltip: 'دەستکاریکردن', // Edit
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red.shade600),
                            onPressed: () => _deleteMenuItem(item),
                            tooltip: 'سڕینەوە', // Delete
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
    );
  }
}

// --- Add/Edit Menu Item Dialog ---
class AddEditMenuItemDialog extends StatefulWidget {
  final MenuItem? item;
  final Function(MenuItem) onSave;

  const AddEditMenuItemDialog({super.key, this.item, required this.onSave});

  @override
  State<AddEditMenuItemDialog> createState() => _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState extends State<AddEditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  File? _selectedImageFile; // For local image preview/saving
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _categoryController.text = widget.item!.category;
      _imageUrlController.text = widget.item!.imageUrl ?? '';

      if (widget.item!.imageUrl != null &&
          !widget.item!.imageUrl!.startsWith('http')) {
        final file = File(widget.item!.imageUrl!);
        if (file.existsSync()) {
          _selectedImageFile = file;
        } else {
          _imageUrlController.text = '';
          debugPrint('وێنەی ناوخۆیی بوونی نییە: ${widget.item!.imageUrl}'); // Existing local image file not found
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _saveImageLocally(pickedFile.path);
    }
  }

  Future<void> _saveImageLocally(String tempPath) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final String localPath = '${appDocDir.path}/$fileName';

      final File originalFile = File(tempPath);
      await originalFile.copy(localPath);

      setState(() {
        _selectedImageFile = File(localPath);
        _imageUrlController.text = localPath;
      });
      debugPrint('وێنە بە ناوخۆیی پاشەکەوتکرا: $localPath'); // Image saved locally at
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('وێنە بە ناوخۆیی پاشەکەوتکرا.'))); // Image saved locally.
      }
    } catch (e) {
      debugPrint('هەڵە لە پاشەکەوتکردنی وێنە بە ناوخۆیی: $e'); // Error saving image locally
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('هەڵە لە پاشەکەوتکردنی وێنە بە ناوخۆیی: $e')), // Failed to save image locally
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.all(24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Text(
        widget.item == null ? 'زیادکردنی خواردنی نوێ' : 'دەستکاریکردنی خواردن', // Add New Item / Edit Item
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ناوی خواردن', // Item Name
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.restaurant_menu),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'تکایە ناوێک بنووسە' : null, // Please enter a name
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'نرخ', // Price
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'تکایە نرخێک بنووسە'; // Please enter a price
                  if (double.tryParse(value!) == null) {
                    return 'تکایە ژمارەیەکی دروست بنووسە'; // Please enter a valid number
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'پۆل', // Category
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'تکایە پۆلێک بنووسە' : null, // Please enter a category
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'ڕێڕەوی وێنە/URL', // Image Path/URL
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.image),
                      ),
                      readOnly: true,
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('هەڵبژاردنی وێنە'), // Select Image
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade100,
                      foregroundColor: Colors.deepOrange.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Image Preview
              if (_selectedImageFile != null && _selectedImageFile!.existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.file(
                    _selectedImageFile!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('هەڵە لە نمایشکردنی وێنەی ناوخۆیی: $error'); // Error displaying local image
                      return Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      );
                    },
                  ),
                )
              else if (_imageUrlController.text.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    _imageUrlController.text,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('هەڵە لە نمایشکردنی وێنەی تۆڕ: $error'); // Error displaying network image
                      return Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      );
                    },
                  ),
                )
              else if (_imageUrlController.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'ڕێڕەوی وێنەکە نادروستە یان فایلەکە نەدۆزرایەوە.', // Invalid image path or file not found.
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'هەڵوەشاندنەوە', // Cancel
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final newItem = MenuItem(
                // Use the existing ID for edits, or 0 for new items (it will be assigned by Hive in parent)
                id: widget.item?.id ?? 0, // Pass existing ID if editing, otherwise it will be auto-generated
                name: _nameController.text,
                price: double.parse(_priceController.text),
                category: _categoryController.text,
                imageUrl: _imageUrlController.text.isNotEmpty
                    ? _imageUrlController.text
                    : null,
              );
              widget.onSave(newItem);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('پاشەکەوتکردن'), // Save
        ),
      ],
    );
  }
}