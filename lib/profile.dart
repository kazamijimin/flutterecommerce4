import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart'; // Import the SellerDashboard

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  Map<String, dynamic>? userData; // Store user data
  List<Map<String, dynamic>> favorites = [];
  String sellerStatus = "notApplied"; // Track seller application status
  bool isAdmin = false; // Track admin status

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFavorites(); // Load products from Firebase
  }

  // Reload user data
  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      // Fetch additional user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          sellerStatus =
              userData?['sellerStatus'] ?? "notApplied"; // Check seller status
          isAdmin = userData?['isAdmin'] ?? false; // Check admin status
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
          .collection('wishlist') // Fetch from wishlist collection
          .get();

      setState(() {
        favorites = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'title': data['title'] ?? 'Unknown',
            'image': data['imageUrl'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Function to apply to become a seller
  Future<void> _applyToBecomeSeller() async {
    if (user != null) {
      try {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user!.uid);

        // Update the Firestore document to set sellerStatus to "pending"
        await userDoc.set({'sellerStatus': 'pending'}, SetOptions(merge: true));

        setState(() {
          sellerStatus = "pending"; // Update the local state
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your application is under review.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = user?.displayName ?? "Guest User";
    final String userEmail = user?.email ?? "guest@example.com";
    final String? userPhotoUrl = user?.photoURL;
    final String gender = userData?['gender'] ?? "Not specified";
    final String phoneNumber = userData?['phone'] ?? "Not provided";
    final String age = userData?['age']?.toString() ?? "Not specified";
    final String memberSince = userData?['createdAt'] != null
        ? (userData!['createdAt'] as Timestamp)
            .toDate()
            .toLocal()
            .toString()
            .split(' ')[0]
        : "Unknown";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.cyan),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboard(),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUser();
          await _loadFavorites();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Seller Status: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                    Text(
                      sellerStatus == "approved"
                          ? 'Verified Seller'
                          : sellerStatus == "pending"
                              ? 'Pending Approval'
                              : 'Not a Seller',
                      style: TextStyle(
                        color: sellerStatus == "approved"
                            ? Colors.green
                            : sellerStatus == "pending"
                                ? Colors.orange
                                : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (sellerStatus == "notApplied")
                ElevatedButton(
                  onPressed: _applyToBecomeSeller,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply to Become a Seller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                )
              else if (sellerStatus == "approved")
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerDashboard(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go to Seller Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                backgroundImage: userPhotoUrl != null
                    ? NetworkImage(userPhotoUrl)
                    : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
                child: userPhotoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white70,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow("Gender", gender),
                    _buildInfoRow("Age", age),
                    _buildInfoRow("Phone", phoneNumber),
                    _buildInfoRow("Member Since", memberSince),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Favorites',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              favorites.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final item = favorites[index];
                        return _buildFavoriteItem(item);
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No favorites added yet.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'PixelFont',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: item['image'].isNotEmpty
                ? Image.network(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _placeholder(item['title']);
                    },
                  )
                : _placeholder(item['title']),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['title'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'PixelFont',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _placeholder(String title) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'PixelFont',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}