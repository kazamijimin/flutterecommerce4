import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'other_user_profile.dart'; // Create this file for user profile view

class UserReviewHistory extends StatefulWidget {
  final String username;
  final String? avatarUrl;

  const UserReviewHistory({
    Key? key,
    required this.username,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<UserReviewHistory> createState() => _UserReviewHistoryState();
}

class _UserReviewHistoryState extends State<UserReviewHistory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _userReviews = [];
  bool _isLoading = true;
  
  String? _currentUserId;
  Map<String, dynamic>? _profileData;
  String _friendStatus = 'none'; // none, pending, accepted, blocked

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchUserReviews();
    _fetchProfileData();
    _checkFriendStatus();
  }

  Future<void> _fetchUserReviews() async {
    try {
      // Query all products collections for reviews by this user
      final productsSnapshot = await _firestore.collection('products').get();
      List<Map<String, dynamic>> allReviews = [];

      for (var productDoc in productsSnapshot.docs) {
        final reviewsSnapshot = await productDoc
            .reference
            .collection('reviews')
            .where('username', isEqualTo: widget.username)
            .get();

        for (var reviewDoc in reviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();
          // Add product information to the review data
          final productData = productDoc.data();
          allReviews.add({
            ...reviewData,
            'productId': productDoc.id,
            'productName': productData['name'] ?? 'Unknown Product',
            'productImage': productData['imageUrl'] ?? '',
            'productPrice': productData['price'] ?? '0.00',
          });
        }
      }

      // Sort reviews by date, most recent first
      allReviews.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

      setState(() {
        _userReviews = allReviews;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user reviews: $e');
      setState(() => _isLoading = false);
    }
  }
Future<void> _fetchProfileData() async {
  try {
    if (widget.username.isEmpty) {
      print('Username is empty');
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> userDoc = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      setState(() {
        _profileData = userDoc.docs.first.data();
        _profileData?['uid'] = userDoc.docs.first.id;
      });
    } else {
      print('No user found with username: ${widget.username}');
    }
  } catch (e) {
    print('Error fetching profile data: $e');
  }
}
Future<void> _checkFriendStatus() async {
  if (_currentUserId == null || _profileData == null) return;
    
  try {
    final friendDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(_profileData!['uid'])
        .get();

    final friendData = friendDoc.data();
    setState(() {
      _friendStatus = friendDoc.exists && friendData != null 
          ? friendData['status'] as String? ?? 'none'
          : 'none';
    });
  } catch (e) {
    print('Error checking friend status: $e');
    setState(() {
      _friendStatus = 'none';
    });
  }
}
  Future<void> _sendFriendRequest() async {
    if (_currentUserId == null || _profileData == null) return;
  
    // Show confirmation dialog before sending request
    bool shouldSend = await _showFriendRequestConfirmationDialog();
    if (!shouldSend) return;

    try {
      final timestamp = FieldValue.serverTimestamp();
      
      // Create friend request in sender's collection
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(_profileData?['uid'])
          .set({
        'status': 'pending',
        'timestamp': timestamp,
        'lastInteraction': timestamp,
        'senderId': _currentUserId,  // Add senderId to identify who sent the request
      });

      // Create friend request in receiver's collection
      await _firestore
          .collection('users')
          .doc(_profileData?['uid'])
          .collection('friends')
          .doc(_currentUserId)
          .set({
        'status': 'pending',
        'timestamp': timestamp,
        'lastInteraction': timestamp,
        'senderId': _currentUserId,  // Add senderId to identify who sent the request
      });

      // Update status locally
      setState(() {
        _friendStatus = 'pending';
      });

      // Show success message
      _showFriendRequestSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending friend request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showFriendRequestConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.cyan, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.cyan,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Send Friend Request',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'Do you want to send a friend request to ${widget.username}?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'PixelFont',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    // Confirm button
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Send Request',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
}

  void _showFriendRequestSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Request Sent!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  'Your friend request to ${widget.username} has been sent. You\'ll be notified when they accept.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'PixelFont',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_profileData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfile(
                      userId: _profileData!['uid'],
                      username: widget.username,
                      avatarUrl: widget.avatarUrl,
                    ),
                  ),
                );
              }
            },
            child: Hero(
              tag: 'profile_${widget.username}',
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                backgroundImage: widget.avatarUrl != null
                    ? CachedNetworkImageProvider(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 40)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                ),
                if (_profileData != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Level ${_profileData?['level'] ?? 1}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_currentUserId != null &&
              _profileData != null &&
              _currentUserId != _profileData?['uid'])
            _buildFriendButton(),
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    switch (_friendStatus) {
      case 'none':
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0077),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      case 'pending':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Pending'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        );
      case 'accepted':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check),
          label: const Text('Friends'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'PROFILE & REVIEWS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'PixelFont',
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                : _userReviews.isEmpty
                    ? _buildEmptyState()
                    : _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      itemCount: _userReviews.length,
      itemBuilder: (context, index) {
        final review = _userReviews[index];
        final date = review['date'] != null
            ? review['date'].substring(0, 10)
            : 'Unknown Date';

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetails(
                    productId: review['productId'],
                    imageUrl: review['productImage'],
                    title: review['productName'],
                    price: review['productPrice'].toString(),
                    description: review['description'] ?? 'No description available',
                    sellerId: review['userId'] ?? 'Unknown Seller',
                    category: review['category'] ?? 'Games', // Add this line
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review['productImage'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['productName'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            Text(
                              'PHP ${review['productPrice']}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Review Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (review['rating'] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
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
    );
  }
}