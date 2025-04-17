import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../main.dart'; // To access supabase client
import '../models/cart_item.dart';
import '../screens/order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You need to be logged in to view orders';
        });
        return;
      }

      // Fetch orders from Supabase
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load orders: ${error.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _orders.isEmpty
                    ? _buildEmptyOrdersView()
                    : _buildOrdersList(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchOrders,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'When you place orders, they will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to profile
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderId = order['id'] as String;
        final createdAt = DateTime.parse(order['created_at']);
        final status = order['status'] as String;
        final totalAmount = order['total_amount'] as double;

        // Parse order items from JSON
        List<dynamic> orderItems = [];
        try {
          if (order['order_items'] != null) {
            orderItems = jsonDecode(order['order_items']);
          }
        } catch (e) {
          debugPrint('Error parsing order items: $e');
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0.5,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(order: order),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID and Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Order Items Preview
                  if (orderItems.isNotEmpty) ...[
                    Text(
                      '${orderItems.length} ${orderItems.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show first 2 items
                    ...orderItems.take(2).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 8, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item['quantity']}x ${item['product_name']}',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Show "more items" if there are more than 2
                    if (orderItems.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Text(
                          '+ ${orderItems.length - 2} more',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],

                  const Divider(height: 24),

                  // Status and Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusChip(status),
                      Text(
                        'Rs.${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
