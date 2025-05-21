import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Map<String, bool> _selectedItems = {};
  List<QueryDocumentSnapshot> _cartItems = []; // Store cart items
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _productCache = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // Load cart items once
  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    _productCache.clear(); // Clear cache when reloading
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        setState(() {
          _cartItems = snapshot.docs;
          _isLoading = false;
          
          // Initialize selected items
          for (var item in _cartItems) {
            if (!_selectedItems.containsKey(item.id)) {
              _selectedItems[item.id] = false;
            }
          }
        });
      } catch (e) {
        print('Error loading cart items: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  // Update quantity locally and in Firestore
  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': newQuantity});

      // Update local state without fetching from Firestore again
      setState(() {
        final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          // Update the quantity in the local data
          final currentItem = _cartItems[itemIndex];
          final updatedData = (currentItem.data() as Map<String, dynamic>)..['quantity'] = newQuantity;
          
          // Update the item in the list while maintaining the correct type
          _cartItems = List.from(_cartItems)
            ..[itemIndex] = currentItem;
        }
      });
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Delete item locally and from Firestore
  Future<void> _deleteItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .delete();

      // Update local state
      setState(() {
        _cartItems.removeWhere((item) => item.id == itemId);
        _selectedItems.remove(itemId);
      });
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your cart.',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'PixelFont',
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCartItems,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            )
          : _cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCartItems,
                        color: Colors.cyan,
                        backgroundColor: Colors.grey.shade900,
                        child: ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final itemData = item.data() as Map<String, dynamic>;
                            final isSelected = _selectedItems[item.id] ?? false;

                            // Get item title/name
                            final itemTitle = itemData['title'] ?? itemData['name'] ?? 'Unknown Item';

                            // Use the price as stored
                            final priceDisplay = itemData['price']?.toString() ?? '0.00';

                            final itemQuantity = itemData['quantity'] ?? 1;
                            final itemImageUrl = itemData['imageUrl'] ?? '';

                            // Game item card design that matches the image
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: Row(
                                children: [
                                  // Item image
                                  Container(
                                    width: 120,
                                    height: 80,
                                    child: Image.network(
                                      itemImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Item details
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'PixelFont', // Apply PixelFont
                                            ),
                                          ),
                                          Text(
                                            "$priceDisplay",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'PixelFont', // Apply PixelFont
                                            ),
                                          ),
                                          
                                          // Add stock availability message
                                          FutureBuilder<Map<String, dynamic>>(
                                            future: _getProductAvailability(itemData['productId'], itemTitle),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const SizedBox.shrink();
                                              }

                                              final productData = snapshot.data!;
                                              final stockCount = productData['stockCount'] ?? 0;
                                              final availability = productData['availability'] ?? true;
                                              final archived = productData['archived'] ?? false;
                                              
                                              if (!availability || archived) {
                                                return const Text(
                                                  "Not available/Out of Stock",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              } else if (stockCount <= 3 && stockCount > 0) {
                                                return const Text(
                                                  "Hurry, about to stock out!",
                                                  style: TextStyle(
                                                    color: Colors.amber,
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              } else if (stockCount <= 0) {
                                                return const Text(
                                                  "Not available/Out of Stock",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }
                                              
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Quantity controls and checkbox
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              if (itemQuantity > 1) {
                                                await _updateQuantity(item.id, itemQuantity - 1);
                                              }
                                            },
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                "-",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'PixelFont', // Apply PixelFont
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              itemQuantity.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'PixelFont', // Apply PixelFont
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              await _updateQuantity(item.id, itemQuantity + 1);
                                            },
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                "+",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'PixelFont', // Apply PixelFont
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white),
                                            ),
                                            child: Checkbox(
                                              value: isSelected,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedItems[item.id] = value ?? false;
                                                });
                                              },
                                              fillColor: MaterialStateProperty.resolveWith<Color>(
                                                (Set<MaterialState> states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Colors.transparent;
                                                  }
                                                  return Colors.transparent;
                                                },
                                              ),
                                              checkColor: Colors.white,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Confirm",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'PixelFont', // Apply PixelFont
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Add delete button
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _confirmDelete(context, item.id, itemTitle),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.red),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontFamily: 'PixelFont',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont', // Apply PixelFont
                                ),
                              ),
                              Text(
                                'PHP ${_calculateTotalPrice(_cartItems).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont', // Apply PixelFont
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _selectedItems.values.contains(true)
                                ? () async {
                                    // Check stock availability before proceeding to checkout
                                    bool hasOutOfStockItems = false;
                                    List<String> outOfStockItemNames = [];
                                    
                                    // Create a list to store selected items that are in stock
                                    final selectedItems = <Map<String, dynamic>>[];
                                    
                                    for (var item in _cartItems) {
                                      if (_selectedItems[item.id] ?? false) {
                                        final data = item.data() as Map<String, dynamic>;
                                        final itemName = data['title'] ?? data['name'] ?? 'Unknown Item';
                                        final productId = data['productId'];
                                        
                                        if (productId != null) {
                                          // Check product availability in Firestore
                                          final productDoc = await FirebaseFirestore.instance
                                              .collection('products')
                                              .doc(productId)
                                              .get();
                                          
                                          if (productDoc.exists) {
                                            final productData = productDoc.data() as Map<String, dynamic>;
                                            final stockCount = productData['stockCount'] ?? 0;
                                            final availability = productData['availability'] ?? true;
                                            final archived = productData['archived'] ?? false;
                                            
                                            if (!availability || archived || stockCount <= 0) {
                                              hasOutOfStockItems = true;
                                              outOfStockItemNames.add(itemName);
                                              continue; // Skip this item
                                            }
                                          }
                                        }
                                        
                                        // Only add in-stock items to the selectedItems list
                                        selectedItems.add({
                                          'title': itemName,
                                          'price': data['price'],
                                          'quantity': data['quantity'] ?? 1,
                                          'imageUrl': data['imageUrl'] ?? '',
                                          'productId': productId,
                                        });
                                      }
                                    }
                                    
                                    if (hasOutOfStockItems) {
                                      // Show error message for out of stock items
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cannot proceed with checkout. The following items are out of stock: ${outOfStockItemNames.join(", ")}',
                                            style: const TextStyle(fontFamily: 'PixelFont'),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    if (selectedItems.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No valid items selected for checkout',
                                            style: TextStyle(fontFamily: 'PixelFont'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    // If we reach here, all selected items are in stock
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutPage(
                                          totalPrice: _calculateTotalPrice(_cartItems),
                                          selectedItems: selectedItems,
                                        ),
                                      ),
                                    );
                                  }
                                : null, // Disable button if no items are selected
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Check Out',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'PixelFont', // Apply PixelFont
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper method to calculate total price based on selected items
  double _calculateTotalPrice(List<QueryDocumentSnapshot> items) {
    double total = 0.0;

    for (var item in items) {
      if (_selectedItems[item.id] ?? false) {
        final data = item.data() as Map<String, dynamic>;

        // Get the price and extract the numeric value
        final priceRaw = data['price'];
        double priceValue = 0.0;

        if (priceRaw != null) {
          String priceString = priceRaw.toString();
          // Extract numeric value from string like "PHP 100.0"
          priceString = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
          priceValue = double.tryParse(priceString) ?? 0.0;
        }

        // Get quantity
        final quantity = data['quantity'] ?? 1;
        final quantityInt = quantity is int
            ? quantity
            : int.tryParse(quantity.toString()) ?? 1;

        final itemTotal = priceValue * quantityInt;
        total += itemTotal;
      }
    }

    return total;
  }

  // Add this helper method to the _CartPageState class:
  Future<DocumentSnapshot?> _findProductByName(String name) async {
    try {
      // Query products collection by name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // If we found a matching product, update the cart item with the product ID
        // This will help for future queries
        final String productId = querySnapshot.docs.first.id;
        final user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          // Find this cart item by title and update it with the product ID
          final cartItems = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .where('title', isEqualTo: name)
              .get();
              
          if (cartItems.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cart')
                .doc(cartItems.docs.first.id)
                .update({'productId': productId});
          }
        }
        
        return querySnapshot.docs.first.reference.get();
      }
      return null;
    } catch (e) {
      print('Error finding product by name: $e');
      return null;
    }
  }

  // Then modify your helper method to avoid type issues:
  void _findAndUpdateProductId(String name) async {
    try {
      // Query products collection by name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // If we found a matching product, update the cart item with the product ID
        final String productId = querySnapshot.docs.first.id;
        final user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          // Find this cart item by title and update it with the product ID
          final cartItems = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .where('title', isEqualTo: name)
              .get();
              
          if (cartItems.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cart')
                .doc(cartItems.docs.first.id)
                .update({'productId': productId});
                
            // Optionally trigger a rebuild after updating
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    } catch (e) {
      print('Error finding product by name: $e');
    }
  }

  // Add this method to handle the delete confirmation
  void _confirmDelete(BuildContext context, String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Item',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Remove $itemName from your cart?',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Get user reference
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  // Delete the cart item
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('cart')
                      .doc(itemId)
                      .delete();
                  
                  // Update the selection map to remove the deleted item
                  setState(() {
                    _selectedItems.remove(itemId);
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed $itemName from cart',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error removing item: $e',
                          style: const TextStyle(fontFamily: 'PixelFont'),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to your _CartPageState class
  Future<Map<String, dynamic>> _getProductAvailability(String? productId, String itemTitle) async {
    // Check cache first
    if (productId != null && _productCache.containsKey(productId)) {
      return _productCache[productId]!;
    }

    try {
      if (productId == null) {
        // Try to find product ID
        final product = await _findProductByName(itemTitle);
        if (product != null && product.exists) {
          final data = product.data() as Map<String, dynamic>;
          _productCache[product.id] = data;
          return data;
        }
        return {'stockCount': 0, 'availability': false, 'archived': false};
      }

      // Fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) {
        return {'stockCount': 0, 'availability': false, 'archived': false};
      }

      final data = doc.data() as Map<String, dynamic>;
      // Cache the result
      _productCache[productId] = data;
      return data;
    } catch (e) {
      print('Error checking availability: $e');
      return {'stockCount': 0, 'availability': false, 'archived': false};
    }
  }
}