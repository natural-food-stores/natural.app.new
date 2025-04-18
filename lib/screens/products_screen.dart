import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../admin/add_product_screen.dart';
import '../admin/edit_product_screen.dart'; // You'll need to create this

class ProductsScreen extends StatefulWidget {
  // Use const constructor if possible
  const ProductsScreen({super.key}); // Use super parameters

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  List<String> _categories = ['All Categories'];

  // Indian Rupee formatter
  final _rupeeFormat = NumberFormat.currency(
    locale: 'hi_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.fetchProducts();

      // Extract unique categories safely
      final Set<String> categorySet = {'All Categories'};
      for (var product in products) {
        // Handle potential null or empty categories
        if (product.category != null && product.category!.isNotEmpty) {
          categorySet.add(product.category!);
        }
      }

      // Sort categories alphabetically (optional, keeps 'All Categories' first)
      final sortedCategories = categorySet.toList()
        ..sort((a, b) {
          if (a == 'All Categories') return -1;
          if (b == 'All Categories') return 1;
          return a.compareTo(b);
        });

      setState(() {
        _products = products;
        _filteredProducts = products; // Initialize filtered list
        _categories = sortedCategories;
        _isLoading = false;
      });
      _filterProducts(); // Apply initial filter
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Filter by category
        final categoryMatch = _selectedCategory == 'All Categories' ||
            product.category == _selectedCategory;

        // Filter by search query (handle null description)
        final searchLower = _searchQuery.toLowerCase();
        final searchMatch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchLower) ||
            // *** FIX 6: Use null-aware operator or default value for description ***
            (product.description ?? '').toLowerCase().contains(searchLower);

        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false), // Return false on cancel
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true), // Return true on confirm
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Proceed only if confirmed (confirm == true)
    if (confirm == true && mounted) {
      try {
        await _productService.deleteProduct(product.id);
        // No need to call _loadProducts, just remove from the current list
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
          _filterProducts(); // Re-apply filters to update UI
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product.name}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        elevation: 1, // Subtle elevation
        backgroundColor: Colors.white, // Match filter section
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Wait for AddProductScreen to return, refresh if a product was added (e.g., return true)
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadProducts(); // Refresh if a product was added
          }
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterSection(),
                Expanded(
                  child: _filteredProducts.isEmpty &&
                          !_isLoading // Check isLoading false
                      ? _buildEmptyState()
                      : _buildProductsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom padding
      decoration: BoxDecoration(
          color: Colors.white, // Consistent background
          border: Border(
              bottom: BorderSide(color: Colors.grey.shade300)) // Separator line
          ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or description...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                // Consistent border style
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                // Highlight on focus
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12), // Adjust padding
              isDense: true, // Make it slightly more compact
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterProducts();
              });
            },
          ),
          const SizedBox(height: 12), // Adjust spacing
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
                bottom: 8), // Padding for scrollbar visibility
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterProducts();
                        });
                      }
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.green
                        .withOpacity(0.15), // Softer selection color
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16)), // More rounded
                    side: BorderSide(
                        color: isSelected
                            ? Colors.green.shade100
                            : Colors.grey.shade300), // Subtle border
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.green : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13, // Slightly smaller font
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // Adjust padding
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap, // Tighter tap area
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        // Add padding around the empty state content
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off, // More relevant icon for filtering
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All Categories'
                  ? 'No products match your filters'
                  : 'No products added yet', // More accurate initial state message
              textAlign: TextAlign.center, // Center align text
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16), // Add space before button
            if (_searchQuery.isNotEmpty ||
                _selectedCategory != 'All Categories')
              ElevatedButton.icon(
                // Use ElevatedButton for clearer action
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Filters'),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All Categories';
                    _filterProducts();
                    // Optionally clear the text field controller if you use one
                  });
                },
                style: ElevatedButton.styleFrom(
                    // Use primary color from theme if available
                    // backgroundColor: Theme.of(context).colorScheme.secondary,
                    // foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14)),
              )
            else
              ElevatedButton.icon(
                // Button to add product when list is truly empty
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add First Product'),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddProductScreen()));
                  if (result == true && mounted) {
                    _loadProducts();
                  }
                },
                style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200) // Subtle border
                ),
            elevation: 1.5, // Slight elevation
            clipBehavior:
                Clip.antiAlias, // Ensure InkWell splash stays within borders
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  // Expect bool result
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(
                      product: product,
                    ),
                  ),
                );
                // Refresh only if EditScreen indicated a change (returned true)
                if (result == true && mounted) {
                  _loadProducts();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(product.imageUrl!),
                                fit: BoxFit.cover,
                                onError: (e, s) {}, // Basic error handling
                              )
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (product.imageUrl == null ||
                              product.imageUrl!.isEmpty)
                          ? const Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: Colors.grey, size: 32))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // *** FIX 7: Use null-aware operator or default value for description ***
                            product.description ?? 'No description available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            // Chips for category and stock
                            children: [
                              if (product.category != null &&
                                  product.category!.isNotEmpty)
                                _buildInfoChip(product.category!, Colors.green),
                              if (product.category != null &&
                                  product.category!.isNotEmpty)
                                const SizedBox(width: 8),
                              _buildStockChip(product.quantity),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // Space before price/actions
                    // Price and actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Align price top, actions bottom
                      mainAxisSize: MainAxisSize.max, // Take full height
                      children: [
                        Text(
                          _rupeeFormat.format(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20), // Space down to actions
                        Row(
                          // Actions row
                          mainAxisSize:
                              MainAxisSize.min, // Row takes minimum space
                          children: [
                            _buildActionButton(
                              icon: Icons.edit,
                              color: Colors.blue.shade700,
                              tooltip: 'Edit Product',
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EditProductScreen(
                                            product: product)));
                                if (result == true && mounted) {
                                  _loadProducts();
                                }
                              },
                            ),
                            const SizedBox(width: 8), // Space between buttons
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              color: Colors.red.shade700,
                              tooltip: 'Delete Product',
                              onPressed: () {
                                _deleteProduct(
                                    product); // Calls method with confirmation dialog
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for consistent info chips
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Helper widget for stock chip with colors
  Widget _buildStockChip(int quantity) {
    Color bgColor;
    Color textColor;
    String label;

    if (quantity <= 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = 'Out of Stock';
    } else if (quantity < 10) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      label = '$quantity';
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      label = '$quantity';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper for consistent action buttons
  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required String tooltip,
      required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 20,
      padding: const EdgeInsets.all(4), // Reduced padding
      constraints: const BoxConstraints(), // Remove default constraints
      splashRadius: 20, // Control splash radius
      visualDensity: VisualDensity.compact, // Make it more compact
    );
  }
}
