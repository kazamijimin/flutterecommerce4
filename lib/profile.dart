import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';
import 'order_history.dart';

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
    _loadFavorites();
    _loadPurchases(); // Load purchase history
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
          sellerStatus = userData?['sellerStatus'] ?? "notApplied";
          isAdmin = userData?['isAdmin'] ?? false;
        });
      }
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
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  void _navigateToMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistory()),
    );
  }

  void _navigateToShippingAddress() {
    // Navigate to shipping address page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shipping Address coming soon')),
    );
  }

  void _navigateToFAQs() {
    // Navigate to FAQs page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQs coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = user?.displayName ?? "Guest";
    final String? userPhotoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      body: RefreshIndicator(
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
                        border: Border.all(color: Colors.white, width: 2),
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
                        backgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.black,
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
                color: const Color(0xFF1A1A2E),
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
                            color: Colors.red,
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
                            color: Colors.red,
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
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorites section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Favourites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteItem(favorites[index]);
                        },
                      )
                    : const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No favourites yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ),
              ),

              // Edit favorites button
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () {
                    // Edit favorites functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Edit Favourites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional options section
              _buildNavButton('My Orders', _navigateToMyOrders),
              _buildNavButton('Shipping Address', _navigateToShippingAddress),
              _buildNavButton('FAQs', _navigateToFAQs),
              _buildNavButton('Logout', _handleLogout, isDestructive: true),

              const SizedBox(height: 32),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Game image
          Expanded(
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
          // Game title
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8),
            child: Text(
              item['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'PixelFont',
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
      {bool isDestructive = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDestructive ? Colors.red.shade900 : Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.white : Colors.cyan,
            fontSize: 16,
            fontFamily: 'PixelFont',
          ),
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
            fontSize: 16,
            fontFamily: 'PixelFont',
          ),
        ),
      ),
    );
  }
}
