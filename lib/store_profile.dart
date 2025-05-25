import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'message.dart';

class StoreProfile extends StatefulWidget {
  final String sellerId;
  final String storeName;

  const StoreProfile({
    Key? key,
    required this.sellerId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<StoreProfile> createState() => _StoreProfileState();
}

class _StoreProfileState extends State<StoreProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _storeProducts = [];
  bool _isLoading = true;
  int _stalkerCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
    _fetchStoreProducts();
  }

  Future<void> _fetchStoreData() async {
    try {
      final storeDoc =
          await _firestore.collection('users').doc(widget.sellerId).get();

      if (storeDoc.exists) {
        setState(() {
          _storeData = storeDoc.data();
          _stalkerCount = _storeData?['stalkerCount'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching store data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStoreProducts() async {
    setState(() => _isLoading = true);

    try {
      print('Fetching products for seller ID: ${widget.sellerId}');

      // Query products by the seller ID with proper field name
      final productsQuery = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .get();

      if (productsQuery.docs.isEmpty) {
        print('No products found for seller: ${widget.sellerId}');
      } else {
        print(
            'Found ${productsQuery.docs.length} products for seller: ${widget.sellerId}');

        // Debug information to help troubleshoot
        for (var doc in productsQuery.docs) {
          print(
              'Product: ${doc.id} - ${doc.data()['title']} - SellerId: ${doc.data()['sellerId']}');
        }
      }

      setState(() {
        _storeProducts = productsQuery.docs.map((doc) {
          final data = doc.data();
          // Make sure we're mapping the correct field names from Firestore
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Product',
            'price': data['price'] ?? 0.0,
            'imageUrl': data['imageUrl'] ?? '',
            'rating': data['rating'] ?? 0.0,
            'createdAt': data['createdAt'],
            'description': data['description'] ?? '',
            'category': data['category'] ?? 'Uncategorized',
            'sellerId': data['sellerId'] ?? '',
            'sold': data['sold'] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching store products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purple.withOpacity(0.8),
                      Colors.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[900],
                          backgroundImage: _storeData?['photoURL'] != null
                              ? CachedNetworkImageProvider(
                                  _storeData!['photoURL'])
                              : null,
                          child: _storeData?['photoURL'] == null
                              ? const Icon(Icons.store,
                                  color: Colors.white, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        _storeProducts.length.toString(),
                        'Products',
                        Icons.shopping_bag,
                        Colors.cyan,
                      ),
                      _buildStatItem(
                        _stalkerCount.toString(),
                        'Stalkers',
                        Icons.visibility,
                        Colors.purple,
                      ),
                      _buildStatItem(
                        _storeData?['totalSales']?.toString() ?? '0',
                        'Sales',
                        Icons.sell,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      'CHAT WITH STORE',
                      style: TextStyle(fontFamily: 'PixelFont'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => startStoreChat(
                      context,
                      widget.sellerId,
                      widget.storeName,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'STORE PRODUCTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProductsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PixelFont',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_storeProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No products in this store',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This seller hasn\'t added any products yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'PixelFont',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text(
                'REFRESH',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _fetchStoreProducts,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _storeProducts.length,
      itemBuilder: (context, index) {
        final product = _storeProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product detail page
        Navigator.pushNamed(context, '/product',
            arguments: {'productId': product['id']});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with loading indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: CachedNetworkImage(
                    imageUrl: product['imageUrl'] ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: Colors.grey[850],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported,
                              color: Colors.white60),
                          const SizedBox(height: 4),
                          Text(
                            product['name'] ?? 'Product',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontFamily: 'PixelFont',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category badge
                if (product['category'] != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price with PHP symbol
                  Text(
                    '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating and sales info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(
                            ' ${(product['rating'] ?? 0.0).toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${product['sold'] ?? 0} sold',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontFamily: 'PixelFont',
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
  }
}
