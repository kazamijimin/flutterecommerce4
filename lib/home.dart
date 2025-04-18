import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterecommerce4/authentication_page.dart';
import 'add_product.dart';
import 'dart:async';
import 'cart.dart';
import 'see_all_recommend.dart';
import 'profile.dart';
import 'settings.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details.dart';
import 'wishlist.dart';
import 'category.dart';

// New SearchPage class to handle search functionality
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 10000);
  List<String> _recentSearches = [];
  List<String> _suggestedProducts = [];
  bool _showFilters = false;

  // These would normally be fetched from Firebase
  final List<String> _categories = [
    'All',
    'Games',
    'Consoles',
    'Accessories',
    'Collectibles'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadSuggestedProducts();
  }

  void _loadRecentSearches() async {
    // In a real app, you could load this from shared preferences or Firebase
    setState(() {
      _recentSearches = [
        'Pokemon',
        'Nintendo Switch',
        'PS5',
        'Gaming Keyboard'
      ];
    });
  }

  void _loadSuggestedProducts() async {
    // Normally we'd query Firestore for popular products
    setState(() {
      _suggestedProducts = [
        'Final Fantasy XVI',
        'DualSense Controller',
        'Xbox Series X'
      ];
    });
  }

  void _saveSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      // Remove if already exists and add to front
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);

      // Keep only the last 5 searches
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle:
                const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: Colors.cyan,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: (value) {
            _saveSearch(value);
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildSuggestions()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTER BY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Category:',
                style:
                    TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'PixelFont'),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Price Range:',
            style: TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            max: 10000,
            divisions: 20,
            activeColor: Colors.cyan,
            inactiveColor: Colors.grey,
            labels: RangeLabels(
              'PHP ${_priceRange.start.round().toString()}',
              'PHP ${_priceRange.end.round().toString()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHP ${_priceRange.start.round()}',
                style: const TextStyle(
                    color: Colors.white70, fontFamily: 'PixelFont'),
              ),
              Text(
                'PHP ${_priceRange.end.round()}',
                style: const TextStyle(
                    color: Colors.white70, fontFamily: 'PixelFont'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Apply filters
              },
              child: const Text(
                'APPLY FILTERS',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'RECENT SEARCHES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((search) => GestureDetector(
                        onTap: () {
                          _searchController.text = search;
                          setState(() {
                            _searchQuery = search;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                search,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PixelFont'),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'SUGGESTED FOR YOU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 16),

          // Using StreamBuilder to get suggested products from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .limit(6)
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
                    'No suggestions available',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                );
              }

              final products = snapshot.data!.docs;

 return GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: products.length, // Use 'products' instead of 'filteredProducts'
  itemBuilder: (context, index) {
    final product = products[index];
    final productData = product.data() as Map<String, dynamic>?;

    return _buildProductItem(
      productData?['imageUrl'] ?? '',
      productData?['name'] ?? 'Unknown Product',
      'PHP ${productData?['price'] ?? '0.00'}',
      productData?['description'] ?? 'No description available',
      productData?['userId'] ?? 'Unknown User',
      product.id, // Pass the Firestore document ID
    );
  },
);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyan),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$_searchQuery"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        // Apply price filter
        final filteredProducts = products.where((product) {
          final productData = product.data() as Map<String, dynamic>?;
          final price =
              double.tryParse(productData?['price'].toString() ?? '0') ?? 0;

          bool matchesPrice =
              price >= _priceRange.start && price <= _priceRange.end;

          bool matchesCategory = _selectedCategory == 'All' ||
              productData?['category'] == _selectedCategory;

          return matchesPrice && matchesCategory;
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.filter_alt_off,
                    color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No results match your filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

 return GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: products.length,
  itemBuilder: (context, index) {
    final product = products[index];
    final productData = product.data() as Map<String, dynamic>?;

    return _buildProductItem(
      productData?['imageUrl'] ?? '',
      productData?['name'] ?? 'Unknown Product',
      'PHP ${productData?['price'] ?? '0.00'}',
      productData?['description'] ?? 'No description available',
      productData?['userId'] ?? 'Unknown User',
      product.id, // Pass the Firestore document ID as the sixth argument
    );
  },
);
      },
    );
  }

  Widget _buildProductItem(String imageUrl, String title, String price,
      String description, String userId, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              productId: productId,
              imageUrl: imageUrl,
              title: title,
              price: price,
              description: description,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryPage()),
                );
              },
              child:
                  _buildBottomNavItem(Icons.category, "CATEGORY", Colors.white),
            ),
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
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Search products...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SearchPage()),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
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
                            productData?['userId'] ?? 'Unknown User',
                            product
                                .id, // Pass the Firestore document ID as the sixth argument
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
      String description, String userId, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              productId: productId,
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
