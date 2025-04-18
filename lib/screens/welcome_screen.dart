import 'package:flutter/material.dart';
import 'login_screen.dart'; // Need this for navigation

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // Make stack children fill the screen
        children: <Widget>[
          // 1. Background Image
          Image.asset(
            'assets/welcome_background.jpg', // <-- Your background image path
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                    child: Text('Background image not found\nAdd to assets/')),
              );
            },
          ),

          // 2. Logo at the Top
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/logo.png', // <-- YOUR LOGO IMAGE PATH
              height: screenHeight * 0.15,
              errorBuilder: (context, error, stackTrace) {
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
            bottom: screenHeight * 0.05,
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 40),

                // Get Started Button (Uses theme)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Get Started'), // Text style from theme
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
