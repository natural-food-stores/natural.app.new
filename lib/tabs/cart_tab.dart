// screens/tabs/cart_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart'; // Adjust path if needed
import '../../models/cart_item.dart'; // Adjust path if needed
import '../../models/product.dart'; // Import Product model

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // ... (rest of build method remains the same) ...
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'My Cart (${cart.totalItemsCount} items)', // Use totalItemsCount
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).canvasColor,
            elevation: 1,
            actions: [
              if (cart.itemCount > 0)
                IconButton(
                  icon: Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent[100]),
                  tooltip: 'Clear Cart',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Action'),
                        content: const Text(
                            'Are you sure you want to remove all items from your cart?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Clear All'),
                            onPressed: () {
                              cart.clearCart();
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: cart.itemCount == 0
              ? _buildEmptyCart(context)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) {
                          final item = cart.items.values.toList()[i];
                          // Pass item and cart provider
                          return _buildCartItemTile(context, item, cart);
                        },
                      ),
                    ),
                    _buildCartSummary(context, cart),
                  ],
                ),
        );
        // ...
      },
    );
  }

  // --- _buildEmptyCart remains the same ---
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .remove_shopping_cart_outlined, // Or your preferred empty cart icon
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Your Cart is Empty',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Looks like you haven\'t added anything yet.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Attempt to switch tab - may need adjustment based on your exact navigation setup
              DefaultTabController.maybeOf(context)?.animateTo(0);
            },
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse Products'),
          )
        ],
      ),
    );
  }
  // --------------------------------------

  // Widget for displaying a single cart item tile
  Widget _buildCartItemTile(
      BuildContext context, CartItem item, CartProvider cart) {
    // Changed signature back
    final textTheme = Theme.of(context).textTheme;

    // Use the item directly, productId is item.id
    final productId = item.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              width: 70,
              height: 70,
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/placeholder.png',
                      image: item.imageUrl!,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.broken_image,
                                  size: 30, color: Colors.grey)),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 30, color: Colors.grey))),
            ),
          ),
          const SizedBox(width: 15),

          // Item Details and Quantity Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Rs.${item.price.toStringAsFixed(2)}',
                  style:
                      textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity Controls
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed: () =>
                          cart.decreaseItemQuantity(productId), // Use productId
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        '${item.quantity}',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.add,
                      onPressed: () {
                        // *** FIXED SNIPPET ***
                        // Reconstruct Product using CartItem details, including category
                        final product = Product(
                          id: productId, // Use productId from item.id
                          name: item.name,
                          price: item.price,
                          category: item
                              .category, // <-- FIXED: Use category from CartItem
                          quantity: 1, // Placeholder ok here
                          imageUrl: item.imageUrl,
                          createdAt: DateTime.now(), // Placeholder ok here
                        );
                        cart.addItem(product);
                        // **********************
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => cart.removeItem(productId), // Use productId
                      child: Icon(Icons.delete_outline,
                          color: Colors.redAccent[100], size: 22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildQuantityButton remains the same ---
  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
      ),
    );
  }
  // ------------------------------------------

  // --- _buildCartSummary remains the same ---
  // (Using totalPrice getter from CartProvider now)
  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    final textTheme = Theme.of(context).textTheme;
    // Hardcoded delivery fee for example
    const double deliveryFee = 50.0;
    final double totalWithDelivery = cart.totalPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${cart.totalItemsCount} items):', // Use totalItemsCount
                style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              ),
              Text(
                'Rs.${cart.totalPrice.toStringAsFixed(2)}', // Use totalPrice
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Delivery Fee (Example)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee:',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                'Rs.${deliveryFee.toStringAsFixed(2)}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 24),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs.${totalWithDelivery.toStringAsFixed(2)}', // Calculate total
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.itemCount == 0
                  ? null
                  : () {
                      // Disable if cart is empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Checkout not implemented yet!')),
                      );
                    },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
  // ------------------------------------
} // End of CartTab class
