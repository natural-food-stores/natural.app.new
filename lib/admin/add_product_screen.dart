// screens/add_product_screen.dart (adjust path if needed)
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart'; // Adjust path if needed

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productService = ProductService();
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  String? _selectedCategory; // <-- State variable for selected category
  bool _isLoading = false;

  // --- Define available categories ---
  // TODO: Fetch these from a database table in a real app
  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Bakery',
    'Beverages',
    'Snacks',
    'Other'
  ];
  // ---------------------------------

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image picking not supported on web yet.')));
      return;
    }
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      setState(() {
        _selectedImage = pickedFile;
      });
    } catch (e) {
      debugPrint("Image picking failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to pick image.')));
      }
    }
  }

  Future<void> _submitProduct() async {
    // Validate category selection along with the form
    if ((_formKey.currentState?.validate() ?? false) &&
        _selectedCategory != null) {
      if (_selectedImage == null && !kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a product image.')));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String? imageUrl;
      File? imageFile;

      if (_selectedImage != null && !kIsWeb) {
        imageFile = File(_selectedImage!.path);
      }

      try {
        if (imageFile != null) {
          final fileName = _selectedImage!.name;
          imageUrl = await _productService.uploadImage(imageFile, fileName);
          if (imageUrl == null) {
            throw Exception('Image upload failed.');
          }
        }

        // Pass all data including the selected category
        await _productService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          category: _selectedCategory!, // Pass selected category
          imageUrl: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to add product: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedCategory == null) {
      // Show error if category wasn't selected
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product category.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker and Preview
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Select Image")
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? const Center(child: Text('Web preview N/A'))
                                : Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    height: 150,
                                    width: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'Error loading image preview: $error');
                                      return const Center(
                                          child: Icon(Icons.error_outline,
                                              color: Colors.red));
                                    },
                                  ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Organic Apples',
                  // Using theme's input decoration
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Category Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  // Using theme's input decoration implicitly
                  // border: OutlineInputBorder(), // Uncomment if theme doesn't provide border
                ),
                hint: const Text('Select Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              // -------------------------

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Freshly picked, crisp and sweet',
                  // border: OutlineInputBorder(), // Uncomment if theme doesn't provide border
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 4.99',
                  prefixText: 'Rs. ',
                  // border: OutlineInputBorder(), // Uncomment if theme doesn't provide border
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null) {
                    return 'Please enter a valid number';
                  }
                  if (price <= 0) {
                    return 'Price must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 50',
                  // border: OutlineInputBorder(), // Uncomment if theme doesn't provide border
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quantity';
                  }
                  final quantity = int.tryParse(value.trim());
                  if (quantity == null) {
                    return 'Please enter a valid whole number';
                  }
                  if (quantity < 0) {
                    return 'Quantity cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                // Using theme's elevated button style implicitly
                onPressed: _isLoading ? null : _submitProduct,
                icon: _isLoading
                    ? Container()
                    : const Icon(Icons.add_circle_outline),
                label: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ))
                    : const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
