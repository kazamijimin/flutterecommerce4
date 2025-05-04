import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details.dart';

class CategoryPage extends StatefulWidget {
  final String? initialCategory;
  
  const CategoryPage({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<String> _allCategories = [
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
  ];

  // Pagination settings
  int _currentPage = 0;
  final int _categoriesPerPage = 5;
  String _selectedCategory = 'Games';

  // Show/hide categories toggle
  bool _showCategories = false;

  List<String> get _currentCategories {
    final startIndex = _currentPage * _categoriesPerPage;
    final endIndex = startIndex + _categoriesPerPage;

    if (startIndex >= _allCategories.length) {
      return [];
    }

    return _allCategories.sublist(startIndex,
        endIndex > _allCategories.length ? _allCategories.length : endIndex);
  }

  int get _totalPages => (_allCategories.length / _categoriesPerPage).ceil();

  void _nextPage() {
    setState(() {
      if (_currentPage < _totalPages - 1) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  void _toggleCategoriesVisibility() {
    setState(() {
      _showCategories = !_showCategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Category Selection with Pagination
          Container(
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Category selector header - always visible
                InkWell(
                  onTap: _toggleCategoriesVisibility,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.category,
                          color: Colors.cyan,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Category',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'PixelFont',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedCategory,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PixelFont',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showCategories
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.cyan,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories list - only visible when _showCategories is true
                if (_showCategories) ...[
                  const Divider(height: 1, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Select Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Page ${_currentPage + 1}/$_totalPages',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'PixelFont',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentCategories.length,
                    itemBuilder: (context, index) {
                      final category = _currentCategories[index];
                      return ListTile(
                        title: Text(
                          category,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 15,
                            fontWeight: _selectedCategory == category
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: _selectedCategory == category
                            ? const Icon(Icons.check_circle, color: Colors.cyan)
                            : null,
                        tileColor: _selectedCategory == category
                            ? Colors.cyan.withOpacity(0.1)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            // Optionally close the categories after selection
                            _showCategories = false;
                          });
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: _currentPage > 0
                                ? Colors.cyan
                                : Colors.grey[700],
                            size: 20,
                          ),
                          onPressed: _currentPage > 0 ? _previousPage : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: _currentPage < _totalPages - 1
                                ? Colors.cyan
                                : Colors.grey[700],
                            size: 20,
                          ),
                          onPressed:
                              _currentPage < _totalPages - 1 ? _nextPage : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  _selectedCategory,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData) {
                        count = snapshot.data!.docs.length;
                      }
                      return Text(
                        '$count items',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: _selectedCategory)
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            color: Colors.grey[600], size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found in this category',
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

                final products = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productData = product.data() as Map<String, dynamic>?;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetails(
                              productId: product.id,
                              imageUrl: productData?['imageUrl'] ?? '',
                              title: productData?['name'] ?? 'Unknown Product',
                              price:
                                  productData?['price']?.toString() ?? '0.00',
                              description: productData?['description'] ??
                                  'No description available',
                              stockCount: productData?['stockCount'] ?? 0,
                              userId: productData?['userId'] ?? 'Unknown User',
                              category: _selectedCategory,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(11)),
                                    child: Image.network(
                                      productData?['imageUrl'] ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade900,
                                          child: const Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                                size: 40),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Stock indicator
                                  if ((productData?['stockCount'] ?? 0) < 5)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Low Stock',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'PixelFont',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData?['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'PixelFont',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'PHP ${productData?['price'] ?? '0.00'}',
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'PixelFont',
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.cyan.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.cyan,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
