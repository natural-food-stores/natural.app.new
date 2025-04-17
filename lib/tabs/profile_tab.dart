import 'package:flutter/material.dart';
import '../main.dart'; // To access supabase client
import '../admin/admin_dashboard_screen.dart'; // Import admin screen

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user from the Supabase client
    final user = supabase.auth.currentUser;
    final userEmail =
        user?.email ?? 'Not logged in'; // Get email or default text

    // Define text styles for consistency
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: Colors.grey[600]);
    final listTileTitleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: 16); // Slightly smaller for list tiles

    return Scaffold(
      // Use Scaffold for background color consistency if needed
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        // Use ListView for scrollability if content grows
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        children: <Widget>[
          // --- User Info Section ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                // Placeholder for profile picture
                radius: 55, // Slightly larger
                backgroundColor: Color(0xFFE0E0E0), // Lighter grey
                child: Icon(
                  Icons.person_outline,
                  size: 60,
                  color: Color(0xFFBDBDBD), // Darker grey icon
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userEmail, // Display user email
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Optional: Add a placeholder for user's name if available in profile
              // Text(
              //   "User Name Placeholder", // Replace with actual name if fetched
              //   style: subtitleStyle,
              // ),
            ],
          ),
          const SizedBox(height: 30), // Space before options

          // --- General Options Section ---
          _buildSectionTitle(context, 'Account'),
          _buildProfileOption(
            context,
            icon: Icons.settings_outlined,
            title: 'Account Settings',
            subtitle: 'Manage your profile details',
            onTap: () {
              // TODO: Navigate to Account Settings Screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Navigate to Account Settings (Not Implemented)')));
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            subtitle: 'Manage your delivery addresses',
            onTap: () {
              // TODO: Navigate to Address Management Screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Navigate to Saved Addresses (Not Implemented)')));
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.credit_card_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage your cards',
            onTap: () {
              // TODO: Navigate to Payment Methods Screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Navigate to Payment Methods (Not Implemented)')));
            },
          ),

          const SizedBox(height: 20), // Space before next section
          _buildSectionTitle(context, 'Activity'),
          _buildProfileOption(
            context,
            icon: Icons.history_outlined,
            title: 'Order History',
            subtitle: 'View your past orders',
            onTap: () {
              // TODO: Navigate to Order History Screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Navigate to Order History (Not Implemented)')));
            },
          ),

          const SizedBox(height: 20), // Space before next section
          _buildSectionTitle(context, 'Support'),
          _buildProfileOption(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get assistance',
            onTap: () {
              // TODO: Navigate to Help Screen or show contact info
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Navigate to Help & Support (Not Implemented)')));
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            onTap: () {
              // TODO: Implement feedback mechanism
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Send Feedback (Not Implemented)')));
            },
          ),

          // --- Admin Panel Section (Conditional) ---
          // Only show if user is logged in (basic check, real apps need role check)
          if (user != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined,
                  color: Colors.deepOrangeAccent),
              title: Text('Admin Panel',
                  style: listTileTitleStyle?.copyWith(
                      color: Colors.deepOrangeAccent)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen()),
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0), // Adjust padding
            ),
            const Divider(height: 1, thickness: 0.5),
          ],

          const SizedBox(height: 40), // Space at the bottom

          // Logout button is handled by the AppBar in MainScreen
        ],
      ),
    );
  }

  // Helper widget to build section titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  // Helper widget to build consistent ListTiles for profile options
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context)
              .primaryColorDark), // Use a consistent icon color
      title: Text(title,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 4.0), // Adjust vertical padding
      visualDensity: VisualDensity.compact, // Make tiles slightly denser
    );
  }
}
