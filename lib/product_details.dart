import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterecommerce4/checkout.dart';

class ProductDetails extends StatefulWidget {
  final String productId; // Firestore document ID
  final String imageUrl;
  final String title;
  final String price;
  final String description;
  final double rating;
  final int stockCount;
  final String userId;
  final String category;

  const ProductDetails({
    Key? key,
    required this.productId, // Pass the Firestore document ID
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
    this.rating = 4.9,
    this.stockCount = 41,
    required this.userId,
    this.category = "RPG",
  }) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 5.0;
  bool _isInWishlist = false;
  bool _isInFavorites = false; // Add this flag to track if user can add review
  List<Review> _reviews = [];
  int quantity = 1;
  String addedByUserName = "Loading...";
  String? addedByUserAvatar;
  bool _canAddReview = false; // Add this flag to track if user can add review
  double _averageRating = 0.0;
  int _reviewCount = 0;
  int _actualStockCount = 0;
  int _totalSold = 0;

  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
    _checkIfInFavorites(); // Add this new method call
    _fetchReviews();
    _fetchAddedByUserInfo();
    _checkIfCanAddReview();
    _loadProductDetails(); // Add this new method call
  }

  Future<void> _buyNow() async {
    if (widget.stockCount > 0) {
      try {
        // Clean the price string to ensure it's a valid double
        final cleanedPrice = widget.price.replaceAll(RegExp(r'[^\d.]'), '');
        final totalPrice = double.parse(cleanedPrice) * quantity;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPage(
              totalPrice: totalPrice,
              selectedItems: [
                {
                  'productId': widget.productId,
                  'title': widget.title,
                  'imageUrl': widget.imageUrl,
                  'price': widget.price,
                  'quantity': quantity,
                },
              ],
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Out of Stock!',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Updated method to check if user has completed order for this product
  Future<void> _checkIfCanAddReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _canAddReview = false;
      });
      return;
    }

    try {
      // Check user's orders collection (in users/{uid}/orders)
      final userOrdersQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('status', isEqualTo: 'delivered') // Changed from 'completed'
          .get();

      if (userOrdersQuery.docs.isNotEmpty) {
        // Look through user's orders first
        for (var orderDoc in userOrdersQuery.docs) {
          final orderData = orderDoc.data();
          final items = orderData['items'] as List<dynamic>? ?? [];

          for (var item in items) {
            if (item['title'] == widget.title) {
              setState(() {
                _canAddReview = true;
              });
              return; // Found a match in user's orders
            }
          }
        }
      }

      // If not found in user's orders, check main orders collection
      final mainOrdersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      for (var orderDoc in mainOrdersQuery.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          if (item['title'] == widget.title) {
            setState(() {
              _canAddReview = true;
            });
            return; // Found a match in main orders
          }
        }
      }

      // If we get here, no matching completed order was found
      setState(() {
        _canAddReview = false;
      });
    } catch (e) {
      print("Error checking if user can add review: $e");
      setState(() {
        _canAddReview = false;
      });
    }
  }

  // Update your _submitReview method
  void _submitReview() async {
    // First check if user can add review
    if (!_canAddReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only review products from completed orders.',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please write a review before submitting.',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final review = Review(
        username: FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        comment: _reviewController.text.trim(),
        rating: _userRating,
        avatarUrl: FirebaseAuth.instance.currentUser?.photoURL,
        date: DateTime.now().toIso8601String(),
      );

      // Submit the review
      await _reviewService.submitReview(widget.productId, review);

      // Update the product document with new rating average
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId);

      // Get the current product data
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final int currentReviewCount = productData['reviewCount'] ?? 0;
        final double currentRating = productData['rating'] ?? 0.0;

        // Calculate new average rating
        final double totalRatingPoints = currentRating * currentReviewCount;
        final int newReviewCount = currentReviewCount + 1;
        final double newAverageRating =
            (totalRatingPoints + _userRating) / newReviewCount;

        // Update the product with new rating data
        await productRef.update({
          'rating': newAverageRating,
          'reviewCount': newReviewCount,
          'lastReviewed': FieldValue.serverTimestamp(),
        });

        // Update local state
// In your _submitReview method, make sure to update these lines
        setState(() {
          _reviews.add(review);
          _reviewController.clear();
          _userRating = 5.0; // Reset rating
          _averageRating = newAverageRating;
          _reviewCount = newReviewCount;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Review submitted successfully!',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit review: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchAddedByUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          addedByUserName = user.displayName ?? "Guest User";
        });
      } else {
        setState(() {
          addedByUserName = "Guest User";
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        addedByUserName = "Guest User";
      });
    }
  }

  Future<void> _checkIfInWishlist() async {
    _isInWishlist = await _productService.checkIfInWishlist(widget.title);
    setState(() {});
  }

  Future<void> _fetchReviews() async {
    _reviews = await _reviewService.fetchReviews(widget.title);
    setState(() {});
  }

  void _increaseQuantity() {
    if (quantity < widget.stockCount) {
      setState(() {
        quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> _addToCart() async {
    if (widget.stockCount > 0) {
      try {
        await _productService.addToCart(
          widget.title,
          widget.imageUrl,
          widget.price,
          quantity,
          widget.userId,
        );

        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId);

        final productSnapshot = await productRef.get();
        if (productSnapshot.exists) {
          await productRef.update({
            'stockCount': FieldValue.increment(-quantity),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Added to Cart!',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Product not found in the database.',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add to cart: $e',
              style: const TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Out of Stock!',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProductDetails() async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        final data = productDoc.data() as Map<String, dynamic>;
        setState(() {
          _actualStockCount = data['stockCount'] ?? 0;
          _reviewCount = data['reviewCount'] ?? 0;
          _totalSold = data['totalSold'] ?? 0; // Add this line

          // Only use the rating if there are reviews
          if (_reviewCount > 0) {
            _averageRating = (data['rating'] ?? 0.0).toDouble();
          } else {
            _averageRating = 0.0; // No reviews yet
          }
        });
      }
    } catch (e) {
      print("Error loading product details: $e");
    }
  }

  Future<void> _checkIfInFavorites() async {
    final isFavorite =
        await _productService.checkIfInFavorites(widget.productId);
    setState(() {
      _isInFavorites = isFavorite;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRelatedProducts() async {
    try {
      // Query products in the same category, excluding the current one
      final relatedQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: widget.category)
          .where(FieldPath.documentId, isNotEqualTo: widget.productId)
          .limit(6)
          .get();
      
      List<Map<String, dynamic>> relatedProducts = relatedQuery.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      
      // If we don't have enough products in the same category
      if (relatedProducts.length < 6) {
        // Get products from other categories to fill up to 6
        final otherQuery = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isNotEqualTo: widget.category)
            .limit(6 - relatedProducts.length)
            .get();
        
        final otherProducts = otherQuery.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
        
        relatedProducts.addAll(otherProducts);
      }
      
      return relatedProducts;
    } catch (e) {
      print('Error fetching related products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          // Star icon for favorites
          IconButton(
            icon: Icon(
              _isInFavorites ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () async {
              await _productService.toggleFavorite(
                widget.productId,
                widget.title,
                widget.imageUrl,
                widget.price,
                widget.description,
                widget.userId,
              );
              setState(() {
                _isInFavorites = !_isInFavorites;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isInFavorites
                        ? 'Added to Favorites!'
                        : 'Removed from Favorites',
                    style: const TextStyle(fontFamily: 'PixelFont'),
                  ),
                  backgroundColor: _isInFavorites ? Colors.amber : Colors.grey,
                ),
              );
            },
          ),
          // Heart icon for wishlist (keep your existing code)
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
            ),
            color: const Color(0xFFFF0077),
            onPressed: () async {
              await _productService.toggleWishlist(
                widget.productId,
                widget.title,
                widget.imageUrl,
                widget.price,
                widget.description,
                widget.userId,
              );
              setState(() {
                _isInWishlist = !_isInWishlist;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isInWishlist
                        ? 'Added to Wishlist!'
                        : 'Removed from Wishlist',
                    style: const TextStyle(fontFamily: 'PixelFont'),
                  ),
                  backgroundColor:
                      _isInWishlist ? const Color(0xFFFF0077) : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F0F1B),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${_averageRating.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'PixelFont',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        if (index < _averageRating.floor()) {
                                          return const Icon(Icons.star,
                                              color: Colors.amber, size: 16);
                                        } else if (index ==
                                                _averageRating.floor() &&
                                            _averageRating -
                                                    _averageRating.floor() >
                                                0) {
                                          return const Icon(Icons.star_half,
                                              color: Colors.amber, size: 16);
                                        } else {
                                          return const Icon(Icons.star_border,
                                              color: Colors.amber, size: 16);
                                        }
                                      }),
                                    ),
                                    Text(
                                      "$_reviewCount ${_reviewCount == 1 ? 'review' : 'reviews'}",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontFamily: 'PixelFont',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_reviewCount > 0) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: 1.0,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber),
                                minHeight: 4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Computed from $_reviewCount ${_reviewCount == 1 ? 'rating' : 'ratings'}",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildGameTag("Genre: ${widget.category}"),
                          buildGameTag("Single Player"),
                          buildGameTag("Action RPG"),
                          buildGameTag("Anime Style"),
                          buildGameTag("Story Rich"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Available Stock: ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          Text(
                            "$_actualStockCount", // Use the loaded stock count
                            style: TextStyle(
                              color: _actualStockCount > 10
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          if (_actualStockCount < 5 && _actualStockCount > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Low Stock!",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          InkWell(
                            onTap: _decreaseQuantity,
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "-",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 28,
                            alignment: Alignment.center,
                            child: Text(
                              "$quantity",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _increaseQuantity,
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "+",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.stockCount > 0 ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                ),
                child: const Text("ADD TO CART"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.stockCount > 0 ? _buyNow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                ),
                child: const Text("BUY NOW"),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyan, width: 2),
                    ),
                    child: addedByUserAvatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              addedByUserAvatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, _) => const Icon(
                                  Icons.person,
                                  color: Colors.cyan,
                                  size: 32),
                            ),
                          )
                        : const Icon(Icons.person,
                            color: Colors.cyan, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Added by",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      Text(
                        addedByUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "REVIEWS",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 16),
            _canAddReview
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Add Your Review",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _userRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _userRating = index + 1.0;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                          ),
                          decoration: InputDecoration(
                            hintText: "Write your review here...",
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontFamily: 'PixelFont',
                            ),
                            filled: true,
                            fillColor: Colors.black45,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.cyan),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "SUBMIT REVIEW",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF0077),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "ONLY VERIFIED BUYERS CAN REVIEW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You can only review products after your order has been completed.",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'PixelFont',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You can only review products from completed orders.',
                                    style: TextStyle(fontFamily: 'PixelFont'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "COMPLETE AN ORDER FIRST",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),
            _reviews.isEmpty
                ? const Center(
                    child: Text(
                      "No reviews yet. Be the first to review!",
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  )
                : Column(
                    children: _reviews
                        .map((review) => ReviewItem(review: review))
                        .toList(),
                  ),
            const SizedBox(height: 24),
            // Products You May Also Like Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.whatshot, color: Colors.orange, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'PRODUCTS YOU MAY ALSO LIKE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchRelatedProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.orange),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No related products found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          );
                        }

                        final relatedProducts = snapshot.data!;

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: relatedProducts.length,
                          itemBuilder: (context, index) {
                            final product = relatedProducts[index];
                            
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to the product details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetails(
                                        productId: product['id'],
                                        imageUrl: product['imageUrl'] ?? '',
                                        title: product['name'] ?? 'Unknown Product',
                                        price: product['price']?.toString() ?? '0.00',
                                        description: product['description'] ?? 'No description available',
                                        rating: (product['rating'] ?? 0.0).toDouble(),
                                        stockCount: product['stockCount'] ?? 0,
                                        userId: product['userId'] ?? '',
                                        category: product['category'] ?? 'Unknown',
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey[700]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.network(
                                          product['imageUrl'] ?? '',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[900],
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported, color: Colors.grey),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product['name'] ?? 'Unknown Product',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'PixelFont',
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PHP ${product['price'] ?? '0.00'}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontFamily: 'PixelFont',
                                      ),
                                    ),
                                    // Small rating display
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${(product['rating'] ?? 0.0).toStringAsFixed(1)}',
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
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget buildGameTag(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'PixelFont',
        ),
      ),
    );
  }
}

// Review Item Widget
class ReviewItem extends StatelessWidget {
  final Review review;

  const ReviewItem({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format date for display
    final dateStr =
        review.date.isNotEmpty ? review.date.substring(0, 10) : "Unknown Date";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyan, width: 1),
                ),
                child: review.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          review.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, _) =>
                              const Icon(Icons.person, color: Colors.cyan),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.cyan),
              ),

              const SizedBox(width: 12),

              // Username and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review Comment
          Text(
            review.comment,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Rest of the classes remain the same as in your original code
class Review {
  final String username;
  final String comment;
  final double rating;
  final String? avatarUrl;
  final String date;

  Review({
    required this.username,
    required this.comment,
    required this.rating,
    this.avatarUrl,
    required this.date,
  });
}

// Update your ProductService class with these methods
class ProductService {
  Future<void> addToCart(String title, String imageUrl, String price,
      int quantity, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      await cartRef.doc(title).set({
        'imageUrl': imageUrl,
        'title': title,
        'price': price,
        'quantity': quantity,
        'addedBy': userId,
      });
    }
  }

// Update to toggle wishlist instead of just adding
  Future<bool> toggleWishlist(String productId, String title, String imageUrl,
      String price, String description, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist');

      final doc = await wishlistRef.doc(title).get();

      if (doc.exists) {
        // Remove from wishlist
        await wishlistRef.doc(title).delete();
        return false;
      } else {
        // Add to wishlist
        await wishlistRef.doc(title).set({
          'productId': productId,
          'imageUrl': imageUrl,
          'title': title,
          'price': price,
          'description': description,
          'addedBy': userId,
          'addedOn': FieldValue.serverTimestamp(),
        });
        return true;
      }
    }
    return false; // Return false if user is null
  }

  // Add favorites functionality
  Future<bool> toggleFavorite(String productId, String title, String imageUrl,
      String price, String description, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites');

      final doc = await favsRef.doc(productId).get();

      if (doc.exists) {
        // Remove from favorites
        await favsRef.doc(productId).delete();
        return false;
      } else {
        // Add to favorites
        await favsRef.doc(productId).set({
          'productId': productId,
          'imageUrl': imageUrl,
          'title': title,
          'price': price,
          'description': description,
          'addedBy': userId,
          'addedOn': FieldValue.serverTimestamp(),
        });
        return true;
      }
    }
    return false;
  }

  Future<bool> checkIfInWishlist(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist');

      final doc = await wishlistRef.doc(title).get();
      return doc.exists;
    }
    return false;
  }

  Future<bool> checkIfInFavorites(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites');

      final doc = await favsRef.doc(productId).get();
      return doc.exists;
    }
    return false;
  }
}

class ReviewService {
  Future<List<Review>> fetchReviews(String productId) async {
    final reviewsRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews');

    final snapshot = await reviewsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Review(
        username: data['username'] ?? 'Anonymous',
        comment: data['comment'] ?? '',
        rating: (data['rating'] ?? 0).toDouble(),
        avatarUrl: data['avatarUrl'],
        date: data['date'] ?? '',
      );
    }).toList();
  }

  Future<void> submitReview(String productId, Review review) async {
    final reviewsRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews');

    await reviewsRef.add({
      'username': review.username,
      'comment': review.comment,
      'rating': review.rating,
      'avatarUrl': review.avatarUrl,
      'date': review.date,
    });
  }
}
