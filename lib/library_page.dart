import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_details.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveredProducts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDeliveredProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveredProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = "Please log in to view your library";
          _isLoading = false;
        });
        return;
      }

      // Get all orders with status 'delivered'
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'delivered')
          .get();

      List<Map<String, dynamic>> products = [];

      // For each order, get the ordered items
      for (var orderDoc in orderSnapshot.docs) {
        final orderData = orderDoc.data();
        final orderDate = orderData['deliveredDate'] ?? orderData['orderDate'];

        // Safely handle items list with type checking
        List<dynamic> orderItems = [];
        if (orderData['items'] != null) {
          if (orderData['items'] is List) {
            orderItems = orderData['items'] as List<dynamic>;
          } else {
            // If not a list, skip this order
            continue;
          }
        }

        // Add each item to the products list with additional order info
        for (var item in orderItems) {
          // Make sure item is a Map before trying to access its properties
          if (item is! Map) continue;

          // Create a new Map with string keys
          final Map<String, dynamic> productItem = {};

          // Safely extract values with type checking
          try {
            productItem['id'] = item['productId']?.toString() ?? '';
            productItem['name'] = item['title']?.toString() ??
                item['name']?.toString() ??
                'Unknown Product';
            productItem['imageUrl'] = item['imageUrl']?.toString() ?? '';
            productItem['price'] = item['price']?.toString() ?? '0.00';
            productItem['quantity'] =
                item['quantity'] is int ? item['quantity'] : 1;
            productItem['sellerId'] = item['sellerId']?.toString() ?? '';
            productItem['orderDate'] = orderDate;
            productItem['orderId'] = orderDoc.id;
            productItem['category'] = item['category']?.toString() ?? 'Games';
            productItem['downloadLink'] =
                item['downloadLink']?.toString() ?? '';
            productItem['activationKey'] =
                item['activationKey']?.toString() ?? '';

            // Handle lastPlayed which might be a Timestamp or null
            if (item['lastPlayed'] is Timestamp) {
              productItem['lastPlayed'] = item['lastPlayed'];
            } else {
              productItem['lastPlayed'] = null;
            }

            // Handle playTime which should be an integer
            if (item['playTime'] is int) {
              productItem['playTime'] = item['playTime'];
            } else {
              productItem['playTime'] = 0;
            }

            products.add(productItem);
          } catch (e) {
            // Skip this item if there's an error
            print('Error processing item: $e');
            continue;
          }
        }
      }

      // Update your sorting function to handle multiple types
      products.sort((a, b) {
        // Safely extract dates without direct casting
        final aDateRaw = a['orderDate'];
        final bDateRaw = b['orderDate'];

        // Handle cases where either value is null
        if (aDateRaw == null && bDateRaw == null) return 0;
        if (aDateRaw == null) return 1;
        if (bDateRaw == null) return -1;

        // Convert both to DateTime for comparison
        DateTime? aDateTime;
        DateTime? bDateTime;

        // Handle Timestamp type
        if (aDateRaw is Timestamp) {
          aDateTime = aDateRaw.toDate();
        }
        // Handle String type
        else if (aDateRaw is String) {
          try {
            aDateTime = DateTime.parse(aDateRaw);
          } catch (e) {
            // If parsing fails, use current time
            print('Failed to parse date string: $aDateRaw');
          }
        }

        // Handle Timestamp type
        if (bDateRaw is Timestamp) {
          bDateTime = bDateRaw.toDate();
        }
        // Handle String type
        else if (bDateRaw is String) {
          try {
            bDateTime = DateTime.parse(bDateRaw);
          } catch (e) {
            // If parsing fails, use current time
            print('Failed to parse date string: $bDateRaw');
          }
        }

        // If we couldn't parse either date, fallback to string comparison
        if (aDateTime == null && bDateTime == null) {
          return aDateRaw.toString().compareTo(bDateRaw.toString());
        } else if (aDateTime == null) {
          return 1;
        } else if (bDateTime == null) {
          return -1;
        }

        // Compare dates
        return bDateTime.compareTo(aDateTime); // Most recent first
      });

      setState(() {
        _deliveredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading your library: $e";
        _isLoading = false;
      });
    }
  }

  // Format timestamp to readable date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    if (timestamp is Timestamp) {
      return DateFormat('MMM d, y').format(timestamp.toDate());
    } else if (timestamp is String) {
      try {
        return DateFormat('MMM d, y').format(DateTime.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    }

    return 'Unknown date format';
  }

  // Format playtime into hours and minutes
  String _formatPlayTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $remainingMinutes min';
      }
    }
  }

  // Simulate starting a game
  void _startGame(Map<String, dynamic> product) {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF0077), width: 2),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LAUNCHING ${product['name'].toString().toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait...',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Simulate loading time
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Close dialog

      // Record play session
      _recordPlaySession(product);

      // Show gameplay UI
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product['name'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DEMO GAMEPLAY',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Color(0xFFFF0077),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0077),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'EXIT GAME',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Record that user played the game
  // Record that user played the game
  Future<void> _recordPlaySession(Map<String, dynamic> product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get current timestamp
      final now = Timestamp.now();

      // First, get the current order document
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(product['orderId'])
          .get();

      if (!orderDoc.exists) {
        print('Order document does not exist');
        return;
      }

      // Get the items array
      final orderData = orderDoc.data();
      if (orderData == null) return;

      final List<dynamic> items = List.from(orderData['items'] ?? []);

      // Find the index of our product
      final int itemIndex = items.indexWhere(
          (item) => item is Map && item['productId'] == product['id']);

      if (itemIndex != -1) {
        // Update the specific item in the array
        final Map<String, dynamic> updatedItem =
            Map<String, dynamic>.from(items[itemIndex]);

        // Increment play time by 5 minutes for demo
        int currentPlayTime =
            updatedItem['playTime'] is int ? updatedItem['playTime'] : 0;
        updatedItem['lastPlayed'] = now;
        updatedItem['playTime'] = currentPlayTime + 5; // Add 5 minutes playtime

        // Replace the item in the array
        items[itemIndex] = updatedItem;

        // Update the document with the modified array
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(product['orderId'])
            .update({
          'items': items,
        });

        // Also update our local copy so UI refreshes
        setState(() {
          final int productIndex = _deliveredProducts.indexWhere((p) =>
              p['id'] == product['id'] && p['orderId'] == product['orderId']);

          if (productIndex != -1) {
            _deliveredProducts[productIndex]['playTime'] =
                updatedItem['playTime'];
            _deliveredProducts[productIndex]['lastPlayed'] =
                updatedItem['lastPlayed'];
          }
        });
      }
    } catch (e) {
      print('Error recording play session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'MY LIBRARY',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF0077),
          labelStyle: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'GAMES'),
            Tab(text: 'SOFTWARE'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF0077)),
            onPressed: _fetchDeliveredProducts,
            tooltip: 'Refresh library',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0077)),
            )
          : _error != null
              ? _buildErrorView()
              : _deliveredProducts.isEmpty
                  ? _buildEmptyLibraryView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductGrid(_deliveredProducts), // All products
                        _buildProductGrid(_deliveredProducts
                            .where((product) =>
                                product['category']?.toString().toLowerCase() ==
                                'games')
                            .toList()), // Games only
                        _buildProductGrid(_deliveredProducts
                            .where((product) =>
                                product['category']?.toString().toLowerCase() ==
                                'software')
                            .toList()), // Software only
                      ],
                    ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'No items in this category',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

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
        return _buildLibraryItem(product);
      },
    );
  }

  Widget _buildLibraryItem(Map<String, dynamic> product) {
    // Format the delivery date
    final deliveryDate = _formatDate(product['orderDate']);
    // Check if there's playtime data
    final bool hasPlaytime =
        product['playTime'] != null && product['playTime'] > 0;
    final bool hasLastPlayed = product['lastPlayed'] != null;

    // Check if it's a game
    final bool isGame =
        product['category']?.toString().toLowerCase() == 'games';

    // Check if it has activation key or download link
    final bool hasActivationKey = product['activationKey'] != null &&
        product['activationKey'].toString().isNotEmpty;
    final bool hasDownloadLink = product['downloadLink'] != null &&
        product['downloadLink'].toString().isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Show product details with owned product info
        _showProductActions(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF333355),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game/Software Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    product['imageUrl'].toString(),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white),
                    ),
                  ),
                ),
                // Indicator for "Play" or "Install" button
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (isGame) {
                        _startGame(product);
                      } else if (hasDownloadLink) {
                        _launchDownload(product['downloadLink'].toString());
                      } else {
                        _showProductActions(product);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0077),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isGame ? Icons.play_arrow : Icons.download,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product['name'].toString(),
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Delivered date
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Delivered: $deliveryDate',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Play time if available
                  if (hasPlaytime)
                    Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.cyan,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPlayTime(product['playTime'] as int),
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            color: Colors.cyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                  // Last played if available
                  if (hasLastPlayed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last: ${_formatDate(product['lastPlayed'] as Timestamp?)}',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGame
                          ? Colors.pink.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isGame
                            ? Colors.pink.withOpacity(0.5)
                            : Colors.blue.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      product['category']?.toString() ?? 'Games',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        color: isGame ? Colors.pink : Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
  }

  // Launch download link
  Future<void> _launchDownload(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch download link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show actions for a product (play, download, view key)
  void _showProductActions(Map<String, dynamic> product) {
    final bool isGame =
        product['category']?.toString().toLowerCase() == 'games';
    final bool hasActivationKey = product['activationKey'] != null &&
        product['activationKey'].toString().isNotEmpty;
    final bool hasDownloadLink = product['downloadLink'] != null &&
        product['downloadLink'].toString().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: const Color(0xFFFF0077), width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header
            Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['imageUrl'].toString(),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Product title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'].toString(),
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['category']?.toString() ?? 'Games',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: isGame ? Colors.pink : Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFF333355)),
            const SizedBox(height: 10),

            // Actions
            if (isGame)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Color(0xFFFF0077)),
                title: const Text(
                  'Play',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startGame(product);
                },
              ),

            if (hasDownloadLink)
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text(
                  'Download',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchDownload(product['downloadLink'].toString());
                },
              ),

            if (hasActivationKey)
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.amber),
                title: const Text(
                  'View Activation Key',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showActivationKey(product);
                },
              ),

            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.cyan),
              title: const Text(
                'Product Details',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetails(
                      productId: product['id'].toString(),
                      imageUrl: product['imageUrl'].toString(),
                      title: product['name'].toString(),
                      price: product['price'].toString(),
                      description: 'View your owned product',
                      sellerId: product['sellerId'].toString(),
                      category: product['category']?.toString() ?? 'Games',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show activation key in a dialog
  void _showActivationKey(Map<String, dynamic> product) {
    final activationKey = product['activationKey']?.toString() ?? '';

    if (activationKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No activation key available for this product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Activation Key',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use this key to activate your product:',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activationKey,
                      style: const TextStyle(
                        fontFamily: 'PixelFont',
                        color: Colors.amber,
                        fontSize: 16,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: activationKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activation key copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'CLOSE',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Color(0xFFFF0077),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchDeliveredProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0077),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'TRY AGAIN',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLibraryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 24),
          const Text(
            'Your library is empty',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Products you purchase will appear here after delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0077),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'SHOP NOW',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
