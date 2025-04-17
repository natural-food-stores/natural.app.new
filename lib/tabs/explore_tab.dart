// screens/tabs/explore_tab.dart
import 'package:flutter/material.dart';
import '../services/product_service.dart'; // Import ProductService
import '../models/product.dart'; // Import Product model
import '../widgets/product_card.dart'; // Import ProductCard widget

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  // --- State Variables ---
  String?
      _selectedCategory; // Currently selected category (null means show categories)
  Future<List<Product>>? _filteredProductsFuture; // Future for loading products
  final ProductService _productService = ProductService(); // Service instance

  // --- Category Definitions (Ideally move to constants or fetch) ---
  final List<String> _categories = const [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Bakery',
    'Beverages',
    'Snacks',
    'Other'
  ];
  final Map<String, IconData> _categoryIcons = const {
    'Fruits': Icons.apple_outlined,
    'Vegetables': Icons.local_florist_outlined,
    'Dairy': Icons.egg_alt_outlined,
    'Bakery': Icons.bakery_dining_outlined,
    'Beverages': Icons.local_cafe_outlined,
    'Snacks': Icons.fastfood_outlined,
    'Other': Icons.category_outlined,
  };
  // --------------------------------------------------------------

  // --- Methods ---
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      // Trigger fetching products for the selected category
      _filteredProductsFuture =
          _productService.fetchProductsByCategory(category);
    });
  }

  void _clearCategorySelection() {
    setState(() {
      _selectedCategory = null;
      _filteredProductsFuture = null; // Clear the future
    });
  }
  // ---------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar here as requested
      body: _selectedCategory == null
          ? _buildCategoryGrid(context) // Show category grid if none selected
          : _buildFilteredProductList(
              context), // Show products if category selected
    );
  }

  // --- Widget Builder for Category Grid ---
  Widget _buildCategoryGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.1,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final icon = _categoryIcons[category] ?? Icons.category_outlined;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _selectCategory(category), // Call state update method
            splashColor: colorScheme.primary.withOpacity(0.1),
            highlightColor: colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 48.0, color: colorScheme.primary),
                  const SizedBox(height: 12.0),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // -----------------------------------------

  // --- Widget Builder for Filtered Product List ---
  Widget _buildFilteredProductList(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header with Back Button and Title ---
        Padding(
          padding: const EdgeInsets.only(
              top: kToolbarHeight * 0.7,
              left: 8,
              right: 8,
              bottom: 10), // Add top padding similar to AppBar height
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearCategorySelection, // Go back to category grid
                tooltip: 'Back to Categories',
              ),
              const SizedBox(width: 10),
              Expanded(
                // Use Expanded to allow title to take space
                child: Text(
                  _selectedCategory!, // Display selected category name
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // -----------------------------------------

        // --- FutureBuilder for Products ---
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _filteredProductsFuture,
            builder: (context, snapshot) {
              // Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Error State
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading products for $_selectedCategory: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              // Empty State
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No products found in the $_selectedCategory category.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Success State - Display Products
              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16.0, 0, 16.0, 16.0), // Adjust padding
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0, // Consistent spacing
                  mainAxisSpacing: 12.0, // Consistent spacing
                  childAspectRatio:
                      0.75, // Consistent aspect ratio from HomeTab
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  // Use the existing ProductCard widget
                  return ProductCard(product: products[index]);
                },
              );
            },
          ),
        ),
        // ----------------------------------
      ],
    );
  }
  // ---------------------------------------------
}
