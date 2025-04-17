import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- Import google_fonts

// Adjust these paths if needed
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'providers/cart_provider.dart'; // Your CartProvider path

const String supabaseUrl = 'https://ubnqsjeciseaisghyljq.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVibnFzamVjaXNlYWlzZ2h5bGpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4ODIzODgsImV4cCI6MjA2MDQ1ODM4OH0.DFLvL55rZZNQ_mxAgjbrcGK7MWALjJtb0TA1dP0Fh3Y';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before calling native code.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Run the app
  runApp(const MyApp());
}

// Global Supabase client instance (consider dependency injection for larger apps)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide CartProvider to the widget tree
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'Natural Food Store', // Or your app's title
        debugShowCheckedModeBanner: false, // Hide debug banner

        // --- Apply Theme with Custom Font ---
        theme: _buildTheme(context), // Use a helper method for theme

        // Determine initial screen based on login state
        home: supabase.auth.currentSession != null
            ? const MainScreen() // Go to main app if logged in
            : const WelcomeScreen(), // Start with Welcome screen otherwise
      ),
    );
  }

  // Helper method to build the theme data
  ThemeData _buildTheme(BuildContext context) {
    // Start with a base theme
    final ThemeData base = ThemeData(
      primarySwatch: Colors.green, // Base color scheme
      scaffoldBackgroundColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Define non-text styles first
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          // Ensure enabled matches border
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIconColor: Colors.grey[600],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF6ABF4B), // Consider using theme primary color
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black54,
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          titleTextStyle: TextStyle(
            // Font family will be inherited, just specify differences
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500, // Medium weight for titles
          )),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            Colors.amber[800], // Consider using theme primary/secondary
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );

    // Apply the Google Font text theme on top of the base theme
    return base.copyWith(
      textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme),
      // Apply font specifically to AppBar title if needed (though it should inherit)
      // appBarTheme: base.appBarTheme.copyWith(
      //   titleTextStyle: GoogleFonts.beVietnamPro(
      //     color: Colors.black87,
      //     fontSize: 20,
      //     fontWeight: FontWeight.w500,
      //   ),
      // ),
    );
  }
}
