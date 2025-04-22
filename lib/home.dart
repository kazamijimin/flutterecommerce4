import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // Search-related variables
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _suggestedProducts = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;
  
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
    _loadRecentSearches();
    
    // Listen for search focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    
    // Listen for search text changes
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many Firebase queries
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _getSuggestedProducts(_searchController.text);
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String search) async {
    if (search.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recentSearches') ?? [];
    
    // Remove duplicates and add to the beginning
    searches.remove(search);
    searches.insert(0, search);
    
    // Limit to 5 recent searches
    final limitedSearches = searches.take(5).toList();
    
    await prefs.setStringList('recentSearches', limitedSearches);
    
    setState(() {
      _recentSearches = limitedSearches;
    });
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentSearches');
    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _getSuggestedProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestedProducts = [];
      });
      return;
    }
    
    setState(() {
      _isLoadingSuggestions = true;
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();
      
      if (mounted) {
        setState(() {
          _suggestedProducts = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Save the search query to recent searches
    _saveRecentSearch(query);
    
    // Clear focus to hide suggestions
    _searchFocusNode.unfocus();
    
    // Navigate to a dedicated search results page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(searchQuery: query),
      ),
    );
  }

  // Fetch products in advance to avoid loading during scrolling
 Future<void> _fetchProducts() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('archived', isNotEqualTo: true)  // Only fetch non-archived products
        .limit(10)
        .get();
    
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
    _debounceTimer?.cancel();
    _pageController.dispose();
    _productScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: pixelFontStyle(),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: pixelFontStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestedProducts = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (value) {
                      _executeSearch(value);
                    },
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
            // Search suggestions overlay
            if (_isSearchFocused)
              Container(
                color: Colors.black,
                width: double.infinity,
                child: _buildSearchSuggestions(),
              ),
            if (!_isSearchFocused)
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
            if (!_isSearchFocused)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh product data
                    await _fetchProducts();
                    // Optionally refresh other data like cart/wishlist counts
                    await _loadCounts();
                  },
                  color: Colors.cyan,
                  backgroundColor: Colors.grey.shade900,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // This is important for RefreshIndicator to work
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
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
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

  Widget _buildSearchSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggested products based on search query
          if (_suggestedProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SUGGESTED PRODUCTS',
                style: pixelFontStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            for (var product in _suggestedProducts)
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    product['imageUrl'] ?? '',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.error, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                title: Text(
                  product['name'] ?? 'Unknown',
                  style: pixelFontStyle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'PHP ${product['price'] ?? '0.00'}',
                  style: pixelFontStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                onTap: () {
                  // Navigate to product details and save search
                  _searchFocusNode.unfocus();
                  _saveRecentSearch(product['name']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(
                        imageUrl: product['imageUrl'] ?? '',
                        title: product['name'] ?? 'Unknown Product',
                        price: 'PHP ${product['price'] ?? '0.00'}',
                        description: product['description'] ?? 'No description available',
                        userId: product['userId'] ?? 'Unknown User',
                        productId: product['id'],
                      ),
                    ),
                  );
                },
              ),
          ],
          
          // Recent searches section
          if (_recentSearches.isNotEmpty && _suggestedProducts.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT SEARCHES',
                    style: pixelFontStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecentSearches,
                    child: Text(
                      'Clear',
                      style: pixelFontStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            for (var search in _recentSearches)
              ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  search,
                  style: pixelFontStyle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _searchController.text = search;
                  _executeSearch(search);
                },
              ),
          ],
          
          // Loading indicator for suggestions
          if (_isLoadingSuggestions)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          
          // No results message
          if (_searchController.text.isNotEmpty && 
              _suggestedProducts.isEmpty && 
              !_isLoadingSuggestions)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No products found',
                  style: pixelFontStyle(color: Colors.grey),
                ),
              ),
            ),
            
          const SizedBox(height: 8),
        ],
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
                    style: pixelFontStyle(color: const Color.fromARGB(255, 212, 0, 0)),
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

// Add this class at the bottom of your home.dart file or create a new search_results.dart file

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  
  const SearchResultsPage({Key? key, required this.searchQuery}) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      List<Map<String, dynamic>> results = [];
      final searchTerm = widget.searchQuery.toLowerCase();
      
      // First try direct query for performance
      var querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: widget.searchQuery)
          .where('archived', isNotEqualTo: true)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        // Add exact matches
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          results.add(data);
        }
      }
      
      // Try prefix match
      querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: widget.searchQuery)
          .where('name', isLessThanOrEqualTo: widget.searchQuery + '\uf8ff')
          .where('archived', isNotEqualTo: true)
          .get();
          
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Avoid duplicates from the first query
        if (!results.any((item) => item['id'] == doc.id)) {
          results.add(data);
        }
      }
      
      // If still no results, try a more general search
      if (results.isEmpty) {
        // Get all products and filter locally
        querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('archived', isNotEqualTo: true)
            .get();
            
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          
          if (name.contains(searchTerm) || description.contains(searchTerm)) {
            data['id'] = doc.id;
            results.add(data);
          }
        }
      }
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching products: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'SEARCH: ${widget.searchQuery}',
          style: pixelFontStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading search results',
                        style: pixelFontStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _performSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        child: Text(
                          'Try Again',
                          style: pixelFontStyle(),
                        ),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No products found for "${widget.searchQuery}"',
                            style: pixelFontStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return _buildProductCard(product);
                      },
                    ),
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              imageUrl: product['imageUrl'] ?? '',
              title: product['name'] ?? 'Unknown Product',
              price: 'PHP ${product['price'] ?? '0.00'}',
              description: product['description'] ?? 'No description available',
              userId: product['userId'] ?? 'Unknown User',
              productId: product['id'],
            ),
          ),
        );
      },
      child: Card(
        color: Colors.grey.shade900,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                product['imageUrl'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: pixelFontStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PHP ${product['price'] ?? '0.00'}',
                    style: pixelFontStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Stock indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (product['stockCount'] ?? 0) > 0 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (product['stockCount'] ?? 0) > 0 ? 'In Stock' : 'Out of Stock',
                      style: pixelFontStyle(
                        fontSize: 10,
                        color: (product['stockCount'] ?? 0) > 0 ? Colors.green : Colors.red,
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