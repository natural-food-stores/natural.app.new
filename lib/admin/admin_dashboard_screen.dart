import 'package:flutter/material.dart';
import 'add_product_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add New Product'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddProductScreen()),
              );
            },
            // Optional: Style differently from main theme if needed
            // style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          ),
          // TODO: Add more admin functions here (View Products, Orders, etc.)
        ),
      ),
    );
  }
}
