import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductDetails extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String description;
  final double rating;
  final int stockCount;
  final String userId; // New field to store the user who added the product

  const ProductDetails({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
    this.rating = 4.9,
    this.stockCount = 41,
    required this.userId, // Mark as required
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
  String addedByUserName = "Loading..."; // Placeholder for the user's name

  @override
  void initState() {
    super.initState();
    _checkIfInWishlist();
    _fetchReviews();
    _fetchAddedByUserName(); // Fetch the name of the user who added the product
  }

  Future<void> _fetchAddedByUserName() async {
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

  Future<void> _submitReview() async {
    final review = Review(
      username: FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
      comment: _reviewController.text,
      rating: _userRating,
      avatarUrl: FirebaseAuth.instance.currentUser?.photoURL,
      date: DateTime.now().toIso8601String(),
    );

    await _reviewService.submitReview(widget.title, review);
    setState(() {
      _reviews.add(review);
      _reviewController.clear();
      _userRating = 5.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addToCart() async {
    if (widget.stockCount > 0) {
      await _productService.addToCart(
        widget.title,
        widget.imageUrl,
        widget.price,
        quantity,
        widget.userId,
      );

      // Decrement stock count in Firestore
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(widget.title);
      await productRef.update({
        'stockCount': FieldValue.increment(-quantity),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to Cart!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Out of Stock!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buyNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proceeding to Checkout...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
            ),
            color: const Color(0xFFFF0077),
            onPressed: () async {
              await _productService.addToWishlist(
                widget.title,
                widget.imageUrl,
                widget.price,
                widget.description,
                widget.userId,
              );
              setState(() {
                _isInWishlist = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            color: const Color(0xFF00E5FF),
            onPressed: () {
              // Implement share functionality
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ProductImage(imageUrl: widget.imageUrl),

              // Product Info
              ProductInfo(
                title: widget.title,
                price: widget.price,
                description: widget.description,
                rating: widget.rating,
                stockCount: widget.stockCount, // Pass the stockCount parameter
                category:
                    "Category Placeholder", // Replace with the actual category value

                onAddToCart: _addToCart,
                onBuyNow: _buyNow,
              ),

              const SizedBox(height: 16),

              // Display the name of the user who added the product
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Added by: $addedByUserName",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reviews Section
              ReviewsSection(
                reviews: _reviews,
                reviewController: _reviewController,
                userRating: _userRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _userRating = rating;
                  });
                },
                onSubmitReview: _submitReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Product Image Widget
class ProductImage extends StatelessWidget {
  final String imageUrl;

  const ProductImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFFF0077),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0077).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

// Product Info Widget
// Product Info Widget
class ProductInfo extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final double rating;
  final int stockCount;
  final String category; // Add category
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const ProductInfo({
    Key? key,
    required this.title,
    required this.price,
    required this.description,
    required this.rating,
    required this.stockCount,
    required this.category, // Add category
    required this.onAddToCart,
    required this.onBuyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF232339).withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFFDD00),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFDD00),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category
          Text(
            'Category: $category',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 8),

          // Price
          Text(
            '\$${price}',
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 8),

          // Stock Count
          Text(
            'Stock: $stockCount',
            style: TextStyle(
              fontSize: 16,
              color: stockCount > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'PixelFont',
            ),
          ),
          const SizedBox(height: 16),

          // Add to Cart and Buy Now Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: stockCount > 0 ? onAddToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0077),
                  ),
                  child: const Text(
                    "ADD TO CART",
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: stockCount > 0 ? onBuyNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                  ),
                  child: const Text(
                    "BUY NOW",
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Reviews Section Widget
class ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final TextEditingController reviewController;
  final double userRating;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSubmitReview;

  const ReviewsSection({
    Key? key,
    required this.reviews,
    required this.reviewController,
    required this.userRating,
    required this.onRatingChanged,
    required this.onSubmitReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REVIEWS",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E5FF),
              fontFamily: 'PixelFont',
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),

          // Add Review
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ADD YOUR REVIEW",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < userRating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFDD00),
                        size: 30,
                      ),
                      onPressed: () {
                        onRatingChanged(index + 1.0);
                      },
                    );
                  }),
                ),

                // Review Text Field
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                  ),
                  decoration: InputDecoration(
                    hintText: "Share your thoughts on this product...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'PixelFont',
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFFFF0077),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFFFF0077).withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Review Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDD00),
                    ),
                    child: const Text("SUBMIT"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Review List
          ...reviews.map((review) => ReviewItem(review: review)).toList(),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF0077).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // User Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00E5FF),
                        width: 1,
                      ),
                    ),
                    child: review.avatarUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              review.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person,
                                      color: Color(0xFF00E5FF)),
                            ),
                          )
                        : const Icon(Icons.person, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    review.username,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ],
              ),
              Text(
                review.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'PixelFont',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFDD00),
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 8),

          // Comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }
}

// Review Model
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

// Product Service
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
        'addedBy': userId, // Store the user who added the product
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
        'addedBy': userId, // Store the user who added the product
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

// Review Service
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
