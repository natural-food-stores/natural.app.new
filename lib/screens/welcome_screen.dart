import 'package:flutter/material.dart';
import 'login_screen.dart'; // Need this for navigation

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Use a Stack to layer elements: Background -> Logo -> Content
      body: Stack(
        fit: StackFit.expand, // Make stack children fill the screen
        children: <Widget>[
          // 1. Background Image
          Image.asset(
            'assets/welcome_background.jpg', // <-- Your new background image path
            fit: BoxFit.cover, // Cover the entire screen
            errorBuilder: (context, error, stackTrace) {
              // Placeholder if background image fails
              return Container(
                color: Colors.grey[200],
                child: const Center(
                    child: Text('Background image not found\nAdd to assets/')),
              );
            },
          ),

          // Optional: Add a semi-transparent overlay for better text readability
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.5)],
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //     ),
          //   ),
          // ),

          // 2. Logo at the Top
          Positioned(
            top: screenHeight *
                0.1, // Adjust vertical position as needed (e.g., 10% from top)
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/logo.png', // <-- YOUR LOGO IMAGE PATH
              height: screenHeight * 0.15, // Adjust logo size as needed
              errorBuilder: (context, error, stackTrace) {
                // Placeholder if logo image fails
                return SizedBox(
                    height: screenHeight * 0.15,
                    child: Center(
                        child: Text('Logo not found',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7)))));
              },
            ),
          ),

          // 3. Content Area (Text and Button) at the Bottom
          Positioned(
            bottom: screenHeight * 0.05, // Position content from the bottom
            left: screenWidth * 0.06, // Horizontal padding
            right: screenWidth * 0.06, // Horizontal padding
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Column takes minimum space needed
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Welcome Text
                const Text(
                  'Welcome to our store',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: <Shadow>[
                      // Add subtle shadow for better readability
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(150, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle Text
                const Text(
                  // Using placeholder text as it's obscured in the image
                  'Get your groceries delivered fresh to your door',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(150, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Space between text and button

                // Get Started Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6ABF4B), // Vibrant green color
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(double.infinity, 50), // Make button wide
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Navigate to the Login Screen when button is pressed
                    Navigator.pushReplacement(
                      // Use pushReplacement if you don't want users to go back to Welcome
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
