import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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

  // List of the widgets representing the content for each tab (remains the same)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    ExploreTab(),
    CartTab(),
    ProfileTab(),
  ];

  // List of AppBar titles corresponding to each tab (remains the same)
  static const List<String> _appBarTitles = <String>[
    'Natural Food Store', // Home
    'Explore Products', // Explore
    'Your Shopping Cart', // Cart
    'Your Profile', // Profile
  ];

  // Function called when a navigation bar item is tapped (remains the same)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function for handling logout (remains the same)
  Future<void> _handleLogout() async {
    // ... (logout code remains exactly the same)
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
    // final colors = Theme.of(context).colorScheme; // We'll use specific colors

    return Scaffold(
      appBar: AppBar(
        // ... (AppBar code remains the same)
        title: Text(_appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 3) // Show Logout only on Profile tab
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Logout',
              onPressed: _handleLogout,
            )
        ],
      ),
      body: IndexedStack(
        // Body remains the same
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // ---- GNav with GREEN Background and WHITE Active Tab ----
      bottomNavigationBar: Container(
        // Set the background of the whole bar container to green
        color: Colors.green.shade700, // Main background is now green
        // You could use Colors.green, Colors.green.shade800 etc.

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              gap: 8,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),

              // --- Inverted Color Configuration ---
              tabBackgroundColor: Colors
                  .white, // Background color of the ACTIVE tab button is now WHITE
              activeColor: Colors.green
                  .shade700, // Text and icon color of the ACTIVE tab button (green to contrast with white background)
              // You could also use Colors.black87 here if preferred: activeColor: Colors.black87,
              color: Colors
                  .white70, // Text and icon color of INACTIVE tab buttons (white/grey to contrast with green background)
              // --- End of Inverted Color Configuration ---

              tabs: const [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.explore_outlined,
                  text: 'Explore',
                ),
                GButton(
                  icon: Icons.shopping_cart_outlined,
                  text: 'Cart',
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
      // ---- End of GNav ----
    );
  }
}
