import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart'; // Make sure this import is correct
import '../models/cart_item.dart'; // Assuming CartProvider uses a CartItem model

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    // Get providers and theme data - NO listen: false here for the main build
    // We'll use Consumer for targeted listening later.
    final cartProviderRead =
        context.read<CartProvider>(); // Use read for actions
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias, // Clip image to card shape
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          // Optional: Navigate to Product Detail Screen
          debugPrint('Tapped on product: ${product.name}');
          // Example navigation (replace with your actual navigation logic)
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Product Image Section (Keep as is) ---
            Expanded(
              flex: 3, // Adjust flex factor if needed
              child: Container(
                color: Colors.grey[100], // Background for image area
                child: (product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty)
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),

            // --- Product Details Section ---
            Expanded(
              flex: 2, // Adjust flex factor if needed
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Pushes content apart
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price and Add/Quantity Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Text(
                          // Make sure your product model has a currency symbol or handle formatting here
                          'Rs.${product.price.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // --- Dynamic Add/Quantity Button ---
                        // Use Consumer to listen to CartProvider changes
                        Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            // Find the specific item in the cart
                            final cartItem = cart.items[product.id];
                            final int quantity = cartItem?.quantity ?? 0;

                            // If item is not in cart (quantity is 0)
                            if (quantity == 0) {
                              return ElevatedButton(
                                onPressed: () {
                                  // Use the 'read' instance for actions
                                  cartProviderRead.addItem(product);
                                  _showAddToCartSnackbar(
                                      context, product, cartProviderRead);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  minimumSize:
                                      const Size(0, 32), // Smaller button
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Add'),
                              );
                            }
                            // If item IS in cart
                            else {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          colorScheme.primary.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Row takes minimum space
                                  children: [
                                    // Decrease Button
                                    SizedBox(
                                      width: 32, // Constrain button size
                                      height: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.remove,
                                            size: 18,
                                            color: colorScheme.primary),
                                        tooltip: 'Decrease quantity',
                                        onPressed: () {
                                          cartProviderRead
                                              .decreaseItemQuantity(product.id);
                                          // Optional: Show a different snackbar or none on decrease
                                        },
                                      ),
                                    ),

                                    // Quantity Display - *** PADDING REDUCED ***
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0), // Reduced padding
                                      child: Text(
                                        quantity.toString(),
                                        style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),

                                    // Increase Button
                                    SizedBox(
                                      width: 32, // Constrain button size
                                      height: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.add,
                                            size: 18,
                                            color: colorScheme.primary),
                                        tooltip: 'Increase quantity',
                                        onPressed: () {
                                          cartProviderRead.addItem(
                                              product); // AddItem usually handles incrementing
                                          _showAddToCartSnackbar(context,
                                              product, cartProviderRead);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        // --- End of Dynamic Button ---
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to show the SnackBar (Keep as is)
  void _showAddToCartSnackbar(
      BuildContext context, Product product, CartProvider cartProvider) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(); // Hide previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // Floats above bottom nav bar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.yellowAccent, // Or your theme's accent color
          onPressed: () {
            // Use the passed CartProvider instance
            cartProvider.decreaseItemQuantity(product.id);
          },
        ),
      ),
    );
  }
}
