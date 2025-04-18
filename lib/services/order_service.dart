import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../main.dart'; // Import to access your supabase instance
import 'package:intl/intl.dart';

class OrderService {
  final _supabase = supabase;
  final String _ordersTable = 'orders';

  // Fetch all orders
  Future<List<Order>> fetchOrders() async {
    try {
      debugPrint('Fetching all orders...');
      final response = await _supabase
          .from(_ordersTable)
          .select()
          .order('created_at', ascending: false);

      if (response == null) {
        debugPrint('Error fetching orders: Supabase returned null');
        throw Exception('Failed to load orders: Received null response');
      }

      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint('Raw data list length (orders): ${dataList.length}');

      final orders = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Order.fromJson(data);
            } else {
              debugPrint('Skipping invalid order data item: $data');
              return null;
            }
          })
          .whereType<Order>()
          .toList();

      debugPrint('Parsed order list length: ${orders.length}');
      return orders;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching orders: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error loading orders: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching orders: $e');
      throw Exception('Failed to load orders: $e');
    }
  }

  // Fetch orders by customer ID
  Future<List<Order>> fetchOrdersByCustomer(String customerId) async {
    try {
      debugPrint('Fetching orders for customer: $customerId');
      final response = await _supabase
          .from(_ordersTable)
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (response == null) {
        debugPrint('Error fetching customer orders: Supabase returned null');
        throw Exception('Failed to load orders: Received null response');
      }

      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint('Raw data list length (customer orders): ${dataList.length}');

      final orders = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Order.fromJson(data);
            } else {
              debugPrint('Skipping invalid order data item: $data');
              return null;
            }
          })
          .whereType<Order>()
          .toList();

      debugPrint('Parsed customer order list length: ${orders.length}');
      return orders;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching customer orders: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error loading customer orders: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching customer orders: $e');
      throw Exception('Failed to load customer orders: $e');
    }
  }

  // Fetch orders by status
  Future<List<Order>> fetchOrdersByStatus(String status) async {
    try {
      debugPrint('Fetching orders with status: $status');
      final response = await _supabase
          .from(_ordersTable)
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      if (response == null) {
        debugPrint('Error fetching orders by status: Supabase returned null');
        throw Exception('Failed to load orders: Received null response');
      }

      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint('Raw data list length (status orders): ${dataList.length}');

      final orders = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Order.fromJson(data);
            } else {
              debugPrint('Skipping invalid order data item: $data');
              return null;
            }
          })
          .whereType<Order>()
          .toList();

      debugPrint('Parsed status order list length: ${orders.length}');
      return orders;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching status orders: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error loading status orders: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching status orders: $e');
      throw Exception('Failed to load status orders: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      debugPrint('Updating order $orderId status to: $newStatus');
      await _supabase
          .from(_ordersTable)
          .update({'status': newStatus}).eq('id', orderId);
      debugPrint('Order status updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException updating order status: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error updating order status: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get monthly sales data for the last 6 months
  Future<List<Map<String, dynamic>>> getMonthlySalesData() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      debugPrint('Fetching sales data from ${sixMonthsAgo.toIso8601String()}');

      final response = await _supabase
          .from(_ordersTable)
          .select()
          .gte('created_at', sixMonthsAgo.toIso8601String())
          .order('created_at');

      if (response == null) {
        debugPrint('Error fetching sales data: Supabase returned null');
        throw Exception('Failed to load sales data: Received null response');
      }

      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint('Raw sales data list length: ${dataList.length}');

      // Convert to Order objects
      final orders = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Order.fromJson(data);
            } else {
              return null;
            }
          })
          .whereType<Order>()
          .toList();

      // Group by month and calculate total sales
      final Map<String, double> monthlySales = {};

      for (int i = 0; i < 6; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthlySales[monthKey] = 0.0;
      }

      for (final order in orders) {
        final orderMonth =
            '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
        if (monthlySales.containsKey(orderMonth)) {
          monthlySales[orderMonth] =
              (monthlySales[orderMonth] ?? 0) + order.totalAmount;
        }
      }

      // Convert to list format for chart
      final List<Map<String, dynamic>> result = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        final monthName = DateFormat('MMM').format(month);

        result.add({
          'month': monthName,
          'sales': monthlySales[monthKey] ?? 0.0,
        });
      }

      debugPrint('Monthly sales data: $result');
      return result;
    } catch (e) {
      debugPrint('Error getting monthly sales data: $e');
      // Return empty data in case of error
      return [];
    }
  }
}
