import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../product_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BecauseYouViewed extends StatefulWidget {
  final String? viewedProductId;
  final String? viewedProductName;
  final String? viewedProductCategory;

  const BecauseYouViewed({
    Key? key, 
    this.viewedProductId,
    this.viewedProductName,
    this.viewedProductCategory,
  }) : super(key: key);

  @override
  State<BecauseYouViewed> createState() => _BecauseYouViewedState();
}

class _BecauseYouViewedState extends State<BecauseYouViewed> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _suggestedProducts = [];
  String _lastViewedProductName = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Option 1: Use the provided product details if available
      if (widget.viewedProductCategory != null && widget.viewedProductName != null) {
        await _fetchRelatedProducts(
          widget.viewedProductCategory!,
          widget.viewedProductName!,
          widget.viewedProductId,
        );
        return;
      }

      // Option 2: If no product details provided, get from user's view history
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewed = prefs.getStringList('recentlyViewedProducts') ?? [];
      
      if (recentlyViewed.isNotEmpty) {
        // Get the most recently viewed product details
        final lastViewedProductId = recentlyViewed.first;
        
        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(lastViewedProductId)
              .get();
          
          if (productDoc.exists) {
            final data = productDoc.data()!;
            final category = data['category'] as String? ?? 'Games';
            final name = data['name'] as String? ?? 'Product';
            
            await _fetchRelatedProducts(category, name, lastViewedProductId);
          } else {
            setState(() {
              _isLoading = false;
              _suggestedProducts = [];
            });
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // If no viewed products, use default "trending" products
        await _fetchTrendingProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchRelatedProducts(String category, String productName, String? excludeProductId) async {
    try {
      // Store the product name for the section title
      _lastViewedProductName = productName;
      
      // Get products with the same category
      var query = FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .where('archived', isNotEqualTo: true)
          .limit(10);
      
      final querySnapshot = await query.get();
      
      if (mounted) {
        setState(() {
          _suggestedProducts = querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              })
              .where((product) => product['id'] != excludeProductId) // Exclude the current product
              .take(5) // Limit to 5 products
              .toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTrendingProducts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('archived', isNotEqualTo: true)
          .orderBy('soldCount', descending: true) // Use soldCount to determine trending
          .limit(5)
          .get();
      
      if (mounted) {
        setState(() {
          _suggestedProducts = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't display if we're loading or there are no recommendations
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }
    
    if (_suggestedProducts.isEmpty) {
      return const SizedBox(); // Return empty widget if no suggestions
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section divider
        Container(
          height: 8,
          color: Colors.grey.shade900,
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
        
        // Section header with pixelated title
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.viewedProductId == null ? 'TRENDING NOW' : 'BECAUSE YOU VIEWED',
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              if (widget.viewedProductId != null)
                Text(
                  _lastViewedProductName,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        
        // Products horizontal list
        SizedBox(
          height: 270,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedProducts.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final productData = _suggestedProducts[index];
              
              // Determine if product has a discount
              final bool hasDiscount = productData['discount'] == true;
              final int discountPercent = hasDiscount ? (productData['discountPercent'] ?? 20) : 0;
              
              // Calculate prices
              final String currentPrice = productData['price']?.toString() ?? '0.00';
              final double originalPriceValue = hasDiscount
                  ? double.parse(currentPrice) * (100 / (100 - discountPercent))
                  : double.parse(currentPrice);
              final String originalPrice = originalPriceValue.toStringAsFixed(2);
              
              return GestureDetector(
                onTap: () {
                  // Navigate to product details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(
                        imageUrl: productData['imageUrl'] ?? '',
                        title: productData['name'] ?? 'Unknown Product',
                        price: currentPrice,
                        description: productData['description'] ?? 'No description available',
                        sellerId: productData['sellerId'] ?? '',
                        productId: productData['id'],
                        category: productData['category'] ?? 'Games',
                      ),
                    ),
                  ).then((_) {
                    // Refresh recommendations when returning from product details
                    if (mounted) {
                      _loadRecommendations();
                    }
                  });
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade800),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            child: Image.network(
                              productData['imageUrl'] ?? '',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                          ),
                          
                          // Add to Cart Button
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: GestureDetector(
                              onTap: () async {
                                if (FirebaseAuth.instance.currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in to add items to cart'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                try {
                                  // Add to cart logic would go here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to add to cart'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          
                          // Discount badge
                          if (hasDiscount)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                          // Low stock indicator
                          if ((productData['stockCount'] ?? 0) < 5 && (productData['stockCount'] ?? 0) > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Low Stock',
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Product Details
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productData['name'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            
                            // Price section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Price column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasDiscount)
                                      Text(
                                        'PHP $originalPrice',
                                        style: TextStyle(
                                          fontFamily: 'PixelFont',
                                          color: Colors.grey,
                                          fontSize: 11,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      'PHP $currentPrice',
                                      style: TextStyle(
                                        fontFamily: 'PixelFont',
                                        color: hasDiscount 
                                            ? const Color.fromARGB(255, 212, 0, 0)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: hasDiscount ? 16 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Rating display
                                if (productData['rating'] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${(productData['rating'] ?? 0.0).toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            // Category tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                productData['category'] ?? 'Games',
                                style: const TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontSize: 10,
                                  color: Colors.cyan,
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
            },
          ),
        ),
      ],
    );
  }
}