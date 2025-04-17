import 'package:flutter/gestures.dart'; // Import for RichText Taps
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'register_screen.dart'; // Link to Register
import '../main.dart'; // Import main to access supabase client easily

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false; // Keep for password functionality

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Check if login was successful (user is not null)
        if (res.user != null && mounted) {
          // Navigate to HomeScreen and remove login screen from stack
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An unexpected error occurred.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // No AppBar
      backgroundColor: Colors.white, // Set background to white
      body: SafeArea(
        // Use SafeArea to avoid status bar overlap
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Top Image Section
              Container(
                height: screenHeight * 0.35, // Adjust height as needed
                width: double.infinity,
                child: Image.asset(
                  'assets/groceries_banner.png', // <-- Replace with your image path
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Placeholder if image fails to load
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                          child: Text('Image not found\nAdd to assets/')),
                    );
                  },
                ),
              ),
              // Add some space between image and text
              const SizedBox(height: 24),

              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth *
                        0.06), // ~24 logical pixels on average screens
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Text Section
                    const Text(
                      'Welcome back!',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get your groceries with Natural Food Store',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. Form Section
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Colors.grey),
                              filled: true,
                              fillColor:
                                  Colors.grey[100], // Light grey background
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none, // No border line
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.grey),
                              // You can add the visibility toggle back if needed
                              // suffixIcon: IconButton(
                              //   icon: Icon(
                              //     _passwordVisible
                              //     ? Icons.visibility_off_outlined
                              //     : Icons.visibility_outlined,
                              //     color: Colors.grey,
                              //   ),
                              //   onPressed: () {
                              //     setState(() {
                              //        _passwordVisible = !_passwordVisible;
                              //      });
                              //    },
                              //  ),
                              filled: true,
                              fillColor:
                                  Colors.grey[100], // Light grey background
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none, // No border line
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                            obscureText: !_passwordVisible,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4. Buttons Section
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                            0xFF6ABF4B), // Vibrant green color from image
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2, // Subtle shadow
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, // Match text size
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                          : const Text('Login with Email',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                            0xFF6ABF4B), // Vibrant green color from image
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2, // Subtle shadow
                      ),
                      onPressed: () {
                        // Navigate to Register Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Register with Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 32), // Space before footer

                    // 5. Footer Text Section
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        children: <TextSpan>[
                          const TextSpan(
                              text: 'By continuing, you agree to the '),
                          TextSpan(
                            text: 'Terms of service',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Implement navigation or show terms
                                print('Terms of Service Tapped!');
                              },
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Implement navigation or show policy
                                print('Privacy Policy Tapped!');
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
