import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'terms_condition.dart'; // Import the Terms and Conditions page
import 'address.dart';
import 'faqs.dart';
import 'bank_accounts.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User settings
  bool isDarkMode = true; // Default to dark mode for cyberpunk theme
  bool notificationsEnabled = true;
  double textSize = 16.0;

  // User profile data
  User? user;
  String userName = "User_0x7F";
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchUserData();
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      setState(() {
        user = FirebaseAuth.instance.currentUser;
        userName = user?.displayName ?? "User_0x7F";
        userPhotoUrl = user?.photoURL;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['displayName'] ?? userName;
            userPhotoUrl = userDoc['photoURL'] ?? userPhotoUrl;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch user data: $e'),
          backgroundColor: const Color(0xFFFF0055),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: const Color(0xFFFF0055),
        ),
      );
    }
  }

  IconData _getIconForTitle(String title) {
    // Map of titles to icons
    const iconMap = {
      'My Profile': Icons.person,
      'My Addresses': Icons.location_on,
      'Bank Account/Cards': Icons.credit_card,
      'Chat Settings': Icons.chat,
      'Notification Settings': Icons.notifications,
      'Privacy Settings': Icons.privacy_tip,
      'Blocked users': Icons.block,
      'Language': Icons.language,
      'ABOUT': Icons.info,
      'FAQS': Icons.help_center,
      'Shopee Policies': Icons.policy,
      'Rate us': Icons.star_rate,
      'HELP': Icons.help_outline,
      'TERMS AND CONDITIONS': Icons.description,
      'Request Account Deletion': Icons.delete_forever,
    };

    // Return the corresponding icon or a default icon
    return iconMap[title] ?? Icons.settings;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = isDarkMode
        ? const ColorScheme.dark(
            primary: Color(0xFFFF0077),
            secondary: Color(0xFF00E5FF),
            surface: Color(0xFF1A1A2E),
            background: Color(0xFF0F0F1B),
          )
        : const ColorScheme.light(
            primary: Color(0xFFFF0077),
            secondary: Color(0xFF00E5FF),
            surface: Color(0xFF2E2E44),
            background: Color(0xFF232339),
          );

    return Theme(
      data: ThemeData(
        colorScheme: colorScheme,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: textSize,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SETTINGS',
            style: TextStyle(
              fontFamily: 'PixelFont',
              letterSpacing: 2.0,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          children: [
            // SYSTEM Section
            _buildSettingCategory('MY ACCOUNT'),
            _buildSettingTile(
              title: 'My Profile',
              onTap: () {
                // Navigate to My Profile
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'My Addresses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AddressPage(), // Replace with your account page widget
                  ),
                );
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            // In _buildSettingTile for Bank Account/Cards
            _buildSettingTile(
              title: 'Bank Account/Cards',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankAccountsPage(),
                  ),
                );
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingCategory('SYSTEM'),
            _buildSettingTile(
              title: 'Chat Settings',
              onTap: () {
                // Navigate to Chat Settings
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Notification Settings',
              onTap: () {
                // Navigate to Notification Settings
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Privacy Settings',
              onTap: () {
                // Navigate to Privacy Settings
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Blocked users',
              onTap: () {
                // Navigate to Blocked Users
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Language',
              onTap: () {
                // Navigate to Language Settings
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingCategory('Support'),
            _buildSettingTile(
              title: 'ABOUT',
              onTap: () {
                // Navigate to About
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'FAQS and Help',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FAQPage(), // Navigate to FAQS page
                  ),
                );
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'FAQS and Help',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FAQPage(), // Navigate to FAQS page
                  ),
                );
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Shopee Policies',
              onTap: () {
                // Navigate to Shopee Policies
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Rate us',
              onTap: () {
                // Navigate to Rate Us
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'HELP',
              onTap: () {
                // Navigate to Help
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'TERMS AND CONDITIONS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TermsAndConditionsPage()),
                );
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
            _buildSettingTile(
              title: 'Request Account Deletion',
              onTap: () {
                // Navigate to Request Account Deletion
              },
              colorScheme: colorScheme,
              textSize: textSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'PixelFont',
          fontSize: 14,
          color: const Color(0xFF00E5FF),
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required ColorScheme colorScheme,
    required double textSize,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(_getIconForTitle(title), color: colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'PixelFont',
          fontSize: textSize,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}
