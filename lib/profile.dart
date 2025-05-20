import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';
import 'order_history.dart';
import 'seller_register.dart';
import 'login.dart';
import 'home.dart';
import 'see_all_recommend.dart';
import 'category.dart';
import 'message.dart'; // Import the Message screen

class AppColors {
  // Primary colors
  static final Color background = Colors.black;
  static final Color surface = Colors.grey.shade900.withOpacity(0.5);
  static final Color border = Colors.grey.shade800;
  
  // Accent colors
  static final Color primary = Colors.pink.shade400;
  static final Color secondary = Colors.cyan;
  static final Color tertiary = Colors.purple.shade700;
  
  // Status colors
  static final Color success = Colors.green.shade500;
  static final Color warning = Colors.amber.shade500;
  static final Color error = Colors.red.shade500;
  
  // Text colors
  static final Color textPrimary = Colors.white;
  static final Color textSecondary = Colors.grey.shade400;
  
  // Gradients
  static final Gradient primaryGradient = LinearGradient(
    colors: [Colors.pink.shade700, Colors.pink.shade900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final Gradient secondaryGradient = LinearGradient(
    colors: [Colors.cyan.shade600, Colors.blue.shade800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final Gradient tertiaryGradient = LinearGradient(
    colors: [Colors.purple.shade700, Colors.purple.shade900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static final Gradient destructiveGradient = LinearGradient(
    colors: [Colors.red.shade700, Colors.red.shade900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> favorites = [];
  List<Map<String, dynamic>> purchases = []; // Products the user has bought
  String sellerStatus = "notApplied";
  bool isAdmin = false;
  int totalPurchases = 0;

  // Current index for bottom navigation
  int _currentNavIndex = 4; // Profile is the 5th item (index 4)

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchFavorites(); // Ensure this is called
    _loadPurchases();
    _checkSellerApplicationStatus(); // Check seller application status
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final favoritesRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites');

        final querySnapshot = await favoritesRef.get();

        if (querySnapshot.docs.isEmpty) {
          print("No favorites found for user: ${user.uid}");
        }

        setState(() {
          favorites = querySnapshot.docs.map((doc) {
            final data = doc.data();
            print("Fetched favorite: ${data['title']}");
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Unknown',
              'imageUrl': data['imageUrl'] ?? '',
            };
          }).toList();
        });
      } catch (e) {
        print("Error fetching favorites: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load favorites: $e',
                style: const TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print("User is not authenticated.");
    }
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          sellerStatus =
              userData?['sellerStatus'] ?? "notApplied"; // Check seller status
          isAdmin = userData?['isAdmin'] ?? false;
        });
      }
    } else {
      setState(() {
        user = null;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      setState(() {
        favorites = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Unknown',
            'imageUrl': data['imageUrl'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _checkSellerApplicationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Check if the user has a seller application
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellerApplications')
            .doc(currentUser.uid)
            .get();

        // Also check the users collection to get the current status
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        setState(() {
          if (sellerDoc.exists) {
            final data = sellerDoc.data();
            // Get the actual sellerStatus from the user document
            if (userDoc.exists && userDoc.data()?['sellerStatus'] != null) {
              sellerStatus = userDoc.data()?['sellerStatus'];
            } else if (data != null) {
              // Fallback to application data if user document doesn't have status
              sellerStatus = data['sellerStatus'] ?? "pending";
            }
            
            // Debug print the status
            debugPrint("Current seller status: $sellerStatus");
          } else {
            sellerStatus = "notApplied"; // No application found
          }
        });

        if (sellerDoc.exists) {
          debugPrint(
              "Seller application found: ${sellerDoc.data()?['storeName']}");
        } else {
          debugPrint(
              "No seller application found for user: ${currentUser.uid}");
        }
      } catch (e) {
        debugPrint("Error checking seller application status: $e");
      }
    }
  }

  Future<void> _loadPurchases() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .get();

      setState(() {
        totalPurchases = querySnapshot.docs.length;
      });
    } catch (e) {
      print('Error loading purchases: $e');
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Logs out from Firebase
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const Login()), // Navigate to LoginScreen
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void _navigateToMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistory()),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
    );
  }

  void _navigateToSeller() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerRegistrationScreen()),
    );
  }

  void _navigateToShippingAddress() {
    // Navigate to shipping address page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shipping Address coming soon')),
    );
  }

  void _navigateToSellerDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerDashboard()),
    );
  }

  void _navigateWithBottomBar(int index) {
    if (index == _currentNavIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const CategoryPage();
        break;
      case 2:
        page = const ChatPage(); // Navigate to Message screen
        break;
      case 3:
        page = const SeeAllProductsScreen(); // Navigate to Shop screen
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        page = const HomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Sign in prompt widget for users who aren't logged in
  Widget _buildSignInPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or image
            Icon(
              Icons.account_circle,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Sign in to view your profile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Access your games, orders, and seller features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Sign in button
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sign up text button
            TextButton(
              onPressed: () {
                // Navigate to sign up screen (login screen with signup tab)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                );
              },
              child: Text(
                'New user? Sign up here',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (user == null) {
      return _buildSignInPrompt(context);
    }

    // If user is logged in, show profile screen
    final String userName = user?.displayName ?? "Guest";
    final String? userPhotoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, // Change this to true if you want default back button
        // Add a custom back button at the start of the AppBar
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new, 
            color: AppColors.primary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              // Navigate to settings
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Coming Soon",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Settings feature will be available in the next update.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Top profile bar with edit button - Improved design
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Profile picture with glowing effect
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: userPhotoUrl != null
                          ? Image.network(
                              userPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/default_profile_picture.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Username and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.tertiary, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'LVL ${userData?['level'] ?? 100}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (sellerStatus == "approved")
                          Row(
                            children: [
                              Icon(Icons.verified, color: AppColors.secondary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Seller',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                  fontFamily: 'PixelFont',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Edit profile button - improved design
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats bar - Improved with cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Total Games Card
                  Expanded(
                    child: _buildStatsCard(
                      'Total Games',
                      '$totalPurchases',
                      Icons.games,
                      Colors.pink.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Friends Card
                  Expanded(
                    child: _buildStatsCard(
                      'Friends',
                      '${userData?['friendCount'] ?? 1}',
                      Icons.people,
                      Colors.purple.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Order History Card with button
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToMyOrders,
                      child: _buildStatsCard(
                        'Orders',
                        'View',
                        Icons.history,
                        Colors.cyan.shade400,
                        isButton: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Favorites section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.pink.shade400, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'FAVOURITES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey.shade400),
                    onPressed: _fetchFavorites,
                  ),
                ],
              ),
            ),

            // Favorites grid - improved styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: favorites.isNotEmpty
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = favorites[index];
                        return _buildFavoriteItem(favorite);
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border,
                              color: Colors.pink.shade300, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No favorites yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Heart your favorite games to see them here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            // Additional options section - improved styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800),
                  bottom: BorderSide(color: Colors.grey.shade800),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.settings, color: Colors.cyan),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ACCOUNT SETTINGS',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Options buttons - with improved styling
                  if (isAdmin)
                    _buildNavButton(
                      'Admin Dashboard', 
                      _navigateToAdminDashboard,
                      icon: Icons.admin_panel_settings,
                      gradient: LinearGradient(
                        colors: [Colors.red.shade700, Colors.purple.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  _buildNavButton(
                    'My Orders', 
                    _navigateToMyOrders,
                    icon: Icons.history,
                  ),
                  if (sellerStatus == "approved")
                    _buildNavButton(
                      'Manage Store',
                      _navigateToSellerDashboard,
                      icon: Icons.store,
                      gradient: LinearGradient(
                        colors: [Colors.cyan.shade700, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  if (sellerStatus == "notApplied")
                    _buildNavButton(
                      'Become a Seller',
                      _navigateToSeller,
                      icon: Icons.store,
                    ),
                  if (sellerStatus == "pending")
                    _buildNavButton(
                      'Check Application Status',
                      _showSellerStatusDialog,
                      icon: Icons.hourglass_top,
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.orange.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  _buildNavButton(
                    'Shipping Address',
                    _navigateToShippingAddress,
                    icon: Icons.local_shipping,
                  ),
                  const SizedBox(height: 8),
                  _buildNavButton(
                    'Logout', 
                    _handleLogout,
                    isDestructive: true, 
                    icon: Icons.logout,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Footer with version info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Cyberpunk Games v1.0',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontFamily: 'PixelFont',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
        unselectedItemColor: Colors.white,
        currentIndex: _currentNavIndex,
        onTap: _navigateWithBottomBar,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
            tooltip: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: 'Category',
            tooltip: 'Category',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message),
            label: 'Message',
            tooltip: 'Message',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shop),
            label: 'Shop',
            tooltip: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Profile',
            tooltip: 'Profile',
          ),
        ],
        selectedLabelStyle: const TextStyle(
          fontFamily: 'PixelFont', // Use PixelFont for selected labels
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PixelFont', // Use PixelFont for unselected labels
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper method for stats cards
  Widget _buildStatsCard(String title, String value, IconData icon, Color color, {bool isButton = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 4),
          isButton
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }

  // Improved favorite item card
  Widget _buildFavoriteItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Favorite item image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                      ? Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _placeholder(item['title']);
                          },
                        )
                      : _placeholder(item['title']),
                ),
                // Favorite icon overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.favorite, color: Colors.pink.shade400, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Favorite item title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Text(
              item['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Improved navigation button
  Widget _buildNavButton(String title, VoidCallback onTap,
      {bool isDestructive = false, IconData? icon, Gradient? gradient}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.grey.shade900.withOpacity(0.5) : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDestructive 
                ? Colors.red.withOpacity(0.2) 
                : Colors.cyan.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.2) 
                : Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red.shade300 : Colors.cyan,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red.shade300 : Colors.white,
            fontSize: 16,
            fontFamily: 'PixelFont',
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? Colors.red.shade300 : Colors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Improved placeholder
  Widget _placeholder(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Text(
          title.substring(0, title.length > 2 ? 2 : title.length),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showSellerStatusDialog() async {
    // Get the latest status from Firestore to ensure it's current
    await _checkSellerApplicationStatus();
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String statusTitle;
        String statusMessage;
        Color statusColor;
        IconData statusIcon;
        String additionalInfo = "";
        
        switch (sellerStatus) {
          case "pending":
            statusTitle = "Application Pending Approval";
            statusMessage = "Your seller application is waiting for admin approval. This usually takes 1-2 business days.";
            statusColor = AppColors.warning;
            statusIcon = Icons.hourglass_top;
            additionalInfo = "You will be notified when your application is approved.";
            break;
          case "approved":
            statusTitle = "Application Approved!";
            statusMessage = "Congratulations! Your seller account is active. You can now list games and manage your store.";
            statusColor = AppColors.success;
            statusIcon = Icons.check_circle;
            break;
          case "rejected":
            statusTitle = "Application Declined";
            statusMessage = "Unfortunately, your application was not approved. Please contact customer support for more information.";
            statusColor = AppColors.error;
            statusIcon = Icons.cancel;
            break;
          default:
            statusTitle = "Status Unknown";
            statusMessage = "We couldn't determine your application status. Please try again later.";
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }
        
        return AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: statusColor, width: 2),
          ),
          title: Text(
            statusTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'PixelFont',
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        statusIcon,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  additionalInfo,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "Application Date: ${userData?['joinDate'] ?? 'Unknown'}",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
