import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  // Store available quantities for products
  final Map<String, int> _availableQuantities = {};

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  int get totalItemsCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  // Get available quantity for a product
  int getAvailableQuantity(String productId) {
    return _availableQuantities[productId] ?? 0;
  }

  // Check if we can add more of this product
  bool canAddMore(String productId) {
    final availableQty = _availableQuantities[productId] ?? 0;
    final currentQty = _items[productId]?.quantity ?? 0;
    return currentQty < availableQty;
  }

  void addItem(Product product) {
    // Store or update the available quantity for this product
    _availableQuantities[product.id] = product.quantity;

    if (_items.containsKey(product.id)) {
      // Check if we can add more of this product
      final currentQty = _items[product.id]!.quantity;
      if (currentQty >= product.quantity) {
        // Already at max quantity, show message via return value or callback
        debugPrint(
            'Cannot add more items. Max quantity reached for ${product.name}');
        return; // Don't add more
      }

      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity + 1,
          category: existingCartItem.category,
        ),
      );
    } else {
      // Check if product is in stock
      if (product.quantity <= 0) {
        debugPrint('Cannot add out-of-stock item: ${product.name}');
        return; // Don't add out-of-stock items
      }

      _items.putIfAbsent(
        product.id,
        () => CartItem.fromProduct(product, quantity: 1),
      );
    }
    debugPrint('Item added/updated: ${product.name}. New cart state: $_items');
    notifyListeners();
  }

  void decreaseItemQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity - 1,
          category: existingCartItem.category,
        ),
      );
    } else {
      _items.remove(productId);
    }
    debugPrint(
        'Item quantity decreased/removed for ID: $productId. New cart state: $_items');
    notifyListeners();
  }

  void removeItem(String productId) {
    if (_items.containsKey(productId)) {
      _items.remove(productId);
      debugPrint('Item removed for ID: $productId. New cart state: $_items');
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    debugPrint('Cart cleared. New cart state: $_items');
    notifyListeners();
  }
}
