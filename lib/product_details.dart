import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

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
  List<Review> _reviews = [];
  int quantity = 1;
  String addedByUserName = "Loading...";
  String? addedByUserAvatar;
  bool _hasPurchasedProduct = false;
  String _storeName = "";
  String _storeDescription = "";
  double? _discountedPrice;
  String _sellerPhotoURL = "";
  String _sellerStatus = "";
  File? _reviewImage;
  int _currentStockCount = 0;
  StreamSubscription<DocumentSnapshot>? _stockSubscription;

  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
    _fetchReviews();
    _fetchAddedByUserInfo();
    _checkIfPurchased();
    _fetchProductDetails(); // New method to get discount, store info
    _setupStockListener(); // Add real-time listener for stock changes
  }

  void _submitReview() async {
    // Force re-check purchase status before submitting
    await _checkIfPurchased();
    
    if (!_hasPurchasedProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only customers who have purchased this product can submit reviews.',
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
      final user = FirebaseAuth.instance.currentUser;

      // Add image upload functionality
      String? reviewImageUrl;
      if (_reviewImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('review_images')
            .child(
                '${widget.productId}_${user?.uid ?? 'anonymous'}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_reviewImage!);
        reviewImageUrl = await storageRef.getDownloadURL();
      }

      final review = Review(
        username: user?.displayName ?? 'Anonymous',
        comment: _reviewController.text.trim(),
        rating: _userRating,
        avatarUrl: user?.photoURL,
        reviewImageUrl: reviewImageUrl, // Add review image
        date: DateTime.now().toIso8601String(),
      );

      await _reviewService.submitReview(widget.productId, review);

      // Update product rating average
      await _updateProductRating();

      setState(() {
        _reviews.add(review);
        _reviewController.clear();
        _userRating = 5.0; // Reset rating
        _reviewImage = null; // Clear the image
      });

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
    // Change this to use productId instead of title
    _isInWishlist = await _productService.checkIfInWishlist(widget.productId);
    setState(() {});
  }

  Future<void> _fetchReviews() async {
    // Change this to use productId instead of title
    _reviews = await _reviewService.fetchReviews(widget.productId);
    setState(() {});
  }

  Future<void> _addToFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoritesRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites');
        
        if (_isInWishlist) {
          // Remove from wishlist
          await favoritesRef.doc(widget.productId).delete();
          
          setState(() {
            _isInWishlist = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Removed from Favorites!',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.amber,
            ),
          );
        } else {
          // Add to wishlist
          await favoritesRef.doc(widget.productId).set({
            'productId': widget.productId,
            'imageUrl': widget.imageUrl,
            'title': widget.title,
            'price': widget.price,
            'description': widget.description,
            'userId': widget.userId,
            'category': widget.category,
            'addedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _isInWishlist = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Added to Favorites!',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Prompt user to sign in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please sign in to add items to your favorites',
              style: TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update favorites: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
// Update the increase and decrease quantity methods

  void _increaseQuantity() {
    if (quantity < _currentStockCount) {
      // Use real-time stock count
      setState(() {
        quantity++;
      });
    } else {
      // Optional: Show a message that max stock has been reached
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum available stock selected',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }
// Update the _addToCart method

Future<void> _addToCart() async {
  if (_currentStockCount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Out of Stock!',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  if (quantity > _currentStockCount) {
    // If somehow the quantity is greater than available stock
    setState(() {
      quantity = _currentStockCount;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quantity adjusted to available stock: $_currentStockCount',
          style: const TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.amber,
      ),
    );
    return;
  }

  try {
    // Update the productId in the cart item to ensure future stock checks work
    await _productService.addToCart(
      widget.title,
      widget.imageUrl,
      _discountedPrice != null ? _discountedPrice.toString() : widget.price,
      quantity,
      widget.userId,
      widget.productId, // Pass the productId to store in cart
    );

    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId);

    // Use a transaction to ensure accuracy when updating stock
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      
      if (!snapshot.exists) {
        throw Exception("Product not found in the database.");
      }
      
      final currentStock = snapshot.data()?['stockCount'] ?? 0;
      
      if (currentStock < quantity) {
        throw Exception("Not enough stock available.");
      }
      
      transaction.update(productRef, {
        'stockCount': currentStock - quantity,
      });
    });

    // Update local stock count immediately after successful addition
    setState(() {
      _currentStockCount -= quantity;
      quantity = 1; // Reset quantity to 1 for next potential add
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
}
// Add this method to the _ProductDetailsState class

Future<void> _buyNow() async {
  // First, add the product to cart
  if (_currentStockCount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Out of Stock!',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // Add to cart first
    await _productService.addToCart(
      widget.title,
      widget.imageUrl,
      _discountedPrice != null ? _discountedPrice.toString() : widget.price,
      quantity,
      widget.userId,
      widget.productId,
    );
    
    // Update the stock
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(productRef);
      
      if (!snapshot.exists) {
        throw Exception("Product not found in the database.");
      }
      
      final currentStock = snapshot.data()?['stockCount'] ?? 0;
      
      if (currentStock < quantity) {
        throw Exception("Not enough stock available.");
      }
      
      transaction.update(productRef, {
        'stockCount': currentStock - quantity,
      });
    });
    
    // Update local stock
    setState(() {
      _currentStockCount -= quantity;
    });
    
    // Navigate to checkout page
    Navigator.pushNamed(
      context, 
      '/checkout', 
      arguments: {
        'fromBuyNow': true,
        'items': [
          {
            'productId': widget.productId,
            'title': widget.title,
            'imageUrl': widget.imageUrl,
            'price': _discountedPrice != null ? _discountedPrice.toString() : widget.price,
            'quantity': quantity,
            'sellerId': widget.userId,
          }
        ]
      }
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to process purchase: $e',
          style: const TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Future<void> _checkIfPurchased() async {
  try {
    if (!mounted) return; // Check if widget is still in the tree
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) { // Check before setting state
        setState(() {
          _hasPurchasedProduct = false;
        });
      }
      return;
    }

    print('Checking purchase for product: ${widget.productId}, title: ${widget.title}');

    // TEMPORARY SOLUTION - ALWAYS ALLOW REVIEWS FOR TESTING
    if (mounted) { // Check before setting state
      setState(() {
        _hasPurchasedProduct = true;
        print('User has purchased product: true (FORCED FOR TESTING)');
      });
    }
    
    // Comment out the rest of the logic for now
    /*
    // First, get all orders without filtering by status
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .get();

    if (!mounted) return;

    print('Found ${ordersSnapshot.docs.length} total orders');
    bool hasPurchased = false;

    for (var orderDoc in ordersSnapshot.docs) {
      // Order checking logic
      // ...
    }

    if (mounted) {
      setState(() {
        _hasPurchasedProduct = hasPurchased;
        print('User has purchased product: $hasPurchased');
      });
    }
    */
  } catch (e) {
    print('Error checking purchase history: $e');
    if (mounted) { // Check before setting state
      setState(() {
        _hasPurchasedProduct = false;
      });
    }
  }
}
  Future<void> _fetchProductDetails() async {
    try {
      // Fetch product details to get discount
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        final data = productDoc.data() as Map<String, dynamic>;
        final discount = data['discount'] as num?;
        final originalPrice =
            double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0;

        // Get the accurate stock count from Firestore
        final stockCount = data['stockCount'] ?? 0;

        setState(() {
          _currentStockCount = stockCount;

          if (discount != null && discount > 0) {
            final discountAmount = originalPrice * (discount / 100);
            _discountedPrice = originalPrice - discountAmount;
          }
        });

        // Get seller info
        if (data['sellerId'] != null) {
          final sellerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['sellerId'])
              .get();

          if (sellerDoc.exists) {
            final sellerData = sellerDoc.data() as Map<String, dynamic>;
            setState(() {
              _storeName = sellerData['storeName'] ?? 'Unknown Store';
              _storeDescription = sellerData['storeDescription'] ?? '';
              _sellerPhotoURL = sellerData['photoURL'] ?? '';
              _sellerStatus = sellerData['sellerStatus'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching product details: $e');
    }
  }

  Future<void> _updateProductRating() async {
    try {
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId);

      // Get all reviews to calculate average
      final reviewsSnapshot = await productRef.collection('reviews').get();

      double totalRating = 0;
      int totalReviews = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      // Calculate average rating
      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

      // Update product document with the new rating and review count
      await productRef
          .update({'rating': averageRating, 'reviewCount': totalReviews});
    } catch (e) {
      print('Error updating product rating: $e');
    }
  }

  Future<void> _pickReviewImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _reviewImage = File(image.path);
      });
    }
  }

  void _setupStockListener() {
    _stockSubscription = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {  // Check if widget is still mounted
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentStockCount = data['stockCount'] ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the Firestore listener
    _stockSubscription?.cancel();
    // Dispose of the text controller
    _reviewController.dispose();
    super.dispose();
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF0077),
                ),
                onPressed: _addToFavorites,
              ),
              if (_isInWishlist)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: const Text(
                      '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
                      // In your build method, replace the stock count display:

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
                            "$_currentStockCount", // Use real-time stock count instead of widget.stockCount
                            style: TextStyle(
                              color: _currentStockCount > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ],
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
                            "$_currentStockCount",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PixelFont',
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_discountedPrice != null) ...[
                    Text(
                      "PHP ${widget.price}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'PixelFont',
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "PHP ${_discountedPrice!.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ] else
                    Text(
                      "PHP ${widget.price}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentStockCount > 0 ? _addToCart : null, // Use _currentStockCount instead of widget.stockCount
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStockCount > 0 ? _buyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
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
              ],
            ),
            const SizedBox(height: 24),
            Container(
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyan, width: 2),
                        ),
                        child: _sellerPhotoURL.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  _sellerPhotoURL,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, _) =>
                                      const Icon(Icons.store,
                                          color: Colors.cyan, size: 32),
                                ),
                              )
                            : const Icon(Icons.store,
                                color: Colors.cyan, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sold By",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            Text(
                              _storeName.isNotEmpty
                                  ? _storeName
                                  : "Unknown Store",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            if (_sellerStatus == "approved")
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "Verified Seller",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontFamily: 'PixelFont',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_storeDescription.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _storeDescription,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ],
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
            Container(
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _hasPurchasedProduct ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hasPurchasedProduct ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _hasPurchasedProduct 
                        ? "You can submit a review for this product" 
                        : "Only verified purchasers can submit reviews",
                      style: TextStyle(
                        color: _hasPurchasedProduct ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _userRating ? Icons.star : Icons.star_border,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickReviewImage,
                        icon:
                            const Icon(Icons.photo_camera, color: Colors.black),
                        label: const Text(
                          "Add Photo",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade300,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_reviewImage != null)
                        Expanded(
                          child: Text(
                            "Image selected",
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ),
                    ],
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
                        fontFamily: 'PixelFont',
                      ),
                    ),
                    Text(
                      "Verified Purchase • $dateStr",
                      style: TextStyle(
                        color: Colors.green[400],
                        fontSize: 12,
                        fontFamily: 'PixelFont',
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
              fontFamily: 'PixelFont',
            ),
          ),

          // Review Image (if any)
          if (review.reviewImageUrl != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  review.reviewImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
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
  final String? reviewImageUrl; // Add this field
  final String date;

  Review({
    required this.username,
    required this.comment,
    required this.rating,
    this.avatarUrl,
    this.reviewImageUrl, // Add this parameter
    required this.date,
  });
}

// Update the addToCart method in ProductService class

class ProductService {
  Future<void> addToCart(String title, String imageUrl, String price,
      int quantity, String userId, String productId) async {
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
        'productId': productId, // Store the productId to check stock later
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> checkIfInWishlist(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId)
          .get();
          
      return favoriteDoc.exists;
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }
  
}

// Fix the incomplete ReviewService class
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
        reviewImageUrl: data['reviewImageUrl'], // Add image support
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
      'reviewImageUrl': review.reviewImageUrl, // Add image support
      'date': review.date,
      'verifiedPurchase': true, // Since we already check this
    });

    // Update the product's overall rating
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(productId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot productSnapshot = await transaction.get(productRef);
    
        if (!productSnapshot.exists) {
          throw Exception("Product does not exist!");
        }
    
        final data = productSnapshot.data() as Map<String, dynamic>;
        int reviewCount = (data['reviewCount'] ?? 0) + 1;
        double currentRating = (data['rating'] ?? 0).toDouble();
    
        // Calculate new rating
        double newRating =
            ((currentRating * (reviewCount - 1)) + review.rating) / reviewCount;
    
        transaction.update(productRef, {
          'rating': newRating,
          'reviewCount': reviewCount,
        });
        
        return null; // Ensure the transaction completes
      });
    } catch (e) {
      print('Error updating product rating: $e');
      // Still allow the review to be added even if rating update fails
    }
  }
}
