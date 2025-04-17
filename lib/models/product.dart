// models/product.dart
import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String category; // <-- Added category field
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    required this.category, // <-- Added to constructor
    this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Debug logs for potentially missing fields
    if (json['id'] == null) debugPrint('Product JSON missing id: $json');
    if (json['name'] == null) debugPrint('Product JSON missing name: $json');
    if (json['price'] == null) debugPrint('Product JSON missing price: $json');
    if (json['quantity'] == null)
      debugPrint('Product JSON missing quantity: $json');
    if (json['category'] == null)
      debugPrint('Product JSON missing category: $json'); // <-- Added log
    if (json['created_at'] == null)
      debugPrint('Product JSON missing created_at: $json');

    return Product(
      id: json['id'] as String? ?? 'default_id',
      name: json['name'] as String? ?? 'Unnamed Product',
      description: json['description'] as String?,
      price: (json['price'] as num? ?? 0.0).toDouble(),
      quantity: (json['quantity'] as int? ?? 0),
      category: json['category'] as String? ??
          'Uncategorized', // <-- Added parsing, default to 'Uncategorized'
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category, // <-- Added to JSON output
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
