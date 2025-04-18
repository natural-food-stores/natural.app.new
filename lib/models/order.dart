import 'package:flutter/foundation.dart';
import 'dart:convert';

class Order {
  final String id;
  final String customerId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentMethod;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddressLine1;
  final String? shippingAddressLine2;
  final String shippingCity;
  final String shippingState;
  final String shippingZipCode;
  final List<OrderItem> orderItems;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddressLine1,
    this.shippingAddressLine2,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingZipCode,
    required this.orderItems,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];

    try {
      if (json['order_items'] != null) {
        final dynamic orderItemsData = json['order_items'];
        if (orderItemsData is String) {
          // Parse from JSON string
          final List<dynamic> parsedItems = jsonDecode(orderItemsData);
          items = parsedItems.map((item) => OrderItem.fromJson(item)).toList();
        } else if (orderItemsData is List) {
          // Already a list
          items =
              orderItemsData.map((item) => OrderItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error parsing order items: $e');
    }

    return Order(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Not specified',
      shippingName: json['shipping_name'] as String? ?? '',
      shippingPhone: json['shipping_phone'] as String? ?? '',
      shippingAddressLine1: json['shipping_address_line1'] as String? ?? '',
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingCity: json['shipping_city'] as String? ?? '',
      shippingState: json['shipping_state'] as String? ?? '',
      shippingZipCode: json['shipping_zip_code'] as String? ?? '',
      orderItems: items,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address_line1': shippingAddressLine1,
      'shipping_address_line2': shippingAddressLine2,
      'shipping_city': shippingCity,
      'shipping_state': shippingState,
      'shipping_zip_code': shippingZipCode,
      'order_items':
          jsonEncode(orderItems.map((item) => item.toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }
}
