import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Keep this import
import 'add_product_screen.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../screens/orders_screen.dart';
import '../screens/products_screen.dart';
import '../tabs/profile_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  List<Product> _products = [];
  List<Order> _recentOrders = [];
  bool _isLoading = true;

  // Data for analytics
  double _totalSales = 0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  Map<String, int> _categoryCounts = {};
  List<Map<String, dynamic>> _monthlySales = [];

  // Indian Rupee formatter
  final _rupeeFormat = NumberFormat.currency(
    locale: 'hi_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return; // Avoid calling setState if the widget is disposed
    setState(() {
      _isLoading = true;
    });

    try {
      // Load products and orders concurrently
      final results = await Future.wait([
        _productService.fetchProducts(),
        _orderService.fetchOrders(),
      ]);

      final products = results[0] as List<Product>;
      final orders = results[1] as List<Order>;

      // Calculate analytics
      _calculateAnalytics(products, orders);

      if (mounted) {
        // Sort orders by creation date descending before taking 5
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() {
          _products = products;
          _recentOrders = orders.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  void _calculateAnalytics(List<Product> products, List<Order> orders) {
    // Calculate total sales
    _totalSales = orders.fold(0.0,
        (sum, order) => sum + order.totalAmount); // Ensure sum starts as double

    // Count total orders
    _totalOrders = orders.length;

    // Count unique customers
    final uniqueCustomers = <String>{};
    for (var order in orders) {
      // Ensure customerId is not null/empty before adding
      if (order.customerId.isNotEmpty) {
        uniqueCustomers.add(order.customerId);
      }
    }
    _totalCustomers = uniqueCustomers.length;

    // Count products by category
    _categoryCounts = {};
    for (var product in products) {
      // Ensure category is not null or empty before using it as a key
      final categoryKey =
          (product.category != null && product.category!.isNotEmpty)
              ? product.category!
              : 'Uncategorized';
      _categoryCounts[categoryKey] = (_categoryCounts[categoryKey] ?? 0) + 1;
    }

    // Calculate monthly sales for the last 6 months
    _monthlySales = [];
    final now = DateTime.now();
    // Filter out orders without valid dates first
    final validOrders = orders.where((o) => o.createdAt != null).toList();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName =
          DateFormat('MMM').format(month); // Ensure intl is imported

      // Filter orders for this month
      final monthOrders = validOrders.where((order) {
        return order.createdAt!.year == month.year &&
            order.createdAt!.month == month.month;
      });

      // Sum sales for this month
      final monthlySale =
          monthOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

      _monthlySales.add({
        'month': monthName,
        'sales': monthlySale,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.green),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'natural.f00dst0r3s@gmail.com', // Replace with actual admin email if available
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true, // Keep this selected for the current screen
            selectedTileColor: Colors.green.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Products'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductsScreen(),
                ),
                // Refresh data potentially needed if products are modified
              ).then((_) => _loadDashboardData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
                // Refresh data potentially needed if order statuses change
              ).then((_) => _loadDashboardData());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Back'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildSalesChart(),
            const SizedBox(height: 24),
            _buildProductCategoryChart(),
            const SizedBox(height: 24),
            _buildRecentOrdersSection(),
            const SizedBox(height: 24),
            _buildLowStockProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // Ensure intl package is imported for DateFormat
                  DateFormat('EEEE, dd MMMM yy')
                      .format(now), // Consistent format
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    // TODO: Replace placeholder growth data with actual calculations
    // These should ideally come from comparing current period with previous period
    final salesGrowth = '+12.5%';
    final ordersGrowth = '+8.2%';
    final productsGrowth = '+5.3%';
    final customersGrowth = '+15.7%';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Sales',
          value: _rupeeFormat.format(_totalSales),
          icon: Icons.currency_rupee,
          color: Colors.green,
          change: salesGrowth,
        ),
        _buildStatCard(
          title: 'Orders',
          value: _totalOrders.toString(),
          icon: Icons.shopping_cart_checkout, // More specific icon
          color: Colors.blue,
          change: ordersGrowth,
        ),
        _buildStatCard(
          title: 'Products',
          value: _products.length.toString(),
          icon: Icons.inventory_2,
          color: Colors.orange,
          change: productsGrowth,
        ),
        _buildStatCard(
          title: 'Customers',
          value: _totalCustomers.toString(),
          icon: Icons.people_alt, // More specific icon
          color: Colors.purple,
          change: customersGrowth,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    bool isPositiveChange = change.startsWith('+');
    Color changeColor = isPositiveChange ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Better vertical distribution
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start, // Align icon top
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // const Spacer(), // Use MainAxisAlignment.spaceBetween instead
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Take only needed space
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    // Check if there's data
    if (_monthlySales.isEmpty) {
      return _buildEmptyChartContainer(
          'Monthly Sales', 'No sales data available for the chart.');
    }

    // Use fold for safer max calculation if list could be empty (though checked above)
    final maxSales = _monthlySales
            .map((data) => data['sales'] as double)
            .fold(0.0, (max, value) => value > max ? value : max) *
        1.2; // Add 20% padding

    final effectiveMaxSales = maxSales <= 0 ? 1000.0 : maxSales;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Sales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Text('Last 6 months',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12))
                  ])),
            ],
          ),
          const SizedBox(height: 24), // Increased spacing
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: effectiveMaxSales,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    // *** CORRECTED ***

                    tooltipRoundedRadius: 8, // Optional rounded corners
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                          _rupeeFormat.format(rod.toY),
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _monthlySales.length) {
                          // *** CORRECTED ***
                          return SideTitleWidget(
                            meta: meta, // Pass meta
                            space: 4, // Add space below text
                            child: Text(_monthlySales[index]['month'],
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500) // Bolder
                                ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 32, // Increased reserved size
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Show fewer labels for cleaner look
                        if (value == 0 || value == effectiveMaxSales) {
                          // *** CORRECTED ***
                          return SideTitleWidget(
                              meta: meta, // Pass meta

                              child: Text(_rupeeFormat.format(value),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 10)));
                        }
                        // Optionally show mid-point if max is large enough
                        // else if (effectiveMaxSales > 1000 && value == effectiveMaxSales / 2) { ... }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 45, // Adjust space for labels like ₹10k
                      // Let fl_chart determine interval for cleaner look, or set explicitly:
                      // interval: effectiveMaxSales > 0 ? effectiveMaxSales / 2 : null,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false, // No vertical grid lines
                  horizontalInterval: effectiveMaxSales > 0
                      ? effectiveMaxSales / 4
                      : null, // Auto or set intervals
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1); // Lighter grid lines
                  },
                ),
                borderData: FlBorderData(show: false), // No chart border
                barGroups: List.generate(
                  _monthlySales.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _monthlySales[index]['sales'] as double,
                        color: Colors.greenAccent, // Slightly different color
                        width: 22, // Adjust bar width
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)), // Only top radius
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: effectiveMaxSales,
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategoryChart() {
    if (_categoryCounts.isEmpty) {
      return _buildEmptyChartContainer(
          'Product Categories', 'No product category data available.');
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> categoryColors = [
      Colors.green,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
      Colors.grey,
    ];

    int colorIndex = 0;
    final totalProductCount = _products.isNotEmpty ? _products.length : 1;

    // Sort categories for consistent legend order (optional)
    final sortedCategories = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by count descending

    // Limit number of sections shown in chart if too many categories exist
    const maxSectionsToShow = 8;
    double otherCount = 0;
    final sectionsToShow = sortedCategories.take(maxSectionsToShow).toList();
    if (sortedCategories.length > maxSectionsToShow) {
      otherCount = sortedCategories
          .skip(maxSectionsToShow)
          .fold(0, (sum, entry) => sum + entry.value);
    }

    for (var entry in sectionsToShow) {
      final category = entry.key;
      final count = entry.value;
      // final percentage = (count / totalProductCount) * 100; // Calculate percentage if needed
      sections.add(
        PieChartSectionData(
          color: categoryColors[colorIndex % categoryColors.length],
          value: count.toDouble(),
          title: '$count', // Show count directly
          radius: 80,
          titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)]),
          titlePositionPercentageOffset: 0.55, // Adjust label position
        ),
      );
      colorIndex++;
    }
    // Add "Others" section if needed
    if (otherCount > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade400, // Use grey for others
          value: otherCount,
          title: '${otherCount.toInt()}',
          radius: 80,
          titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)]),
          titlePositionPercentageOffset: 0.55,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sections,
                      pieTouchData: PieTouchData(touchCallback:
                          (FlTouchEvent event, pieTouchResponse) {
                        /* Handle touch */
                      }),
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildPieChartLegend(sectionsToShow, otherCount,
                    categoryColors), // Use helper for legend
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build Pie Chart Legend
  Widget _buildPieChartLegend(List<MapEntry<String, int>> sectionsToShow,
      double otherCount, List<Color> colors) {
    int legendColorIndex = 0;
    List<Widget> legendItems = sectionsToShow.map((entry) {
      final category = entry.key;
      final count = entry.value;
      final color = colors[legendColorIndex % colors.length];
      legendColorIndex++;
      return _buildLegendItem(color, category, count);
    }).toList();

    if (otherCount > 0) {
      legendItems.add(
          _buildLegendItem(Colors.grey.shade400, 'Others', otherCount.toInt()));
    }

    // Use ListView if legend might overflow vertically
    return ListView(
      shrinkWrap: true, // Important inside Expanded Column
      children: legendItems,
    );
    // Or Column if items are guaranteed to fit:
    // return Column( crossAxisAlignment: CrossAxisAlignment.start, children: legendItems);
  }

  // Helper for a single legend item
  Widget _buildLegendItem(Color color, String category, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(category,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1)),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OrdersScreen()))
                      .then((_) => _loadDashboardData());
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _recentOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No recent orders found',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _recentOrders
                      .map((order) => _buildOrderItem(order))
                      .toList()),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Order order) {
    final displayOrderId =
        order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child:
                const Icon(Icons.receipt_long, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$displayOrderId...',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15)), // Indicate truncated ID
                const SizedBox(height: 4),
                Text(
                    order.createdAt != null
                        ? DateFormat('dd MMM yy, hh:mm a')
                            .format(order.createdAt!)
                        : 'Date N/A', // Handle null date
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rupeeFormat.format(order.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              _buildStatusChip(order.status ?? 'Unknown'), // Handle null status
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData? iconData;
    String displayStatus = status[0].toUpperCase() +
        status.substring(1).toLowerCase(); // Capitalize

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        iconData = Icons.hourglass_empty;
        break;
      case 'processing':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        iconData = Icons.sync;
        break;
      case 'shipped':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        iconData = Icons.local_shipping;
        break;
      case 'delivered':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        iconData = Icons.check_circle_outline;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        iconData = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        iconData = Icons.help_outline;
        displayStatus = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: chipColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) Icon(iconData, color: textColor, size: 14),
          if (iconData != null) const SizedBox(width: 4),
          Text(displayStatus,
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLowStockProductsSection() {
    final lowStockProducts = _products.where((p) => p.quantity < 10).toList();
    lowStockProducts.sort((a, b) => a.quantity.compareTo(b.quantity));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Low Stock Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  // Navigate to Products screen, maybe pre-filtered for low stock?
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProductsScreen()))
                      .then((_) => _loadDashboardData());
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          lowStockProducts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48,
                            color:
                                Colors.green.shade300), // Positive indication
                        const SizedBox(height: 16),
                        Text('All products have sufficient stock',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                )
              // Show max 5 low stock items on dashboard
              : Column(
                  children: lowStockProducts
                      .take(5)
                      .map((product) => _buildLowStockProductItem(product))
                      .toList()),
        ],
      ),
    );
  }

  Widget _buildLowStockProductItem(Product product) {
    Color stockColor;
    String stockLabel;
    if (product.quantity <= 0) {
      stockColor = Colors.red.shade700;
      stockLabel = 'Out of Stock';
    } else if (product.quantity < 5) {
      stockColor = Colors.red.shade400;
      stockLabel = '${product.quantity} left!';
    } else {
      stockColor = Colors.orange.shade700;
      stockLabel = '${product.quantity} in stock';
    } // qty 5-9

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            // Image/Placeholder
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrl!),
                      fit: BoxFit.cover,
                      onError: (e, s) {})
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                ? const Center(
                    child: Icon(Icons.inventory_2_outlined,
                        color: Colors.grey, size: 28))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            // Product details
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(product.category ?? 'No Category',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            // Price/Stock
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rupeeFormat.format(product.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Container(
                // Stock Level Chip
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(stockLabel,
                    style: TextStyle(
                        color: stockColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for empty chart containers
  Widget _buildEmptyChartContainer(String title, String message) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
              heightFactor: 5,
              child: Text(message, style: TextStyle(color: Colors.grey[600])))
        ]));
  }
} // End of _AdminDashboardScreenState class
