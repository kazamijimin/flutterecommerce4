import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart.dart';
import 'wishlist.dart';
import 'product_details.dart';
import 'services/message_service.dart';
import 'category.dart';
import 'home.dart';
import 'message.dart';
import 'profile.dart';
import 'dart:math'; // <-- Add this import at the top
class ShopPage extends StatefulWidget {
  final String? initialCategory;
  
  const ShopPage({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  // Color scheme matching library page
  static const mainColor = Color(0xFFFF0077);
  static const bgColor = Color(0xFF1A1A2E);
  static const borderColor = Color(0xFF333355);
  
  // Responsive breakpoints
  bool get isDesktop => MediaQuery.of(context).size.width >= 1200;
  bool get isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool get isMobile => MediaQuery.of(context).size.width < 600;

  // Dynamic measurements
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get itemWidth => isDesktop ? 280 : isTablet ? 220 : 160;
  double get gridSpacing => screenWidth * 0.02;

  // Calculate grid columns based on screen size
  int get gridColumns {
    final availableWidth = screenWidth - (gridSpacing * 2);
    return max(1, availableWidth ~/ (itemWidth + gridSpacing));
  }

  late TabController _tabController;
  bool isLoading = true;
  List<String> categories = [
    'All', 
    'Random Picks', 
    'Games',
    'Consoles',
    'Accessories',
    'Collectibles',
    'Action RPG',
    'Turn Based RPG',
    'Visual Novel',
    'Horror',
    'Souls Like',
    'Rogue Like',
    'Puzzle',
    'Open World',
    'MMORPG',
    'Sports',
    'Casual',
    'Slice of Life',
    'Farming Simulator',
    'Card Game',
    'Gacha',
    'Shooting',
    'Merchandise', 
    'Sale'
  ];
  String selectedCategory = 'All';
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  
  // Sort and filter options
  String _sortOption = 'Popular';
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minRating = 0;
  bool _showFilterDialog = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Pagination
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _productsPerPage = 10;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _remainingProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    
    // Set initial category if provided
    if (widget.initialCategory != null) {
      final index = categories.indexOf(widget.initialCategory!);
      if (index != -1) {
        _tabController.index = index;
        selectedCategory = widget.initialCategory!;
      }
    }
    
    _fetchProducts();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    
    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedCategory = categories[_tabController.index];
          _applyFilters();
        });
      }
    });
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMoreProducts && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  // Update the _fetchProducts method to randomize product order
  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // First get all products (with a reasonable limit)
      var query = FirebaseFirestore.instance
          .collection('products')
          .where('archived', isNotEqualTo: true)
          .limit(50); // Increase limit for better randomization
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          products = [];
          filteredProducts = [];
          isLoading = false;
          _hasMoreProducts = false;
        });
        return;
      }
      
      // Convert to list and shuffle
      final fetchedProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Randomize the list
      fetchedProducts.shuffle();
      
      // Take only the first _productsPerPage items
      final randomizedProducts = fetchedProducts.take(_productsPerPage).toList();
      
      // Store the rest for pagination if needed
      _remainingProducts = fetchedProducts.skip(_productsPerPage).toList();
      
      setState(() {
        products = randomizedProducts;
        _applyFilters();
        isLoading = false;
        _hasMoreProducts = _remainingProducts.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      MessageService.showGameMessage(
        context,
        message: 'Failed to load products: $e',
        isSuccess: false,
      );
    }
  }
  
  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      var query = FirebaseFirestore.instance
          .collection('products')
          .where('archived', isNotEqualTo: true)
          .orderBy('soldCount', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_productsPerPage);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreProducts = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      _lastDocument = snapshot.docs.last;
      
      final fetchedProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      setState(() {
        products.addAll(fetchedProducts);
        _applyFilters();
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      MessageService.showGameMessage(
        context,
        message: 'Failed to load more products',
        isSuccess: false,
      );
    }
  }
  
  void _applyFilters() {
    // Filter by category
    var filtered = List<Map<String, dynamic>>.from(products);
    
    if (selectedCategory == 'Random Picks') {
      // For Random Picks, shuffle and take first 10 products
      filtered.shuffle();
      filtered = filtered.take(10).toList();
    } else if (selectedCategory != 'All') {
      filtered = filtered.where((product) => 
        product['category'] == selectedCategory).toList();
    }
    
    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        return name.contains(searchTerm) || description.contains(searchTerm);
      }).toList();
    }
    
    // Filter by price range
    filtered = filtered.where((product) {
      final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();
    
    // Filter by rating
    filtered = filtered.where((product) {
      final rating = (product['rating'] ?? 0.0) as num;
      return rating >= _minRating;
    }).toList();
    
    // Apply sorting
    switch (_sortOption) {
      case 'Price: High to Low':
        filtered.sort((a, b) => 
          double.parse(b['price'].toString()).compareTo(double.parse(a['price'].toString())));
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) => 
          double.parse(a['price'].toString()).compareTo(double.parse(b['price'].toString())));
        break;
      case 'Rating':
        filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'Newest':
        filtered.sort((a, b) => 
          (b['createdAt'] ?? Timestamp.now()).compareTo(a['createdAt'] ?? Timestamp.now()));
        break;
      case 'Popular':
      default:
        filtered.sort((a, b) => (b['soldCount'] ?? 0).compareTo(a['soldCount'] ?? 0));
        break;
    }
    
    setState(() {
      filteredProducts = filtered;
    });
  }
  
  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              // Title
              const Center(
                child: Text(
                  'FILTER & SORT',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Colors.grey, height: 24),
              
              // Sort Options
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Popular', setModalState),
                  _buildSortChip('Price: High to Low', setModalState),
                  _buildSortChip('Price: Low to High', setModalState),
                  _buildSortChip('Rating', setModalState),
                  _buildSortChip('Newest', setModalState),
                ],
              ),
              const SizedBox(height: 16),
              
              // Price Range
              const Text(
                'PRICE RANGE',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PHP ${_priceRange.start.toInt()}',
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'PHP ${_priceRange.end.toInt()}',
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 10000,
                divisions: 100,
                activeColor: Colors.cyan,
                inactiveColor: Colors.grey,
                labels: RangeLabels(
                  'PHP ${_priceRange.start.toStringAsFixed(0)}',
                  'PHP ${_priceRange.end.toStringAsFixed(0)}',
                ),
                onChanged: (RangeValues values) {
                  setModalState(() {
                    _priceRange = values;
                  });
                },
              ),
              
              // Minimum Rating
              const SizedBox(height: 16),
              const Text(
                'MINIMUM RATING',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      activeColor: Colors.cyan,
                      inactiveColor: Colors.grey,
                      label: _minRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setModalState(() {
                          _minRating = value;
                        });
                      },
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _minRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Apply/Reset Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Reset filters
                      setModalState(() {
                        _priceRange = const RangeValues(0, 10000);
                        _minRating = 0;
                        _sortOption = 'Popular';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'RESET',
                      style: TextStyle(fontFamily: 'PixelFont'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Apply filters and close sheet
                      setState(() {
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'APPLY',
                      style: TextStyle(fontFamily: 'PixelFont', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSortChip(String label, StateSetter setModalState) {
    return FilterChip(
      selected: _sortOption == label,
      label: Text(
        label,
        style: TextStyle(
          color: _sortOption == label ? Colors.black : Colors.white,
          fontFamily: 'PixelFont',
          fontSize: 12,
        ),
      ),
      selectedColor: Colors.cyan,
      backgroundColor: Colors.grey.shade800,
      onSelected: (bool selected) {
        if (selected) {
          setModalState(() {
            _sortOption = label;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Update the build method to use a more responsive layout that prevents overflow
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'GAMEBOX SHOP',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        actions: _buildAppBarActions(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryBar(),
            _buildFilterBar(),
            Expanded(
              child: _buildProductGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade900,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                visualDensity: VisualDensity.compact,
                selected: selectedCategory == category,
                label: Text(
                  category,
                  style: TextStyle(
                    color: selectedCategory == category ? Colors.black : Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                  ),
                ),
                selectedColor: Colors.cyan,
                backgroundColor: Colors.grey.shade800,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      selectedCategory = category;
                      // Find the index of the selected category and update tab controller
                      final index = categories.indexOf(category);
                      if (index != -1) {
                        _tabController.animateTo(index);
                      }
                      _applyFilters();
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 8),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Results count
          Text(
            '${filteredProducts.length} Products',
            style: const TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shuffle button
              IconButton(
                icon: const Icon(Icons.shuffle, color: Colors.pink, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Shuffle',
                onPressed: () {
                  setState(() {
                    products.shuffle();
                    _applyFilters();
                  });
                  
                  MessageService.showGameMessage(
                    context,
                    message: 'Products shuffled!',
                    isSuccess: true,
                  );
                },
              ),
              
              // Filter button
              ElevatedButton(
                onPressed: _showFiltersBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'FILTER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : filteredProducts.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _fetchProducts,
                color: Colors.cyan,
                backgroundColor: Colors.grey.shade900,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    childAspectRatio: isDesktop ? 0.8 : 0.65,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                  ),
                  itemCount: _hasMoreProducts
                      ? filteredProducts.length + 1
                      : filteredProducts.length,
                  itemBuilder: (context, index) {
                    if (index >= filteredProducts.length) {
                      return _isLoadingMore
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    return _buildProductCard(
                      filteredProducts[index],
                      isTablet: isTablet,
                      isDesktop: isDesktop,
                    );
                  },
                ),
              );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No products found for "${_searchController.text}"'
                : 'No products found in $selectedCategory',
            style: const TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _tabController.index = 0;
                selectedCategory = 'All';
                _applyFilters();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'VIEW ALL PRODUCTS',
              style: TextStyle(fontFamily: 'PixelFont', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductCard(
    Map<String, dynamic> product, {
    required bool isTablet,
    required bool isDesktop,
  }) {
    final bool hasDiscount = product['discount'] == true;
    final int discountPercent = hasDiscount ? (product['discountPercent'] ?? 0) : 0;
    final double originalPrice = double.parse(product['price']?.toString() ?? '0');
    final double discountedPrice = hasDiscount ? originalPrice * (1 - discountPercent / 100) : originalPrice;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetails(
                  productId: product['id'],
                  imageUrl: product['imageUrl'] ?? '',
                  title: product['name'] ?? '',
                  price: discountedPrice.toString(),
                  description: product['description'] ?? '',
                  sellerId: product['sellerId'] ?? '',
                  category: product['category'] ?? '',
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        product['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image_not_supported, color: Colors.white),
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: mainColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Product Details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          product['name'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // Price
                        if (hasDiscount) ...[
                          Text(
                            'PHP ${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: isDesktop ? 14 : 12,
                              decoration: TextDecoration.lineThrough,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                        ],
                        Text(
                          'PHP ${discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: hasDiscount ? mainColor : Colors.white,
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont',
                          ),
                        ),

                        const Spacer(),

                        // Rating and Sold Count
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${(product['rating'] ?? 0).toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: isDesktop ? 14 : 12,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${product['soldCount'] ?? 0} sold',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: isDesktop ? 14 : 12,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white, size: 20), 
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildSearchDialog(),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WishlistPage()),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        },
      ),
      const SizedBox(width: 4), // Add small padding at the end
    ];
  }

  Widget _buildSearchDialog() {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        'SEARCH PRODUCTS',
        style: TextStyle(
          fontFamily: 'PixelFont',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(
          fontFamily: 'PixelFont',
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Enter product name...',
          hintStyle: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.grey.shade400,
          ),
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.cyan),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _searchController.clear();
            Navigator.pop(context);
            _applyFilters();
          },
          child: const Text(
            'CANCEL',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _applyFilters();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'SEARCH',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFFFF0077),
      unselectedItemColor: Colors.white,
      currentIndex: 3, // Shop is the 4th item (index 3)
      onTap: (index) {
        Widget page;
        switch (index) {
          case 0:
            page = const HomePage();
            break;
          case 1:
            page = const CategoryPage();
            break;
          case 2:
            page = const ChatPage();
            break;
          case 3:
            page = const ShopPage();
            break;
          case 4:
            page = const ProfileScreen();
            break;
          default:
            page = const HomePage();
        }
        if (index != 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          tooltip: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Category',
          tooltip: 'Category',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Message',
          tooltip: 'Message',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shop),
          label: 'Shop',
          tooltip: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
          tooltip: 'Profile',
        ),
      ],
      selectedLabelStyle: TextStyle(
        fontFamily: 'PixelFont',
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'PixelFont',
        fontSize: 12,
      ),
    );
  }
}

// Product Service class to handle firestore operations
class ShopProductService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add to cart functionality
  Future<void> addToCart(
    String productName,
    String imageUrl,
    String price,
    int quantity,
    String sellerId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Check if product already in cart
    final existingCartItem = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: user.uid)
        .where('productName', isEqualTo: productName)
        .get();

    if (existingCartItem.docs.isNotEmpty) {
      // Update quantity
      final docId = existingCartItem.docs.first.id;
      final currentQuantity = existingCartItem.docs.first.data()['quantity'] as int;
      
      await _firestore.collection('carts').doc(docId).update({
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Add new cart item
      await _firestore.collection('carts').add({
        'userId': user.uid,
        'productName': productName,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Add to wishlist functionality
  Future<void> toggleWishlist(
    String productId,
    String productName,
    String imageUrl,
    String price,
    String sellerId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Check if product already in wishlist
    final existingWishlistItem = await _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productId)
        .get();

    if (existingWishlistItem.docs.isNotEmpty) {
      // Remove from wishlist
      final docId = existingWishlistItem.docs.first.id;
      await _firestore.collection('wishlists').doc(docId).delete();
      return;
    } 

    // Add to wishlist
    await _firestore.collection('wishlists').add({
      'userId': user.uid,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'sellerId': sellerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}