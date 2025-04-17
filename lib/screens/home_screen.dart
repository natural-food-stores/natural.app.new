import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // To access supabase client
import 'welcome_screen.dart'; // To navigate on logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Placeholder Widgets for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Home Page Content', style: TextStyle(fontSize: 24))),
    Center(child: Text('Explore Page Content', style: TextStyle(fontSize: 24))),
    Center(child: Text('Cart Page Content', style: TextStyle(fontSize: 24))),
    ProfilePage(), // Using a separate widget for Profile for logout functionality
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Natural Food Store'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // Simple Logout Button - Placed here for easy access
          if (_selectedIndex == 3) // Show only on Profile tab
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  await supabase.auth.signOut();
                  // Navigate back to Welcome Screen and remove all previous routes
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            )
        ],
      ),
      body: IndexedStack(
        // Use IndexedStack to keep state of pages
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
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
        selectedItemColor: Colors.amber[800], // Or your preferred color
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        // backgroundColor: Colors.white, // Optional: Set background color
        // elevation: 8.0, // Optional: Add elevation
      ),
    );
  }
}

// Simple Profile Page Widget (can be expanded later)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser; // Get current user info

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profile Page Content', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          if (user != null) Text('Logged in as: ${user.email ?? 'N/A'}'),
          const SizedBox(height: 20),
          // Logout button is now in the AppBar actions when this tab is active
          // You could add other profile details or settings here.
        ],
      ),
    );
  }
}
