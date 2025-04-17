import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../screens/checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Removed the inner Scaffold's AppBar to avoid duplicate title
        return Scaffold(
          body: cart.itemCount == 0
              ? _buildEmptyCart(context) // Empty cart view
              : Column(
                  // View when cart has items
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) {
                          // Using Map entries is often safer than relying on list index
                          final entry = cart.items.entries.elementAt(i);
                          final item = entry.value;
                          // final productId = entry.key; // If needed elsewhere
                          return _buildCartItemTile(context, item, cart);
                        },
                      ),
                    ),
                    // Only show summary if cart is not empty
                    if (cart.itemCount > 0) _buildCartSummary(context, cart),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
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
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
      BuildContext context, CartItem item, CartProvider cart) {
    final textTheme = Theme.of(context).textTheme;
    final productId = item.id;
    final availableQuantity = cart.getAvailableQuantity(productId);
    final canAddMore = cart.canAddMore(productId);
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
                      placeholder:
                          'assets/images/placeholder.png', // Ensure you have this placeholder
                      image: item.imageUrl!,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.broken_image,
                                  size: 30, color: Colors.grey)),
                    )
                  : Container(
                      // Placeholder for missing image URL
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
                Row(
                  children: [
                    Text(
                      'Rs.${item.price.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // Display available quantity dynamically
                      'In stock: $availableQuantity',
                      style: textTheme.bodySmall?.copyWith(
                        color: availableQuantity > 0
                            ? Colors.green[700]
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity Controls
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed: () => cart.decreaseItemQuantity(productId),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        '${item.quantity}', // Display current quantity in cart
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.add,
                      // Check if more can be added before enabling button
                      onPressed: canAddMore
                          ? () {
                              // Recreate a basic Product object to pass to addItem
                              final product = Product(
                                id: productId,
                                name: item.name,
                                price: item.price,
                                category: item
                                    .category, // Assuming CartItem has category
                                quantity:
                                    availableQuantity, // Pass available stock
                                imageUrl: item.imageUrl,
                                createdAt: DateTime
                                    .now(), // Or item.createdAt if available
                              );
                              cart.addItem(product);
                            }
                          : null, // Disable if cannot add more
                      isDisabled: !canAddMore,
                    ),
                    const Spacer(), // Pushes delete icon to the end
                    // Remove Item Button (Individual)
                    InkWell(
                      onTap: () => cart.removeItem(productId),
                      child: Icon(Icons.delete_outline,
                          color: Colors.redAccent[100], size: 22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                // Show warning if max quantity reached
                if (!canAddMore &&
                    availableQuantity > 0) // Only show if item *is* in stock
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Maximum available quantity reached',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700], // Use orange for warning
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Quantity +/- buttons
  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final disabledColor = Colors.grey[400];
    return InkWell(
      // Use InkWell for tap feedback if needed, otherwise Material
      onTap: isDisabled ? null : onPressed, // Disable tap if needed
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
              color: isDisabled
                  ? Colors.grey[300]!
                  : primaryColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4),
          color:
              isDisabled ? Colors.grey[200] : null, // Background when disabled
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled ? disabledColor : primaryColor,
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    final textTheme = Theme.of(context).textTheme;
    const double deliveryFee = 50.0; // Example fee
    final double totalWithDelivery = cart.totalPrice + deliveryFee;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Use cardColor for background
        boxShadow: [
          BoxShadow(
            // Subtle shadow at the top
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3), // Shadow points upwards
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), // Rounded top corners
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Takes minimum space needed
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${cart.totalItemsCount} items):', // Use totalItemsCount for accuracy
                style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              ),
              Text(
                'Rs.${cart.totalPrice.toStringAsFixed(2)}',
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
          const Divider(height: 24), // Visual separator
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
                'Rs.${totalWithDelivery.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).primaryColor // Highlight total price
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity, // Button takes full width
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Consider adding style like padding, shape
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: cart.itemCount == 0 // Disable if cart is empty
                  ? null
                  : () {
                      // Navigate to checkout screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CheckoutScreen(),
                        ),
                      );
                    },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
