import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterecommerce4/shopee_policies.dart';
import 'login.dart';
import 'terms_condition.dart'; // Import the Terms and Conditions page
import 'address.dart';
import 'faqs.dart';
import 'bank_accounts.dart';
import 'about_us.dart';
import 'team_members.dart';
import 'help_center.dart';
import 'rate_us.dart';
import 'account_deletion.dart';
import 'profile.dart';
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
      'ABOUT': Icons.info,
      'TEAM MEMBERS': Icons.groups, // Add this line
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSettingCategory('MY ACCOUNT'),
          _buildSettingTile(
            title: 'My Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _buildSettingTile(
            title: 'My Addresses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddressPage()),
              );
            },
          ),
          _buildSettingTile(
            title: 'Bank Account/Cards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BankAccountsPage()),
              );
            },
          ),

          _buildSettingCategory('SUPPORT'),
          _buildSettingTile(
            title: 'ABOUT',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),
          _buildSettingTile(
            title: 'TEAM MEMBERS',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamMembersPage(),
                ),
              );
            },
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
          ),
          _buildSettingTile(
            title: 'GameBox Policies',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopeePoliciesPage(),
                ),
              );
            },
          ),
          // In your settings.dart file, update the Rate us tile
          _buildSettingTile(
            title: 'Rate us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RateUsPage(),
                ),
              );
            },
          ),
          // In your settings.dart file, update the Help tile
          _buildSettingTile(
            title: 'HELP',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterPage(),
                ),
              );
            },
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
          ),
          // In your settings.dart file, update the Request Account Deletion tile
          _buildSettingTile(
            title: 'Request Account Deletion',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountDeletionPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: Color(0xFF00E5FF),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333355),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF0077),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getIconForTitle(title),
                    color: const Color(0xFFFF0077),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFF0077),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ...rest of your existing code (IconData mapping, etc.)
}
