import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
    _fetchReviews();
    _fetchAddedByUserInfo();
  }

  void _submitReview() async {
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

      await _reviewService.submitReview(widget.productId, review);

      setState(() {
        _reviews.add(review);
        _reviewController.clear();
        _userRating = 5.0; // Reset rating
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
    _isInWishlist = await _productService.checkIfInWishlist(widget.title);
    setState(() {});
  }

  Future<void> _fetchReviews() async {
    _reviews = await _reviewService.fetchReviews(widget.title);
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

        await favoritesRef.doc(widget.productId).set({
          'productId': widget.productId,
          'imageUrl': widget.imageUrl,
          'title': widget.title,
          'price': widget.price,
          'description': widget.description,
          'userId': widget.userId,
          'category': widget.category,
        });

        setState(() {
          _isInWishlist = true; // Update the UI to reflect the favorite status
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add to Favorites: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
            ),
            color: const Color(0xFFFF0077),
            onPressed: _addToFavorites, // Call the method to add to favorites
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
                      Row(
                        children: [
                          const Text(
                            "Average Rating: ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          Text(
                            "${widget.rating}",
                            style: const TextStyle(
                              color: Colors.white,
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
                            "${widget.stockCount}",
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

  Future<void> addToWishlist(String title, String imageUrl, String price,
      String description, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist');

      await wishlistRef.doc(title).set({
        'imageUrl': imageUrl,
        'title': title,
        'price': price,
        'description': description,
        'addedBy': userId,
      });
    }
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
