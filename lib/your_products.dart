import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product.dart'; // Import the AddProduct widget for navigation
import 'seller_dashboard.dart'; // Import for navigation
import 'order_status.dart'; // Import for navigation
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

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
    final TextEditingController imageUrlController = TextEditingController(text: data['imageUrl'] ?? '');
    
    // Check if availability exists, default to true if it doesn't
    bool availability = data.containsKey('availability') ? data['availability'] : true;
    String? previewImageUrl = data['imageUrl'];
    bool isImageValid = previewImageUrl != null && previewImageUrl.isNotEmpty;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EDIT PRODUCT',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.pink, thickness: 1),
                    const SizedBox(height: 16),
                    // Image Preview and Editor
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.withOpacity(0.5)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isImageValid)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                previewImageUrl!,
                                fit: BoxFit.cover,
                                height: double.infinity,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  setState(() => isImageValid = false);
                                  return _buildImagePlaceholder();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.cyan,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            _buildImagePlaceholder(),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.photo_library, color: Colors.pink),
                                    onPressed: () async {
                                      final url = await _pickAndUploadImage(context);
                                      if (url != null) {
                                        setState(() {
                                          previewImageUrl = url;
                                          isImageValid = true;
                                        });
                                      }
                                    },
                                    tooltip: 'Choose from Gallery',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.link, color: Colors.cyan),
                                    onPressed: () {
                                      _showImageUrlInputDialog(
                                        context, 
                                        imageUrlController,
                                        (url) {
                                          setState(() {
                                            previewImageUrl = url;
                                            isImageValid = url.isNotEmpty;
                                          });
                                        }
                                      );
                                    },
                                    tooltip: 'Enter Image URL',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Form Fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: const TextStyle(color: Colors.cyan),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.pink, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.cyan, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: priceController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Price',
                                labelStyle: const TextStyle(color: Colors.cyan),
                                prefixText: '¥ ',
                                prefixStyle: const TextStyle(color: Colors.cyan),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.pink, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.cyan, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: descriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                                labelStyle: const TextStyle(color: Colors.cyan),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.pink, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.cyan, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Availability toggle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pink),
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Product Visibility:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'PixelFont',
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        availability ? 'VISIBLE' : 'HIDDEN',
                                        style: TextStyle(
                                          color: availability ? Colors.green : Colors.red,
                                          fontFamily: 'PixelFont',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: availability,
                                        onChanged: (bool value) {
                                          setState(() {
                                            availability = value;
                                          });
                                        },
                                        activeColor: Colors.green,
                                        activeTrackColor: Colors.green.withOpacity(0.4),
                                        inactiveThumbColor: Colors.red,
                                        inactiveTrackColor: Colors.red.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                'imageUrl': previewImageUrl,
                                'availability': availability,
                                'lastUpdated': FieldValue.serverTimestamp(),
                              });
                              
                              Navigator.pop(context);
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Product updated successfully!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.save),
                              SizedBox(width: 8),
                              Text(
                                'SAVE CHANGES',
                                style: TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  // Helper method to build image placeholder
  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 64, color: Colors.grey.withOpacity(0.5)),
        const SizedBox(height: 8),
        const Text(
          'NO IMAGE AVAILABLE',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: 'PixelFont',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // Method to show image URL input dialog
  void _showImageUrlInputDialog(BuildContext context, TextEditingController controller, Function(String) onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'EDIT IMAGE URL',
            style: TextStyle(
              color: Colors.pink,
              fontFamily: 'PixelFont',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Image URL',
              labelStyle: const TextStyle(color: Colors.cyan),
              hintText: 'Enter image URL here',
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.pink),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
            ),
            onChanged: (value) {
              // You could add live preview here in a more complex implementation
            },
          ),
          actions: [
            TextButton(
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm(controller.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              child: const Text(
                'CONFIRM',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add this method to handle image picking and uploading
  Future<String?> _pickAndUploadImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return null;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 16),
                Text(
                  'UPLOADING...',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Upload image to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('products/$fileName');
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      
      // Get download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Close loading dialog
      Navigator.pop(context);
      
      return downloadUrl;
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}