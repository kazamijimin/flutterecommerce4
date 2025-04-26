import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';
import 'order_history.dart';
import 'seller_register.dart';
import 'login.dart';

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

  // Sign in prompt widget for users who aren't logged in
  Widget _buildSignInPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or image
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.pink,
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Sign in to view your profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Access your games, orders, and seller features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
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
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
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
              child: const Text(
                'New user? Sign up here',
                style: TextStyle(
                  color: Colors.cyan,
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
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: Colors.pink,
        backgroundColor: Colors.black,
        onRefresh: () async {
          await _loadUser();
          await _loadFavorites();
          await _loadPurchases();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Top profile bar with edit button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                color: Colors.black,
                child: Row(
                  children: [
                    // Profile picture
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pink, width: 2),
                      ),
                      child: userPhotoUrl != null
                          ? Image.network(
                              userPhotoUrl,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/default_profile_picture.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Username and level
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'lvl ${userData?['level'] ?? 100}',
                            style: const TextStyle(
                              color: Colors.pink,
                              fontSize: 18,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          if (sellerStatus == "approved")
                            const Text(
                              'Verified Seller',
                              style: TextStyle(
                                color: Colors.cyan,
                                fontSize: 16,
                                fontFamily: 'PixelFont',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Edit profile button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black, // Moved color inside BoxDecoration
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800),
                    bottom: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Total products purchased
                    Column(
                      children: [
                        const Text(
                          'Total Games',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalPurchases',
                          style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 20,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Friends (placeholder)
                    Column(
                      children: [
                        const Text(
                          'Friends',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${userData?['friendCount'] ?? 1}',
                          style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 20,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Order history button
                    Column(
                      children: [
                        const Text(
                          'Order History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.3),
                            border: Border.all(color: Colors.pink),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: GestureDetector(
                            onTap: _navigateToMyOrders,
                            child: const Text(
                              'View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorites section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Favourites',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'PixelFont',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.favorite, color: Colors.pink),
                  ],
                ),
              ),

              // Favorites grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: favorites.isNotEmpty
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];
                          return _buildFavoriteItem(favorite);
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.favorite_border,
                                color: Colors.pink, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'No favorites yet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Refresh favorites button
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _fetchFavorites,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Refresh Favorites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional options section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu, color: Colors.cyan),
                        const SizedBox(width: 8),
                        const Text(
                          'ACCOUNT SETTINGS',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin)
                      _buildNavButton(
                          'Admin Dashboard', _navigateToAdminDashboard,
                          icon: Icons.admin_panel_settings),
                    _buildNavButton('My Orders', _navigateToMyOrders,
                        icon: Icons.history),
                    if (sellerStatus == "approved")
                      _buildNavButton(
                        'Manage Store', // Updated name
                        _navigateToSellerDashboard,
                        icon: Icons.store,
                      ),
                    if (sellerStatus == "notApplied")
                      _buildNavButton(
                        'Become a Seller', // Updated name
                        _navigateToSeller,
                        icon: Icons.store,
                      ),
                    if (sellerStatus == "pending")
                      _buildNavButton(
                        'Check Application Status', 
                        _showSellerStatusDialog,
                        icon: Icons.hourglass_top,
                      ),
                    if (sellerStatus == "approved")
                      _buildNavButton(
                        'Manage Store', // Updated name
                        _navigateToSellerDashboard,
                        icon: Icons.store,
                      ),
                    _buildNavButton(
                        'Shipping Address', _navigateToShippingAddress,
                        icon: Icons.local_shipping),
                    _buildNavButton('Logout', _handleLogout,
                        isDestructive: true, icon: Icons.logout),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Favorite item image
          Expanded(
            child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      item['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _placeholder(item['title']);
                      },
                    ),
                  )
                : _placeholder(item['title']),
          ),
          // Favorite item title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey.shade800),
              ),
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

  Widget _buildNavButton(String title, VoidCallback onTap,
      {bool isDestructive = false, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: isDestructive ? Colors.white : Colors.cyan),
        label: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.white : Colors.cyan,
            fontSize: 16,
            fontFamily: 'PixelFont',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDestructive ? Colors.red.shade900 : Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Text(
          title.substring(0, title.length > 2 ? 2 : title.length),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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
            statusColor = Colors.amber;
            statusIcon = Icons.hourglass_top;
            additionalInfo = "You will be notified when your application is approved.";
            break;
          case "approved":
            statusTitle = "Application Approved!";
            statusMessage = "Congratulations! Your seller account is active. You can now list games and manage your store.";
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case "rejected":
            statusTitle = "Application Declined";
            statusMessage = "Unfortunately, your application was not approved. Please contact customer support for more information.";
            statusColor = Colors.red;
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
            style: const TextStyle(
              color: Colors.white,
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
                  border: Border.all(color: Colors.grey.shade800),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "Application Date: ${userData?['joinDate'] ?? 'Unknown'}",
                style: const TextStyle(
                  color: Colors.grey,
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
                child: const Text(
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
