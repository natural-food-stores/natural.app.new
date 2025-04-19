import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Ensure these paths are correct for your project structure
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'package:shimmer/shimmer.dart'; // Make sure this package is added

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  // Use a Completer to better handle manual refreshes and initial load state
  Completer<List<Product>> _productsCompleter = Completer();
  Future<List<Product>> get _productsFuture =>
      _productsCompleter.future; // Getter for the future

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Banner state
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _bannerTimer;

  // Animation controller for search bar
  late AnimationController _animationController;
  late Animation<double> _searchBarAnimation;

  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': Colors.blue},
    {'name': 'Fruits', 'icon': Icons.apple_rounded, 'color': Colors.redAccent},
    {
      'name': 'Vegetables',
      'icon': Icons.energy_savings_leaf_rounded,
      'color': Colors.green
    },
    {
      'name': 'Dairy',
      'icon': Icons.icecream_rounded,
      'color': Colors.lightBlueAccent
    },
    {
      'name': 'Bakery',
      'icon': Icons.bakery_dining_rounded,
      'color': Colors.orangeAccent
    },
    {
      'name': 'Beverages',
      'icon': Icons.local_drink_rounded,
      'color': Colors.teal
    },
    {
      'name': 'Snacks',
      'icon': Icons.fastfood_rounded,
      'color': Colors.purpleAccent
    },
    {'name': 'Other', 'icon': Icons.category_rounded, 'color': Colors.blueGrey},
  ];
  String _selectedCategory = 'All';

  // Banner images - replace with your actual assets or fetch dynamically
  final List<Map<String, dynamic>> _bannerImages = [
    {
      'image': 'assets/banner1.jpg', // Make sure these assets exist
      'title': 'Fresh Grocery',
      'subtitle': 'Buy now'
    },
    {
      'image': 'assets/banner2.jpg',
      'title': 'Refreshing Cold Drinks',
      'subtitle': 'Beat the heat, Buy Now'
    },
    {
      'image': 'assets/banner3.jpg',
      'title': 'Fresh Dairy Products',
      'subtitle': 'Buy now'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialProducts(); // Fetch products on init
    _searchController.addListener(_onSearchChanged);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchBarAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    // Auto-scroll banners
    _startBannerTimer();
  }

  // Fetch initial products and complete the completer
  Future<void> _fetchInitialProducts() async {
    // If already completing or completed, don't refetch unless forced
    if (_productsCompleter.isCompleted) {
      // If you want subsequent loads to replace, create a new completer
      // _productsCompleter = Completer(); // Uncomment to allow overriding
      // else return; // Or simply return if already loaded
    }
    try {
      final products = await _productService.fetchProducts();
      if (!_productsCompleter.isCompleted) {
        _productsCompleter.complete(products);
      }
    } catch (error, stackTrace) {
      if (!_productsCompleter.isCompleted) {
        _productsCompleter.completeError(error, stackTrace);
      }
      debugPrint("Error fetching initial products: $error");
    }
  }

  void _startBannerTimer() {
    // Ensure banners exist and have more than one image before starting timer
    if (_bannerImages.length <= 1) return;

    _bannerTimer?.cancel(); // Cancel existing timer if any
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted || !_pageController.hasClients) {
        timer
            .cancel(); // Stop timer if widget is disposed or controller unavailable
        return;
      }

      int nextPage = (_currentPage + 1) % _bannerImages.length; // Use modulo

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      // Note: The onPageChanged callback updates _currentPage
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pageController.dispose();
    _bannerTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Called when search text changes
  void _onSearchChanged() {
    // No need to refetch data, filtering happens in build method
    // Just trigger a rebuild to apply the filter
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }

  // Handles pull-to-refresh
  Future<void> _refreshProducts() async {
    if (mounted) {
      _searchController.clear(); // Optionally clear search on refresh
      setState(() {
        _searchQuery = '';
        _selectedCategory = 'All'; // Reset category on refresh
        // Create a new completer for the refresh operation
        _productsCompleter = Completer();
      });
    }

    HapticFeedback.mediumImpact(); // Provide feedback

    // Refetch products and complete the new completer
    await _fetchInitialProducts();

    // Optional: Short delay to ensure refresh indicator visibility
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data once
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Use Scaffold background color
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: colorScheme.primary, // Use theme color
        backgroundColor: colorScheme.surface, // Use theme surface color
        displacement: 60, // Adjust as needed
        strokeWidth: 3,
        child: CustomScrollView(
          // Use BouncingScrollPhysics for a nicer feel, especially on iOS
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // App Bar with animated search
            SliverAppBar(
              floating: true,
              pinned: false, // Search bar scrolls off
              snap: true, // Snaps into view
              elevation: 0, // Clean look
              backgroundColor:
                  theme.scaffoldBackgroundColor, // Match background
              toolbarHeight: 70, // Ample height for search bar + padding
              automaticallyImplyLeading: false, // No back button
              title: Container(
                // Use container for alignment and potential padding
                height: 50, // Consistent height
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: _searchBarAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5), // Slide down effect
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _animationController, curve: Curves.easeOut)),
                    child: _buildSearchBar(theme), // Pass theme
                  ),
                ),
              ),
            ),

            // Main content area using SliverList for better structure in CustomScrollView
            SliverList(
                delegate: SliverChildListDelegate([
              // Only show banners/categories etc. AFTER data attempt
              FutureBuilder<List<Product>>(
                // Use the completer's future
                future: _productsFuture,
                builder: (context, snapshot) {
                  // --- Loading State ---
                  // Show shimmer ONLY when actively waiting for the first load
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_productsCompleter.isCompleted) {
                    // Pass shimmer placeholders for banners/categories/products
                    return _buildLoadingShimmer(theme);
                  }

                  // --- Error State ---
                  if (snapshot.hasError && !snapshot.hasData) {
                    // Show error only if no data is available at all
                    // Pass error information to the error widget
                    return _buildErrorWidget(snapshot.error, theme);
                  }

                  // --- Data State (Success or Error but with old data) ---
                  final allProducts =
                      snapshot.data ?? []; // Use fetched data or empty list
                  final bool hasAnyProductsInitially = allProducts.isNotEmpty;
                  final bool hasInStockProductsInitially =
                      allProducts.any((p) => p.quantity > 0);

                  // ****** FILTERING LOGIC ******
                  List<Product> displayProducts = allProducts.where((product) {
                    // 1. Filter out products with quantity 0 or less (OUT OF STOCK)
                    final bool isInStock = product.quantity > 0;
                    if (!isInStock) return false;

                    // 2. Filter by Search Query (Case-insensitive)
                    bool searchMatch = true; // Assume match if search is empty
                    if (_searchQuery.isNotEmpty) {
                      final productNameLower = product.name.toLowerCase();
                      final searchQueryLower = _searchQuery.toLowerCase();
                      searchMatch = productNameLower.contains(searchQueryLower);
                    }
                    if (!searchMatch) return false;

                    // 3. Filter by Category (Case-insensitive)
                    bool categoryMatch =
                        true; // Assume match if category is 'All'
                    if (_selectedCategory != 'All') {
                      categoryMatch = product.category.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                    }
                    if (!categoryMatch) return false;

                    // If all checks pass, include the product
                    return true;
                  }).toList();
                  // ****** END FILTERING LOGIC ******

                  // Determine if the empty state is due to filters or no products at all
                  final bool filtersApplied =
                      _searchQuery.isNotEmpty || _selectedCategory != 'All';
                  final bool showNoResultsDueToFilter =
                      hasAnyProductsInitially &&
                          displayProducts.isEmpty &&
                          (filtersApplied || !hasInStockProductsInitially);

                  // Build the main content column
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banners (show even if products are filtered out)
                      _buildBanners(theme),

                      // Categories (show even if products are filtered out)
                      _buildCategories(theme),

                      // Section title (show even if products are filtered out)
                      _buildSectionTitle('Featured Products', theme),

                      // Product Grid or Empty State Message
                      displayProducts.isEmpty
                          ? _buildEmptyOrNoResultsWidget(
                              showNoResultsDueToFilter, theme)
                          : _buildProductGrid(
                              displayProducts, theme), // Pass theme

                      const SizedBox(height: 20), // Padding at the bottom
                    ],
                  );
                },
              ),
            ]))
          ],
        ),
      ),
    );
  }

  // --- Builder Methods (passing theme for consistency) ---

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Use surface color
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded,
              color: theme.colorScheme.primary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: Colors.grey[600],
                  splashRadius: 18,
                  onPressed: () {
                    _searchController.clear(); // Listener will update state
                    HapticFeedback.lightImpact();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.onSurface),
        cursorColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildBanners(ThemeData theme) {
    if (_bannerImages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 180, // Adjust height as needed
      margin: const EdgeInsets.only(top: 16, bottom: 8), // Add vertical margin
      child: PageView.builder(
        controller: _pageController,
        itemCount: _bannerImages.length,
        onPageChanged: (int page) {
          if (mounted) {
            setState(() => _currentPage = page);
          }
        },
        itemBuilder: (context, index) {
          final banner = _bannerImages[index];
          return Container(
            // Add padding around each banner card instead of just horizontal margin
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              // Use Card for elevation and shape
              clipBehavior: Clip.antiAlias, // Clip image to card shape
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image
                  Image.asset(
                    banner['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image,
                          color: Colors.grey[400], size: 50),
                    ),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75)
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Banner text
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner['title'],
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(blurRadius: 2, color: Colors.black54)
                            ],
                          ),
                        ),
                        if (banner['subtitle'] != null &&
                            banner['subtitle']!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                const Shadow(
                                    blurRadius: 1, color: Colors.black45)
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Page indicator dots - Placed outside PageView for better positioning
      // child: Stack( // Original stack structure if preferred
      // ... PageView ...
      // Positioned dots here ...
    );
  }

  Widget _buildCategories(ThemeData theme) {
    return Container(
      height: 105, // Increased height slightly
      margin: const EdgeInsets.only(top: 16, bottom: 8), // Add margin
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = category['name'] == _selectedCategory;
          final Color categoryColor = category['color'] as Color;

          return Padding(
            // Add padding around each item
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() => _selectedCategory = category['name']);
                }
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 85, // Slightly wider
                decoration: BoxDecoration(
                  color: isSelected
                      ? categoryColor.withOpacity(0.15)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? categoryColor
                        : theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          // Add subtle shadow when selected
                          BoxShadow(
                            color: categoryColor.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon background circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? categoryColor
                            : categoryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'],
                        color: isSelected ? Colors.white : categoryColor,
                        size: 24, // Slightly larger icon
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category Name Text
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? categoryColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            // Use displaySmall or headlineMedium depending on emphasis needed
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('See All tapped (not implemented)')),
              );
              // TODO: Implement navigation to a full product list screen
            },
            style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600) // Use labelLarge
                ),
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED: Added Quantity Filter in parent `build` method ---
  // --- This method now just builds the grid UI ---
  Widget _buildProductGrid(List<Product> products, ThemeData theme) {
    // Use 2 columns - adjust aspect ratio as needed for your ProductCard design
    const int crossAxisCount = 2;
    const double childAspectRatio = 0.75; // Adjust this (width / height)
    const double spacing = 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacing, vertical: 8.0),
      child: GridView.builder(
        shrinkWrap:
            true, // Essential inside a non-scrollable parent like Column
        physics:
            const NeverScrollableScrollPhysics(), // The CustomScrollView handles scrolling
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          // Simple fade-in animation per item (consider flutter_staggered_animations for more complex effects)
          return AnimatedOpacity(
            duration:
                Duration(milliseconds: 300 + (index * 50)), // Staggered delay
            opacity: 1.0, // Animate from 0.0 if starting opacity is 0
            curve: Curves.easeOut,
            child: ProductCard(
                product: products[index]), // Your existing card widget
          );
        },
      ),
    );
  }

  // --- MODIFIED: Updated condition logic ---
  Widget _buildEmptyOrNoResultsWidget(
      bool isFilteredResultEmpty, ThemeData theme) {
    final IconData icon = isFilteredResultEmpty
        ? Icons.search_off_rounded // Icon when filters yield no results
        : Icons
            .inventory_2_outlined; // Icon when no products are available/in-stock initially

    final String title =
        isFilteredResultEmpty ? 'No Products Found' : 'No Products Available';

    final String message = isFilteredResultEmpty
        ? 'Try adjusting your search or category filter.'
        : 'We currently have no products in stock matching your criteria. Please check back later or pull to refresh.';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 30.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          // Only show 'Reset Filters' button if filters were applied and resulted in empty list
          if (isFilteredResultEmpty &&
              (_searchQuery.isNotEmpty || _selectedCategory != 'All')) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _searchController
                        .clear(); // Updates _searchQuery via listener
                    _searchQuery = ''; // Explicitly set state
                    _selectedCategory = 'All';
                  });
                }
                HapticFeedback.mediumImpact();
              },
              icon: const Icon(Icons.filter_list_off_rounded, size: 18),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error, ThemeData theme) {
    // Log the error for debugging
    debugPrint("Error loading products in HomeTab: $error");

    return Container(
      padding: const EdgeInsets.all(30.0),
      alignment: Alignment.center,
      // Constrain height or let it size naturally within the Column
      // height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 60, color: theme.colorScheme.error),
          const SizedBox(height: 20),
          Text(
            'Connection Error',
            style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'We couldn\'t load products right now. Please check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _refreshProducts, // Trigger refresh
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('TRY AGAIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the shimmer loading placeholders
  Widget _buildLoadingShimmer(ThemeData theme) {
    // Use theme colors for shimmer base/highlight
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;
    const double spacing = 12.0;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner shimmer
          Container(
            height: 180,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white, // Shimmer needs a solid base color
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Categories shimmer
          SizedBox(
            height: 105, // Match category list height

            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Show a few placeholder categories
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) => Container(
                width: 85, // Match category item width
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Section title shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16.0, 24.0, 16.0, 18.0), // Match title padding
            child: Container(
              height: 24, // Approx title height
              width: 200, // Approx title width
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Products shimmer Grid (2 columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacing),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4, // Show 4-6 placeholder products
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Match product grid columns
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.75, // Match product grid aspect ratio
              ),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0), // Match card shape
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Padding at bottom
        ],
      ),
    );
  }
} // End of _HomeTabState
