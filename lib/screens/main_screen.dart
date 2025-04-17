import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tabs/home_tab.dart';
import '../tabs/explore_tab.dart';
import '../tabs/cart_tab.dart';
import '../tabs/profile_tab.dart';
import '../main.dart'; // To access supabase client
import 'welcome_screen.dart'; // To navigate on logout

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // State variable to track selected tab index

  // List of the widgets representing the content for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    ExploreTab(),
    CartTab(),
    ProfileTab(),
  ];

  // List of AppBar titles corresponding to each tab
  static const List<String> _appBarTitles = <String>[
    'Natural Food Store', // Home
    'Explore Products', // Explore
    'Your Shopping Cart', // Cart
    'Your Profile', // Profile
  ];

  // Function called when a navigation bar item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function for handling logout
  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Uses theme
        title: Text(_appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 3) // Show Logout only on Profile tab
            IconButton(
              icon: const Icon(Icons.logout_outlined), // Use outlined icon
              tooltip: 'Logout',
              onPressed: _handleLogout,
            )
        ],
      ),
      // Use IndexedStack to preserve the state of each tab when switching
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // The Bottom Navigation Bar itself (Uses theme)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
