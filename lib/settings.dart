import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          // Replace 'displayName' and 'photoURL' with the actual field names in your Firestore document
          userName = userDoc['displayName'] ?? userName; // Update field name
          userPhotoUrl = userDoc['photoURL'] ?? userPhotoUrl; // Update field name
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

  @override
  Widget build(BuildContext context) {
    // Cyberpunk color scheme
    final ColorScheme colorScheme = isDarkMode
        ? const ColorScheme.dark(
            // Dark mode (cyberpunk night)
            primary: Color(0xFFFF0077), // Neon pink/magenta
            secondary: Color(0xFF00E5FF), // Cyan/teal
            tertiary: Color(0xFFFFDD00), // Yellow accent
            surface: Color(0xFF1A1A2E), // Deep blue-purple
            background: Color(0xFF0F0F1B), // Very dark blue-purple
            error: Color(0xFFFF3D00),
          )
        : const ColorScheme.dark(
            // Light mode (still cyberpunk-inspired but brighter)
            primary: Color(0xFFFF0077), // Neon pink/magenta
            secondary: Color(0xFF00E5FF), // Cyan/teal
            tertiary: Color(0xFFFFDD00), // Yellow accent
            surface: Color(0xFF2E2E44), // Lighter blue-purple
            background: Color(0xFF232339), // Medium blue-purple
            error: Color(0xFFFF3D00),
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
          bodyMedium: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: textSize - 2,
            color: Colors.white.withOpacity(0.9),
          ),
          titleLarge: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          labelLarge: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            return states.contains(MaterialState.selected)
                ? colorScheme.primary
                : Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            return states.contains(MaterialState.selected)
                ? colorScheme.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: colorScheme.primary,
          thumbColor: colorScheme.primary,
          overlayColor: colorScheme.primary.withOpacity(0.2),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        dividerTheme: DividerThemeData(
          color: colorScheme.primary.withOpacity(0.2),
          thickness: 1.0,
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.background,
                colorScheme.background.withBlue((colorScheme.background.blue - 15).clamp(0, 255)),
              ],
            ),
          ),
          child: ListView(
            children: [
              // Profile Section with glowing border
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.7),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Picture with glow effect
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary.withOpacity(0.3),
                        backgroundImage: userPhotoUrl != null
                            ? NetworkImage(userPhotoUrl!)
                            : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                        onBackgroundImageError: (exception, stackTrace) {
                          return;
                        },
                        child: userPhotoUrl == null
                            ? Icon(Icons.person, size: 50, color: colorScheme.secondary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username with cyber style
                    Text(
                      userName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 20,
                        color: colorScheme.primary,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: colorScheme.primary.withOpacity(0.7),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
       
                  ],
                ),
              ),

              const Divider(height: 1),

              // Appearance Settings
              _buildSettingCategory('APPEARANCE'),
              
              _buildSettingTile(
                icon: Icons.dark_mode,
                title: 'DARK MODE',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                ),
                colorScheme: colorScheme,
                textSize: textSize,
              ),

              _buildSettingTile(
                icon: Icons.format_size,
                title: 'TEXT SIZE',
                subtitle: Slider(
                  value: textSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  label: textSize.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      textSize = value;
                    });
                  },
                ),
                colorScheme: colorScheme,
                textSize: textSize,
              ),

              const Divider(height: 1),

              // Notification Settings
              _buildSettingCategory('NOTIFICATIONS'),
              
              _buildSettingTile(
                icon: Icons.notifications,
                title: 'PUSH NOTIFICATIONS',
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
                colorScheme: colorScheme,
                textSize: textSize,
              ),

              const Divider(height: 1),

              // About & Help
              _buildSettingCategory('SYSTEM'),
              
              _buildSettingTile(
                icon: Icons.info,
                title: 'ABOUT',
                onTap: () {
                  // Navigate to About page
                },
                colorScheme: colorScheme,
                textSize: textSize,
              ),

              _buildSettingTile(
                icon: Icons.help,
                title: 'HELP',
                onTap: () {
                  // Navigate to Help page
                },
                colorScheme: colorScheme,
                textSize: textSize,
              ),

              const SizedBox(height: 30),

              // Logout Button with neon effect
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    onPressed: _logout,
                    child: const Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontFamily: 'PixelFont', 
                        fontSize: 16,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
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
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    required double textSize,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: textSize,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}