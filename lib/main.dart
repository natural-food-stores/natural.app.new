import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // <-- Import provider

// Adjust these paths if needed
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'providers/cart_provider.dart'; // <-- Import your CartProvider

// TODO: Replace with your actual Supabase URL and Anon Key
const String supabaseUrl = 'https://ubnqsjeciseaisghyljq.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVibnFzamVjaXNlYWlzZ2h5bGpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4ODIzODgsImV4cCI6MjA2MDQ1ODM4OH0.DFLvL55rZZNQ_mxAgjbrcGK7MWALjJtb0TA1dP0Fh3Y';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  // No need to wrap MyApp here, wrap MaterialApp inside MyApp instead
  runApp(const MyApp());
}

// Get a reference to the Supabase client (accessible globally)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // *** FIX: Wrap MaterialApp with ChangeNotifierProvider ***
    return ChangeNotifierProvider(
      create: (context) => CartProvider(), // Creates the CartProvider instance
      child: MaterialApp(
        // MaterialApp is now the child
        title: 'Natural Food Store',
        debugShowCheckedModeBanner: false, // Remove debug banner
        theme: ThemeData(
          // --- Your existing theme data ---
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
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
                backgroundColor: const Color(0xFF6ABF4B),
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
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              )),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.amber[800],
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.white,
            elevation: 8.0,
          ),
          // --- End of your theme data ---
        ),
        // Check if user is logged in, navigate to MainScreen if true
        // These screens can now access CartProvider via context
        home: supabase.auth.currentSession != null
            ? const MainScreen() // Go to main app shell if logged in
            : const WelcomeScreen(), // Start with Welcome screen otherwise
      ),
    );
  }
}
