import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late TabController _tabController;
  bool _isLoading = false;
  
  // Theme colors for cyberpunk style
  final Color _neonPink = const Color(0xFFFF2A6D);
  final Color _neonBlue = const Color(0xFF05D9E8);
  final Color _neonPurple = const Color(0xFFA742B5);
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkCardBg = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add Product
  Future<void> _addProduct() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    
    String selectedCategory = 'Electronics';
    List<String> categories = ['Electronics', 'Fashion', 'Home', 'Beauty', 'Games'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _darkCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: _neonBlue, width: 2),
              ),
              title: Text('ADD PRODUCT', 
                style: TextStyle(
                  color: _neonPink,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _neonBlue.withOpacity(0.5)),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: _neonBlue, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'UPLOAD IMAGE',
                                    style: TextStyle(color: _neonBlue, fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameController, 'Product Name', Icons.shopping_bag),
                    const SizedBox(height: 12),
                    _buildTextField(priceController, 'Price', Icons.attach_money, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(stockController, 'Stock', Icons.inventory, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _neonPurple.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        dropdownColor: _darkCardBg,
                        value: selectedCategory,
                        isExpanded: true,
                        underline: Container(),
                        style: TextStyle(color: _neonPurple),
                        icon: Icon(Icons.arrow_drop_down, color: _neonPurple),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) {
                      // Close dialog first
                      Navigator.pop(context);
                      
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        await _firestore.collection('products').add({
                          'name': nameController.text,
                          'price': double.parse(priceController.text),
                          'description': descriptionController.text,
                          'category': selectedCategory,
                          'stock': int.tryParse(stockController.text) ?? 0,
                          'image': _selectedImage?.path ?? '',
                          'availability': true,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product added successfully!'),
                            backgroundColor: _neonBlue,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding product: $e'),
                            backgroundColor: _neonPink,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                          _selectedImage = null;
                        });
                      }
                    }
                  },
                  child: const Text('ADD'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Custom TextField Widget
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _neonBlue),
        prefixIcon: Icon(icon, color: _neonBlue),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neonBlue.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neonBlue),
        ),
        filled: true,
        fillColor: Colors.black38,
      ),
    );
  }

  // Edit Product
  Future<void> _editProduct(DocumentSnapshot product) async {
  final TextEditingController nameController = TextEditingController(text: product['name']);
  final TextEditingController priceController = TextEditingController(text: product['price'].toString());
  final TextEditingController descriptionController = TextEditingController(
    text: product.data().toString().contains('description') ? product['description'] : '',
  );
  final TextEditingController stockController = TextEditingController(
    text: product.data().toString().contains('stock') ? product['stock'].toString() : '0',
  );

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: _darkCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: _neonPurple, width: 2),
        ),
        title: Text('EDIT PRODUCT', style: TextStyle(color: _neonPurple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Product Name', Icons.shopping_bag),
              const SizedBox(height: 12),
              _buildTextField(priceController, 'Price', Icons.attach_money, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(stockController, 'Stock', Icons.inventory, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await _firestore.collection('products').doc(product.id).update({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'description': descriptionController.text,
                  'stock': int.tryParse(stockController.text) ?? 0,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product updated successfully!'),
                    backgroundColor: _neonPurple,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating product: $e'),
                    backgroundColor: _neonPink,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('UPDATE'),
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
          backgroundColor: _darkCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: _neonPink, width: 2),
          ),
          title: const Text('DELETE PRODUCT', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${product['name']}"?',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await _firestore.collection('products').doc(product.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  // Toggle Product Availability
  Future<void> _toggleAvailability(DocumentSnapshot product) async {
    final bool currentAvailability = product.data().toString().contains('availability')
        ? product['availability']
        : true;
        
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestore.collection('products').doc(product.id).update({
        'availability': !currentAvailability,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentAvailability 
                ? 'Product marked as unavailable' 
                : 'Product marked as available'
          ),
          backgroundColor: _neonBlue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: _neonPink,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'CYBER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            Text(
              'SHOP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.5,
                color: _neonPink,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: _neonBlue),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: _neonBlue),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neonPink,
          labelColor: _neonPink,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'PRODUCTS'),
            Tab(text: 'ORDERS'),
            Tab(text: 'STATS'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _darkBg,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://i.pinimg.com/originals/b0/b1/68/b0b168a5dd2b9f160279655554e60087.jpg',
                ),
                opacity: 0.2,
                fit: BoxFit.cover,
              ),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildProductsTab(),
              _buildOrdersTab(),
              _buildStatsTab(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_neonBlue),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _neonPink,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: _darkBg.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: _neonBlue.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true),
            _buildNavItem(Icons.analytics_outlined, 'Analytics', false),
            _buildNavItem(Icons.account_circle_outlined, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? _neonPink : Colors.white60,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? _neonPink : Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Products Tab
  Widget _buildProductsTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('products').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(color: _neonBlue),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _buildEmptyState(
          'No products available',
          'Tap the + button to add your first product',
          Icons.shopping_bag_outlined,
        );
      }

      final products = snapshot.data!.docs;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final bool isAvailable = product.data().toString().contains('availability')
              ? product['availability']
              : true;

          // Safely access the 'stock' field with a default value
          final stock = product.data().toString().contains('stock')
              ? product['stock']
              : 0;

          // Safely access the 'category' field with a default value
          final category = product.data().toString().contains('category')
              ? product['category']
              : 'Uncategorized';

          // Safely access the 'description' field with a default value
          final description = product.data().toString().contains('description')
              ? product['description']
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _darkCardBg.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isAvailable ? _neonBlue : _neonPink).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: (isAvailable ? _neonBlue : _neonPink).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _neonPink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _neonPink, width: 1),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Category: $category',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Description: $description',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _neonBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${product['price']}',
                              style: TextStyle(
                                color: _neonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock: $stock',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    color: _darkCardBg,
                    icon: Icon(Icons.more_vert, color: _neonPurple),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: _neonBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text('Edit', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isAvailable ? Icons.visibility_off : Icons.visibility,
                              color: isAvailable ? _neonPink : _neonBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAvailable ? 'Mark as Unavailable' : 'Mark as Available',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editProduct(product);
                          break;
                        case 'toggle':
                          _toggleAvailability(product);
                          break;
                        case 'delete':
                          _deleteProduct(product);
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  // Orders Tab (Placeholder)
  Widget _buildOrdersTab() {
    return _buildEmptyState(
      'Coming Soon',
      'Order management will be available in the next update',
      Icons.shopping_cart_outlined
    );
  }

  // Stats Tab (Placeholder)
  Widget _buildStatsTab() {
    return _buildEmptyState(
      'Analytics Dashboard',
      'Sales statistics will be available soon',
      Icons.bar_chart
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _darkCardBg.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _neonPurple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: _neonPurple, size: 50),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}