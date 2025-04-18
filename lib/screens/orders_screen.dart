import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Order> _allOrders = [];
  List<Order> _pendingOrders = [];
  List<Order> _processingOrders = [];
  List<Order> _shippedOrders = [];
  List<Order> _deliveredOrders = [];
  List<Order> _cancelledOrders = [];

  // Indian Rupee formatter
  final _rupeeFormat = NumberFormat.currency(
    locale: 'hi_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _orderService.fetchOrders();

      setState(() {
        _allOrders = orders;
        _pendingOrders = orders
            .where((order) => order.status.toLowerCase() == 'pending')
            .toList();
        _processingOrders = orders
            .where((order) => order.status.toLowerCase() == 'processing')
            .toList();
        _shippedOrders = orders
            .where((order) => order.status.toLowerCase() == 'shipped')
            .toList();
        _deliveredOrders = orders
            .where((order) => order.status.toLowerCase() == 'delivered')
            .toList();
        _cancelledOrders = orders
            .where((order) => order.status.toLowerCase() == 'cancelled')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      await _loadOrders(); // Reload orders after update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_pendingOrders, 'pending'),
                _buildOrderList(_processingOrders, 'processing'),
                _buildOrderList(_shippedOrders, 'shipped'),
                _buildOrderList(_deliveredOrders, 'delivered'),
                _buildOrderList(_cancelledOrders, 'cancelled'),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Order> orders, String currentStatus) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $currentStatus orders',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsScreen(
                      order: order.toJson(),
                    ),
                  ),
                ).then((_) => _loadOrders());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          order.shippingName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          order.shippingPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order.orderItems.length} items',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _rupeeFormat.format(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildActionButtons(order, currentStatus),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Order order, String currentStatus) {
    // Define available actions based on current status
    List<Widget> actions = [];

    switch (currentStatus) {
      case 'pending':
        actions = [
          _buildActionButton(
            label: 'Process',
            icon: Icons.sync,
            color: Colors.blue,
            onPressed: () => _updateOrderStatus(order, 'processing'),
          ),
          _buildActionButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onPressed: () => _updateOrderStatus(order, 'cancelled'),
          ),
        ];
        break;
      case 'processing':
        actions = [
          _buildActionButton(
            label: 'Ship',
            icon: Icons.local_shipping_outlined,
            color: Colors.green,
            onPressed: () => _updateOrderStatus(order, 'shipped'),
          ),
          _buildActionButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onPressed: () => _updateOrderStatus(order, 'cancelled'),
          ),
        ];
        break;
      case 'shipped':
        actions = [
          _buildActionButton(
            label: 'Deliver',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onPressed: () => _updateOrderStatus(order, 'delivered'),
          ),
        ];
        break;
      case 'delivered':
        // No actions for delivered orders
        break;
      case 'cancelled':
        // No actions for cancelled orders
        break;
    }

    return Row(
      mainAxisAlignment: actions.isEmpty
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceEvenly,
      children: actions.isEmpty
          ? [
              Text(
                'No actions available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]
          : actions,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        break;
      case 'processing':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case 'shipped':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'delivered':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
