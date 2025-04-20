import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product.dart'; // Import the AddProduct widget for navigation
import 'seller_dashboard.dart'; // Import for navigation
import 'order_status.dart'; // Import for navigation

class YourProducts extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  YourProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(context), // Add the drawer here
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'YOUR PRODUCTS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.pink),
      ),
      body: Column(
        children: [
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
                        Icon(Icons.inventory, size: 64, color: Colors.pink.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'NO PRODUCTS AVAILABLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Use direct navigation instead of named route
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddProduct()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'ADD YOUR FIRST PRODUCT',
                            style: TextStyle(fontFamily: 'PixelFont'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                // Grid view to match the image design
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      // Safely get the data
                      final data = product.data() as Map<String, dynamic>;
                      // Safely access the archived field
                      final bool isArchived = data.containsKey('archived') ? data['archived'] : false;
                      
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(7),
                                          topRight: Radius.circular(7),
                                        ),
                                        child: data.containsKey('imageUrl') && data['imageUrl'] != null
                                            ? Image.network(
                                                data['imageUrl'],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.grey[900],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 32,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[900],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                      if (isArchived)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(7),
                                              topRight: Radius.circular(7),
                                            ),
                                          ),
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.red),
                                              ),
                                              child: const Text(
                                                'ARCHIVED',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isArchived ? Colors.grey[900] : Colors.black,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(7),
                                      bottomRight: Radius.circular(7),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Product',
                                        style: TextStyle(
                                          color: isArchived ? Colors.grey : Colors.white,
                                          fontFamily: 'PixelFont',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '¥${data['price'] ?? '0'}',
                                        style: TextStyle(
                                          color: isArchived ? Colors.grey[600] : Colors.cyan,
                                          fontFamily: 'PixelFont',
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.edit,
                                            color: Colors.cyan,
                                            onPressed: () => _showEditProductDialog(context, product),
                                          ),
                                          _buildActionButton(
                                            icon: data.containsKey('availability') && data['availability'] != null 
                                                ? (data['availability'] ? Icons.visibility : Icons.visibility_off)
                                                : Icons.visibility,
                                            color: data.containsKey('availability') && data['availability'] != null
                                                ? (data['availability'] ? Colors.green : Colors.red)
                                                : Colors.green,
                                            onPressed: () => _toggleAvailabilityStatus(product.id, 
                                                data.containsKey('availability') ? data['availability'] : true),
                                          ),
                                          _buildActionButton(
                                            icon: isArchived ? Icons.unarchive : Icons.archive,
                                            color: isArchived ? Colors.green : Colors.amber,
                                            onPressed: () => _toggleArchiveStatus(product.id, isArchived),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Availability indicator
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                data.containsKey('availability') && data['availability'] != null 
                                    ? (data['availability'] ? Icons.visibility : Icons.visibility_off)
                                    : Icons.visibility,
                                color: data.containsKey('availability') && data['availability'] != null
                                    ? (data['availability'] ? Colors.green : Colors.red)
                                    : Colors.green,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Bottom "Add Product" button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProduct()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'ADD NEW PRODUCT',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the drawer/hamburger menu
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
                  'SELLER MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your products & orders',
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
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SellerDashboard()),
              );
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
              // Already on this page
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProduct()),
              );
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
  
  // Helper method to build small action buttons
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(
          icon,
          color: color,
          size: 14,
        ),
      ),
    );
  }
  
  // Method to toggle archive status
  Future<void> _toggleArchiveStatus(String productId, bool currentStatus) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'archived': !currentStatus,
      });
    } catch (e) {
      print('Error toggling archive status: $e');
    }
  }
  
  // Method to toggle availability status
  Future<void> _toggleAvailabilityStatus(String productId, bool currentStatus) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'availability': !currentStatus,
      });
    } catch (e) {
      print('Error toggling availability status: $e');
    }
  }
  
  // Method to show edit product dialog
  void _showEditProductDialog(BuildContext context, DocumentSnapshot product) {
    // Safely get the data as Map
    final data = product.data() as Map<String, dynamic>;
    
    final TextEditingController nameController = TextEditingController(text: data['name'] ?? '');
    final TextEditingController priceController = TextEditingController(text: (data['price'] ?? '0').toString());
    final TextEditingController descriptionController = TextEditingController(text: data['description'] ?? '');
    
    // Check if availability exists, default to true if it doesn't
    bool availability = data.containsKey('availability') ? data['availability'] : true;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                'EDIT PRODUCT',
                style: TextStyle(
                  color: Colors.pink,
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.cyan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Availability toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Availability:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        Switch(
                          value: availability,
                          onChanged: (bool value) {
                            setState(() {
                              availability = value;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Validate price is a number
                      double price;
                      try {
                        price = double.parse(priceController.text);
                      } catch (e) {
                        price = 0; // Default value if parsing fails
                      }
                      
                      await _firestore.collection('products').doc(product.id).update({
                        'name': nameController.text,
                        'price': price,
                        'description': descriptionController.text,
                        'availability': availability,
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });
                      
                      Navigator.pop(context);
                    } catch (e) {
                      // Show error snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}