import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart.dart';
import 'wishlist.dart';
import 'category.dart';
import 'product_details.dart';
import 'profile.dart';
import 'settings.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  int _currentNavIndex = 0;
  Timer? _timer;
  final PageController _pageController = PageController();
  final ScrollController _productScrollController = ScrollController();
  int cartCount = 0;
  int wishlistCount = 0;
  
  // Preload product data
  List<Map<String, dynamic>> products = [];
  bool isProductsLoading = true;

  // Text style with pixel font
  TextStyle pixelFontStyle({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontFamily: 'PixelFont',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _startAutoScroll();
    _loadCounts();
  }

  // Fetch products in advance to avoid loading during scrolling
  Future<void> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').limit(10).get();
      
      if (mounted) {
        setState(() {
          products = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          isProductsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProductsLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < 2) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _loadCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load cart count
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      // Load wishlist count
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          cartCount = cartSnapshot.docs.length;
          wishlistCount = wishlistSnapshot.docs.length;
        });
      }
    }
  }

  void _scrollProducts(bool scrollLeft) {
    if (_productScrollController.hasClients) {
      final currentPosition = _productScrollController.offset;
      final scrollAmount = 130.0; // Width of product card + margin
      
      _productScrollController.animateTo(
        scrollLeft ? 
          (currentPosition - scrollAmount).clamp(0, _productScrollController.position.maxScrollExtent) : 
          (currentPosition + scrollAmount).clamp(0, _productScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _productScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Preload banner images to avoid flickering
    precacheImage(const AssetImage('assets/images/banner1.jpg'), context);
    precacheImage(const AssetImage('assets/images/banner2.jpg'), context);
    precacheImage(const AssetImage('assets/images/banner3.jpg'), context);
    
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'PixelFont',
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false, // Removes the back button

          title: Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      _navigateWithBottomBar(context, const CartPage(), 3);
                    },
                    iconSize: 28,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: pixelFontStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    style: pixelFontStyle(),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: pixelFontStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage()));
                    },
                  ),
                  if (wishlistCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$wishlistCount',
                          style: pixelFontStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _topNavButton('MENU', Icons.menu),
                  _topNavButton('WISHLIST', Icons.favorite_border),
                  _topNavButton('WALLET', Icons.account_balance_wallet),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Carousel - Using PageView with preloaded images
                    SizedBox(
                      height: 200,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          Image.asset('assets/images/banner1.jpg', fit: BoxFit.cover),
                          Image.asset('assets/images/banner2.jpg', fit: BoxFit.cover),
                          Image.asset('assets/images/banner3.jpg', fit: BoxFit.cover),
                        ],
                      ),
                    ),
                    // Carousel Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) => _buildDot(index)),
                      ),
                    ),
                    // Recommended Products with Navigation Arrows
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECOMMENDED',
                            style: pixelFontStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Left arrow
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.cyan, size: 20),
                                onPressed: () => _scrollProducts(true),
                              ),
                              // Right arrow
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, color: Colors.cyan, size: 20),
                                onPressed: () => _scrollProducts(false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildProductGrid(),
                    
                    // GameBox Summer Sale Banner
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      color: Colors.blue.shade900,
                      child: Center(
                        child: Text(
                          'GAMEBOX SUMMER SALE',
                          style: pixelFontStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
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
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.cyan,
          unselectedItemColor: Colors.white,
          selectedLabelStyle: pixelFontStyle(fontSize: 12),
          unselectedLabelStyle: pixelFontStyle(fontSize: 12),
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
            switch (index) {
              case 0: // Home - already here
                break;
              case 1: // Category
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryPage()));
                break;
              case 2: // Message
                _showMessageDialog();
                break;
              case 3: // Shop
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
                break;
              case 4: // Profile
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _topNavButton(String title, IconData icon) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        title, 
        style: pixelFontStyle(fontSize: 12),
      ),
      onPressed: () {
        if (title == 'WISHLIST') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistPage()));
        } else if (title == 'WALLET') {
          // Navigate to wallet
        } else if (title == 'MENU') {
          _showMenuDialog();
        }
      },
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.cyan : Colors.grey,
      ),
    );
  }
void _showMenuDialog() {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.pink.shade800, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'MENU',
                style: pixelFontStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Library',
                  style: pixelFontStyle(
                    fontSize: 16,
                    color: Colors.pink.shade300,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                // Navigate to login screen
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Your store',
                  style: pixelFontStyle(
                    fontSize: 16,
                    color: Colors.pink.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
  void _showMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Messages', style: pixelFontStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('No new messages', style: pixelFontStyle()),
        actions: [
          TextButton(
            child: Text('Close', style: pixelFontStyle(color: Colors.cyan)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    // Use pre-fetched products instead of stream
    if (isProductsLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (products.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text('No products available', style: pixelFontStyle())),
      );
    }
    
    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _productScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final productData = products[index];
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetails(
                    imageUrl: productData['imageUrl'] ?? '',
                    title: productData['name'] ?? 'Unknown Product',
                    price: 'PHP ${productData['price'] ?? '0.00'}',
                    description: productData['description'] ?? 'No description available',
                    userId: productData['userId'] ?? 'Unknown User',
                    productId: productData['id'],
                  ),
                ),
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      productData['imageUrl'] ?? '',
                      height: 140,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        width: 120,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productData['name'] ?? 'Unknown Product',
                    style: pixelFontStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'PHP ${productData['price'] ?? '0.00'}',
                    style: pixelFontStyle(color: Colors.cyan),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateWithBottomBar(BuildContext context, Widget page, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) {
      setState(() {
        _currentNavIndex = index;
      });
    });
  }
}