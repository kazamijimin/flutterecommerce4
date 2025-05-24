import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'message.dart';

class OtherUserProfile extends StatefulWidget {
  final String userId;
  final String username;
  final String? avatarUrl;

  const OtherUserProfile({
    Key? key,
    required this.userId,
    required this.username,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _orderedProducts = [];
  bool _isLoading = true;
  int _friendCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchOrderedProducts();
  }
void startChat(BuildContext context, String userId, String username) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatDetailPage(
        conversationId: userId,  // This will be calculated in ChatDetailPage
        recipientId: userId,
        recipientName: username,
      ),
    ),
  );
}
  Future<void> _fetchUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _friendCount = _userData?['friendCount'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrderedProducts() async {
    setState(() => _isLoading = true);

    try {
      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'delivered')
          .get();

      List<Map<String, dynamic>> products = [];

      for (var orderDoc in ordersQuery.docs) {
        final items = orderDoc.data()['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          products.add({
            'id': item['productId'] ?? '',
            'name': item['title'] ?? 'Unknown Product',
            'price': item['price'] ?? 0.0,
            'imageUrl': item['imageUrl'] ?? '',
            'category': item['category'] ?? 'Games',
            'orderDate': orderDoc['orderDate'],
            'playTime': item['playTime'] ?? 0,
            'lastPlayed': item['lastPlayed'],
          });
        }
      }

      setState(() {
        _orderedProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ordered products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF0077)),
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
                      const Color(0xFFFF0077).withOpacity(0.8),
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
                            color: const Color(0xFFFF0077).withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0077).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'profile_${widget.username}',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: widget.avatarUrl != null
                                ? CachedNetworkImageProvider(widget.avatarUrl!)
                                : null,
                            ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.username,
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
                        _orderedProducts.length.toString(),
                        'Games',
                        Icons.games,
                        const Color(0xFFFF0077),
                      ),
                      _buildStatItem(
                        _friendCount.toString(),
                        'Friends',
                        Icons.people,
                        Colors.cyan,
                      ),
                      _buildStatItem(
                        _userData?['level']?.toString() ?? '1',
                        'Level',
                        Icons.star,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      'SEND MESSAGE',
                      style: TextStyle(fontFamily: 'PixelFont'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0077),
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => startChat(
                      context,
                      widget.userId,
                      widget.username,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'GAME COLLECTION',
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

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
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
    if (_orderedProducts.isEmpty) {
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
            Icon(Icons.games_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No games in collection',
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
              'This user hasn\'t purchased any games yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'PixelFont',
              ),
              textAlign: TextAlign.center,
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
      itemCount: _orderedProducts.length,
      itemBuilder: (context, index) {
        final product = _orderedProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final playTime = product['playTime'] ?? 0;
    final lastPlayed = product['lastPlayed'] as Timestamp?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0077).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: Colors.grey[800],
                    child: const Icon(Icons.error, color: Colors.white60),
                  ),
                ),
              ),
              if (playTime > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.cyan, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${playTime}h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unknown Game',
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
                if (lastPlayed != null)
                  Text(
                    'Last played: ${_formatDate(lastPlayed)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontFamily: 'PixelFont',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}