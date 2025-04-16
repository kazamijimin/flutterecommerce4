import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterecommerce4/main.dart';
import 'add_product.dart';
import 'dart:async';
import 'cart.dart';
import 'see_all_recommend.dart';
import 'profile.dart';
import 'settings.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details.dart';
import 'wishlist.dart'; // Import the ProductDetails screen

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // Define bannerImages here
  final List<String> bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_bannerController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= bannerImages.length) {
          // Reset to the first page without animation
          _bannerController.jumpToPage(0);
          _currentPage = 0;
        } else {
          // Animate to the next page
          _bannerController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
          _currentPage = nextPage;
        }
      }
    });
  }

  Future<int> getCartItemCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final snapshot = await cartRef.get();
    return snapshot.docs.length;
  }

  Future<int> getWishlistItemCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');

    final snapshot = await wishlistRef.get();
    return snapshot.docs.length;
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.home, "HOME", Colors.red),
            _buildBottomNavItem(Icons.category, "CATEGORY", Colors.white),
            if (user != null)
              _buildBottomNavItem(Icons.message, "MESSAGE", Colors.white),
            if (user != null)
              _buildBottomNavItem(Icons.shopping_bag, "SHOP", Colors.white),
            if (user != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
                child:
                    _buildBottomNavItem(Icons.person, "PROFILE", Colors.white),
              ),
            if (user == null)
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AuthenticationPage()),
                  );
                },
                child: _buildBottomNavItem(
                    Icons.login, "LOGIN/SIGN UP", Colors.red),
              ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                int itemCount = 0;
                if (snapshot.hasData) {
                  itemCount = snapshot.data!.docs.length;
                }
                return Stack(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartPage()),
                        );
                      },
                    ),
                    if (itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.person, color: Colors.white),
              onSelected: (String value) async {
                if (value == 'Settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                } else if (value == 'Logout') {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                final user = FirebaseAuth.instance.currentUser;
                return [
                  PopupMenuItem<String>(
                    value: 'Settings',
                    child: Row(
                      children: const [
                        Icon(Icons.settings, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user != null)
                    PopupMenuItem<String>(
                      value: 'Logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem("MENU", Icons.menu, true),
                if (user != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WishlistPage()),
                      );
                    },
                    child: Stack(
                      children: [
                        _buildNavItem("WISHLIST", Icons.favorite_border, false),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('wishlist')
                              .snapshots(),
                          builder: (context, snapshot) {
                            int itemCount = 0;
                            if (snapshot.hasData) {
                              itemCount = snapshot.data!.docs.length;
                            }
                            return itemCount > 0
                                ? Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                if (user != null)
                  _buildNavItem("WALLET", Icons.account_balance_wallet, false),
                if (user != null)
                  _buildNavItem("NOTIFICATION", Icons.notifications, false),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: bannerImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Image.asset(
                        bannerImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                "ANIME BANNER IMAGE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 2,
                      color: Colors.blue,
                      margin: const EdgeInsets.only(top: 4),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SeeAllProductsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset - 200,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.cyan),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        );
                      }

                      final products = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final productData =
                              product.data() as Map<String, dynamic>?;

                          return _buildProductCard(
                            productData?['imageUrl'] ?? '',
                            productData?['name'] ?? 'Unknown Product',
                            'PHP ${productData?['price'] ?? '0.00'}',
                            productData?['description'] ??
                                'No description available',
                            productData?['userId'] ??
                                'Unknown User', // Pass the userId
                          );
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 18),
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset + 200,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.cyan.shade700,
                    Colors.cyan.shade300,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GAMEBOX',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'SUMMER SALE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          backgroundColor: Colors.cyan,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProduct()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, [bool isSelected = false]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontFamily: 'PixelFont',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String title, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontFamily: 'PixelFont',
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(String imageUrl, String title, String price,
      String description, String userId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              imageUrl: imageUrl,
              title: title,
              price: price,
              description: description,
              userId: userId, // Pass the userId to the ProductDetails screen
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade900,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'PixelFont',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                price,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'PixelFont',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
