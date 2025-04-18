// models/cart_item.dart
import 'product.dart'; // Your existing Product model

class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;
  final String category;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.category,
  });

  // Update fromProduct factory
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: quantity,
      category: product.category,
    );
  }

  double get totalPrice => price * quantity;
}
