// providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart'; // Adjust path if needed
import '../models/product.dart'; // Adjust path if needed

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

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

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity + 1,
          category: existingCartItem.category, // <-- Use existing category
        ),
      );
    } else {
      // Use the factory which now includes category
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
          category: existingCartItem.category, // <-- Use existing category
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
