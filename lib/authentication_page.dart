import 'package:flutter/material.dart';
import 'package:flutterecommerce4/home.dart';
import 'package:flutterecommerce4/login.dart';
import 'package:flutterecommerce4/signup.dart';


class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A16), // Dark blue-black background
        child: Column(
          children: [
            // Cyberpunk city image (top section)
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A16),
                  image: DecorationImage(
                    image: AssetImage('assets/images/cyberpunk_city.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top right "Republic" badge
                    Positioned(
                      top: 40,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0066),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REPUBLIC 8',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
                    ),
                    // Top left ROG-style logo
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFF0066), width: 1),
                        ),
                        child: const Icon(
                          Icons.gamepad,
                          color: Color(0xFFFF0066),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Welcome header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.black,
              child: Column(
                children: [
                  Text(
                    'Welcome to Gamebox',
                    style: TextStyle(
                      color: const Color(0xFFFF0066),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your authentication method',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ],
              ),
            ),

            // Authentication buttons area
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                color: const Color(0xFF161625), // Dark blue background
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login button
                    Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
                    ),

                    // Sign up button
                    Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0066),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Signup()),
                          );
                        },
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
                    ),

                    // Continue as Guest button
                    Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        child: const Text(
                          'CONTINUE AS GUEST',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}