import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2 for coordinates
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  // --- State Variables ---
  String? _selectedCategory;
  Future<List<Product>>? _filteredProductsFuture;
  final ProductService _productService = ProductService();

  // Store coordinates
  final LatLng _storeLocation = const LatLng(19.100298, 72.890014);

  // --- Category Definitions with Color ---
  // Structure: List<Map<String, dynamic>> containing name, icon, color
  final List<Map<String, dynamic>> _categories = const [
    // Using the categories provided previously
    {'name': 'Fruits', 'icon': Icons.apple_outlined, 'color': Colors.redAccent},
    {
      'name': 'Vegetables',
      'icon': Icons.energy_savings_leaf_outlined,
      'color': Colors.green
    },
    {
      'name': 'Dairy',
      'icon': Icons.icecream_outlined,
      'color': Colors.lightBlueAccent
    },
    {
      'name': 'Bakery',
      'icon': Icons.bakery_dining_outlined,
      'color': Colors.orangeAccent
    },
    {
      'name': 'Beverages',
      'icon': Icons.local_drink_outlined,
      'color': Colors.teal
    },
    {
      'name': 'Snacks',
      'icon': Icons.fastfood_outlined,
      'color': Colors.purpleAccent
    },
    {
      'name': 'Other',
      'icon': Icons.category_outlined,
      'color': Colors.blueGrey
    },
  ];

  // --- Methods (remain the same) ---
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredProductsFuture =
          _productService.fetchProductsByCategory(category);
    });
  }

  void _clearCategorySelection() {
    setState(() {
      _selectedCategory = null;
      _filteredProductsFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Consistent background color
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _selectedCategory == null
          ? _buildCategoryGridWithMap(context)
          : _buildFilteredProductList(context),
    );
  }

  // --- Widget Builder for Category Grid with Map ---
  Widget _buildCategoryGridWithMap(BuildContext context) {
    return Column(
      children: [
        // Map section
        SizedBox(
          height: 200, // Adjust height as needed
          child: Stack(
            children: [
              // OpenStreetMap
              FlutterMap(
                options: MapOptions(
                  center: _storeLocation,
                  zoom: 15.0,
                  interactiveFlags: InteractiveFlag.all,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _storeLocation,
                        builder: (ctx) => Column(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40.0,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Natural Food Store',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Optional: Add a title or info overlay on the map
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Visit Our Store',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Title for categories section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Browse Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Categories grid
        Expanded(
          child: _buildCategoryGrid(context),
        ),
      ],
    );
  }

  // --- Widget Builder for Category Grid (Beautified) ---
  Widget _buildCategoryGrid(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Adjust number of columns if needed
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio:
            1.0, // Make cards square or adjust as needed (e.g., 1.1)
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        // Access category data from the map
        final category = _categories[index];
        final String name = category['name'];
        final IconData icon = category['icon'];
        final Color color = category['color'];
        return Card(
          elevation: 2.0, // Subtle elevation
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          // Optional: Slightly tint background based on category color
          // color: color.withOpacity(0.05),
          child: InkWell(
            onTap: () => _selectCategory(name),
            splashColor:
                color.withOpacity(0.15), // Use category color for splash
            highlightColor:
                color.withOpacity(0.1), // Use category color for highlight
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Optional: Wrap icon in a colored circle background
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        color.withOpacity(0.15), // Light background
                    child: Icon(
                      icon,
                      size: 32.0, // Adjust icon size
                      color: color, // Use category color for icon
                    ),
                  ),
                  const SizedBox(height: 16.0), // Increased spacing
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      // Optional: Slightly darken text color for contrast
                      // color: theme.colorScheme.onSurface.withOpacity(0.8),
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

  // --- Widget Builder for Filtered Product List (Beautified) ---
  Widget _buildFilteredProductList(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final Color categoryColor = _categories.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
            orElse: () => {'color': theme.colorScheme.primary})['color']
        as Color; // Get color for potential use
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header with Back Button and Title (Enhanced) ---
        Padding(
          // Use SafeArea padding for top spacing respecting notches/status bars
          padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).padding.top + 8, // Safe area + padding
              left: 8,
              right: 16,
              bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.arrow_back_ios_new_rounded), // Nicer back icon
                iconSize: 22,
                color: theme.colorScheme.onSurfaceVariant, // Subtle color
                onPressed: _clearCategorySelection,
                tooltip: 'Back to Categories',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCategory!,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    // Optional: Use category color subtly
                    // color: categoryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Optional: Add a filter or sort icon button here
            ],
          ),
        ),
        // Optional: Add a subtle divider below the header
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        // -----------------------------------------
        // --- FutureBuilder for Products ---
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _filteredProductsFuture,
            builder: (context, snapshot) {
              // Loading State - Use Shimmer
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Build a shimmer placeholder that matches the grid
                return _buildProductListShimmer(context);
              }
              // Error State - Enhanced
              if (snapshot.hasError) {
                return _buildListErrorWidget(context, snapshot.error);
              }
              // Empty State - Enhanced
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildListEmptyWidget(context);
              }
              // Success State - Display Products
              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16.0, 16.0, 16.0, 16.0), // Consistent padding
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Consistent columns
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.75, // Consistent aspect ratio
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
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

  // --- Helper: Shimmer for Product List ---
  Widget _buildProductListShimmer(BuildContext context) {
    // Get grid parameters
    const crossAxisCount = 2;
    const spacing = 12.0;
    const aspectRatio = 0.75;
    const shimmerItemCount = 6; // Number of shimmer cards
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1200),
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0), // Match product grid padding
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: shimmerItemCount,
        itemBuilder: (context, index) {
          // Placeholder mimicking ProductCard structure
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                Expanded(flex: 3, child: Container(color: Colors.white)),
                // Text Placeholders
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 16,
                            width: double.infinity,
                            color: Colors.white),
                        const SizedBox(height: 6),
                        Container(height: 14, width: 100, color: Colors.white),
                        const Spacer(), // Push price/button to bottom
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                height: 18, width: 50, color: Colors.white),
                            Container(
                                height: 30, width: 40, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper: Enhanced Error Widget ---
  Widget _buildListErrorWidget(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[300], size: 60),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load products for $_selectedCategory. Please try again later.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${error.toString()}', // Show specific error in debug/dev
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Enhanced Empty Widget ---
  Widget _buildListEmptyWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.grey[400], size: 60),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no products available in the $_selectedCategory category.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
