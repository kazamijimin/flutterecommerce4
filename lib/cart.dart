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
  final Map<String, bool> _selectedItems = {}; // Track selected items

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
              fontFamily: 'PixelFont', // Apply PixelFont
            ),
          ),
        ),
      );
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'PixelFont', // Apply PixelFont
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
            );
          }

          final items = snapshot.data!.docs;

          // Initialize selected items for new documents if not already set
          for (var item in items) {
            if (!_selectedItems.containsKey(item.id)) {
              _selectedItems[item.id] = false;
            }
          }

          // Calculate the total price here based on current selections
          final totalPrice = _calculateTotalPrice(items);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                                  FutureBuilder<DocumentSnapshot>(
                                    future: itemData['productId'] != null 
                                        ? FirebaseFirestore.instance
                                            .collection('products')
                                            .doc(itemData['productId'])
                                            .get()
                                        : null, // Use null instead of _findProductByName for now
                                    builder: (context, snapshot) {
                                      // Debug: Print productId to verify it exists
                                      print('Product ID for ${itemTitle}: ${itemData['productId']}');
                                      
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Text(
                                          "Checking availability...",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'PixelFont',
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      
                                      // If we don't have a product ID, try looking up the product by name
                                      if (itemData['productId'] == null) {
                                        // Trigger product lookup but don't wait for result in builder
                                        _findAndUpdateProductId(itemTitle);
                                        
                                        return const Text(
                                          "Product information unavailable",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'PixelFont',
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      
                                      if (snapshot.hasError) {
                                        print('Error loading product: ${snapshot.error}');
                                        return const Text(
                                          "Error checking stock",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'PixelFont',
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      
                                      if (snapshot.hasData && snapshot.data!.exists) {
                                        final productData = snapshot.data!.data() as Map<String, dynamic>;
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
                                        await cartRef.doc(item.id).update({
                                          'quantity': itemQuantity - 1,
                                        });
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
                                      await cartRef.doc(item.id).update({
                                        'quantity': itemQuantity + 1,
                                      });
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
                            ],
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    );
                  },
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
                          'PHP ${totalPrice.toStringAsFixed(2)}',
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
                              
                              for (var item in items) {
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
                                    totalPrice: totalPrice,
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
          );
        },
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
}