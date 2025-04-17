import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract order details
    final orderId = order['id'] as String;
    final createdAt = DateTime.parse(order['created_at']);
    final status = order['status'] as String;
    final subtotal = order['subtotal'] as double;
    final deliveryFee = order['delivery_fee'] as double;
    final totalAmount = order['total_amount'] as double;
    final paymentMethod = order['payment_method'] as String;

    // Shipping address details
    final shippingName = order['shipping_name'] as String;
    final shippingPhone = order['shipping_phone'] as String;
    final shippingAddressLine1 = order['shipping_address_line1'] as String;
    final shippingAddressLine2 = order['shipping_address_line2'] as String?;
    final shippingCity = order['shipping_city'] as String;
    final shippingState = order['shipping_state'] as String;
    final shippingZipCode = order['shipping_zip_code'] as String;

    // Parse order items from JSON
    List<dynamic> orderItems = [];
    try {
      if (order['order_items'] != null) {
        orderItems = jsonDecode(order['order_items']);
      }
    } catch (e) {
      debugPrint('Error parsing order items: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Date
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placed on ${DateFormat('MMMM dd, yyyy').format(createdAt)} at ${DateFormat('hh:mm a').format(createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment Method: $paymentMethod',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Items
            _buildSectionTitle(context, 'Order Items'),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...orderItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product quantity
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item['quantity']}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs.${item['price'].toStringAsFixed(2)} per item',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Item total price
                            Text(
                              'Rs.${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (orderItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No items found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Shipping Address
            _buildSectionTitle(context, 'Shipping Address'),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shippingName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shippingPhone,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shippingAddressLine1,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    if (shippingAddressLine2 != null &&
                        shippingAddressLine2.isNotEmpty)
                      Text(
                        shippingAddressLine2,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      '$shippingCity, $shippingState $shippingZipCode',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Order Summary
            _buildSectionTitle(context, 'Order Summary'),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow(
                        'Subtotal', 'Rs.${subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Delivery Fee', 'Rs.${deliveryFee.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                    _buildSummaryRow(
                      'Total',
                      'Rs.${totalAmount.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Help button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact support feature not implemented'),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Need help with this order?'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'processing':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        statusIcon = Icons.sync;
        break;
      case 'shipped':
        chipColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade900;
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
