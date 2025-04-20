import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product.dart';
import 'order_status.dart';
import 'your_products.dart';
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dashboard stats
  int totalCategories = 0;
  int totalProducts = 0;
  int pendingOrders = 0;
  int canceledOrders = 0;
  int completedOrders = 0;

  // Cyberpunk theme colors
  final Color _primaryRed = const Color(0xFFFF003C);
  final Color _darkBackground = const Color(0xFF0D0D0D);
  final Color _accentColor = const Color(0xFF00F0FF);

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get unique categories count
      final QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .get();

      final Set<String> categories = {};
      for (var doc in productsSnapshot.docs) {
        if (doc.data() is Map && (doc.data() as Map).containsKey('category')) {
          categories.add((doc.data() as Map)['category'] as String);
        }
      }

      // Get order counts
      final QuerySnapshot pendingSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final QuerySnapshot canceledSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'canceled')
          .get();

      final QuerySnapshot completedSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (mounted) {
        setState(() {
          totalCategories = categories.length;
          totalProducts = productsSnapshot.size;
          pendingOrders = pendingSnapshot.size;
          canceledOrders = canceledSnapshot.size;
          completedOrders = completedSnapshot.size;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  // Edit Product
  Future<void> _editProduct(DocumentSnapshot product) async {
    final TextEditingController nameController =
        TextEditingController(text: product['name']);
    final TextEditingController priceController =
        TextEditingController(text: product['price'].toString());
    final TextEditingController descriptionController =
        TextEditingController(text: product['description']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _darkBackground,
          title: Text(
            'Edit Product',
            style: TextStyle(color: _primaryRed, fontFamily: 'PixelFont'),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _primaryRed),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _primaryRed),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _primaryRed),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontFamily: 'PixelFont')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('products').doc(product.id).update({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'description': descriptionController.text,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
              ),
              child:
                  const Text('Save', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
      },
    );
  }

  // Delete Product
  Future<void> _deleteProduct(DocumentSnapshot product) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _darkBackground,
          title: Text(
            'Delete Product',
            style: TextStyle(color: _primaryRed, fontFamily: 'PixelFont'),
          ),
          content: const Text(
            'Are you sure you want to delete this product?',
            style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontFamily: 'PixelFont')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore
                    .collection('products')
                    .doc(product.id)
                    .delete();
                Navigator.pop(context);
                // Refresh stats
                _loadDashboardStats();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
              ),
              child: const Text('Delete',
                  style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
      },
    );
  }

  // Show Product Actions
  void _showProductActions(DocumentSnapshot product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkBackground,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: _accentColor),
                title: const Text(
                  'Edit Product',
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editProduct(product);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: _primaryRed),
                title: const Text(
                  'Delete Product',
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProduct(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.green),
                title: Text(
                  product['availability']
                      ? 'Mark as Unavailable'
                      : 'Mark as Available',
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'PixelFont'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAvailability(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Toggle Availability
  Future<void> _toggleAvailability(DocumentSnapshot product) async {
    final bool currentAvailability =
        product.data().toString().contains('availability')
            ? product['availability']
            : true; // Default to true if field is missing
    await _firestore.collection('products').doc(product.id).update({
      'availability': !currentAvailability,
    });
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProduct()),
    ).then((_) {
      // Refresh stats when returning from the add product page
      _loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context), // Replace with the new drawer method
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.pink),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.pink,
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Stats summary section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DASHBOARD SUMMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                        'Categories', totalCategories, Icons.category),
                    _buildStatCard(
                      'Products',
                      totalProducts,
                      Icons.shopping_bag,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => YourProducts()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ORDERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOrderCard('Pending', pendingOrders, Icons.pending),
                    _buildOrderCard('Canceled', canceledOrders, Icons.cancel),
                    _buildOrderCard(
                        'Completed', completedOrders, Icons.check_circle),
                  ],
                ),
              ],
            ),
          ),

          // Products list section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('sellerId', isEqualTo: _auth.currentUser?.uid)
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory,
                            size: 64, color: Colors.pink.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No products available',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _navigateToAddProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Add Your First Product',
                            style: TextStyle(fontFamily: 'PixelFont'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'YOUR PRODUCTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                product['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PixelFont',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Price: ¥${product['price']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'PixelFont',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category: ${product['category']}',
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontFamily: 'PixelFont',
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: product['availability']
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                    ),
                                    child: Text(
                                      product['availability']
                                          ? 'Available'
                                          : 'Unavailable',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'PixelFont',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                color: Colors.white,
                                onPressed: () => _showProductActions(product),
                              ),
                              onTap: () => _showProductActions(product),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade800),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.cyan, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'PixelFont',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.pink,
                fontFamily: 'PixelFont',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String title, int count, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.cyan, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'PixelFont',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.pink,
              fontFamily: 'PixelFont',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
              gradient: LinearGradient(
                colors: [Colors.black, Colors.pink.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'SELLER DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to your control panel',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: Colors.pink),
            title: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white, 
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
            tileColor: Colors.pink.withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              // Already on dashboard
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory, color: Colors.pink),
            title: const Text(
              'Your Products',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => YourProducts()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add_box, color: Colors.pink),
            title: const Text(
              'Add Product',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              _navigateToAddProduct();
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.pink),
            title: const Text(
              'Order Status',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderStatus()),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.pink),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: Colors.pink),
            title: const Text(
              'Help',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help page
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.pink),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Navigate to login screen
            },
          ),
        ],
      ),
    );
  }
}
