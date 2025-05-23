import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'ABOUT US',
          style: TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Logo
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0077).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'GX',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.7),
                              offset: const Offset(0, 2),
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App Name
                  const Text(
                    'GAMEBOX',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // App Version
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E5FF)),
                    ),
                    child: const Text(
                      'VERSION 1.0.0',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 12,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Our Story Section
            _buildSection(
              title: 'OUR STORY',
              icon: Icons.auto_stories,
              content:
                  'Founded in 2023, GameBox emerged from a vision to create the ultimate digital marketplace for gamers. Our platform bridges the gap between indie developers and AAA studios, offering players the most diverse collection of games on the market.',
              color: const Color(0xFFFF0077),
            ),

            // Mission Section
            _buildSection(
              title: 'OUR MISSION',
              icon: Icons.rocket_launch,
              content:
                  'GameBox is committed to revolutionizing digital game distribution by creating an ecosystem where players can discover new worlds, developers can thrive, and communities can form around shared gaming experiences.',
              color: const Color(0xFF00E5FF),
            ),

            // The Team Section
            _buildSection(
              title: 'OUR TEAM',
              icon: Icons.groups,
              content:
                  'Our team consists of passionate gamers, developers, and industry veterans working together to create the best gaming marketplace possible. We understand what players want because we are players ourselves.',
              color: const Color(0xFFFFA500),
            ),

            // Features Section with cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(
                    children: [
                      Icon(
                        Icons.star_rate,
                        color: const Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'KEY FEATURES',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Feature cards
                  _buildFeatureCard(
                    'VAST GAME LIBRARY',
                    'Access thousands of games across all genres and platforms',
                    Icons.games,
                    const Color(0xFF8A2BE2),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'SECURE PAYMENTS',
                    'Multiple payment options with enterprise-grade security',
                    Icons.security,
                    const Color(0xFF00C853),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'COMMUNITY-DRIVEN',
                    'Reviews, ratings, and recommendations from fellow gamers',
                    Icons.forum,
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    'EXCLUSIVE DEALS',
                    'Weekly promotions and discounts on select titles',
                    Icons.local_offer,
                    const Color(0xFFFF5722),
                  ),
                ],
              ),
            ),

            // Contact Info
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                children: [
                  const Text(
                    'CONTACT US',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    Icons.email,
                    'support@gamebox.com',
                  ),
                  _buildContactItem(
                    Icons.phone,
                    '+1 (555) 123-4567',
                  ),
                  _buildContactItem(
                    Icons.location_on,
                    'Night City, CA 94103',
                  ),
                ],
              ),
            ),

            // Social Media Links
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.facebook, Colors.blue),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.telegram, Colors.lightBlue),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.discord, Colors.deepPurple),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.reddit, Colors.deepOrange),
                ],
              ),
            ),

            // Copyright
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              color: Colors.black,
              child: const Text(
                '© 2025 GameBox. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.5), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}