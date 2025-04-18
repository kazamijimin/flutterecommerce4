import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final Map<String, bool> _selectedItems = {}; // Track selected items
  final Map<String, int> _itemQuantities = {}; // Track item quantities

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your wishlist.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');
    
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wishlist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'PixelFont',
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: wishlistRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your wishlist is empty.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final items = snapshot.data!.docs;
          
          // Initialize selected items and quantities for new documents
          for (var item in items) {
            if (!_selectedItems.containsKey(item.id)) {
              _selectedItems[item.id] = false;
            }
            if (!_itemQuantities.containsKey(item.id)) {
              _itemQuantities[item.id] = 1;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemData = item.data() as Map<String, dynamic>;
                    final isSelected = _selectedItems[item.id] ?? false;
                    final quantity = _itemQuantities[item.id] ?? 1;
                    
                    final title = itemData['title'] ?? 'Unknown Item';
                    final price = itemData['price'] ?? '0 PHP';
                    final imageUrl = itemData['imageUrl'] ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: Row(
                        children: [
                          // Game image
                          SizedBox(
                            width: 140,
                            height: 80,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Game details and controls
                          Expanded(
                            child: Container(
                              height: 80,
                              color: Colors.black,
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Title and price
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'PixelFont',
                                          ),
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          color: Colors.grey[800],
                                          child: Text(
                                            price,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'PixelFont',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 10),
                                  
                                  // Quantity controls and checkbox
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (_itemQuantities[item.id]! > 1) {
                                                  _itemQuantities[item.id] = _itemQuantities[item.id]! - 1;
                                                }
                                              });
                                            },
                                            child: const Text(
                                              "—",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              "$quantity",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'PixelFont',
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _itemQuantities[item.id] = _itemQuantities[item.id]! + 1;
                                              });
                                            },
                                            child: const Text(
                                              "+",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white),
                                              color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                                            ),
                                            child: Checkbox(
                                              value: isSelected,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedItems[item.id] = value ?? false;
                                                });
                                              },
                                              fillColor: MaterialStateProperty.all(Colors.transparent),
                                              checkColor: Colors.white,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Confirm",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'PixelFont',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Add to Cart button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    // Check if any items are selected
                    bool hasSelectedItems = _selectedItems.values.contains(true);
                    
                    if (!hasSelectedItems) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one item to add to cart.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Add selected items to cart
                    for (var item in items) {
                      if (_selectedItems[item.id] == true) {
                        final itemData = item.data() as Map<String, dynamic>;
                        final quantity = _itemQuantities[item.id] ?? 1;
                        
                        // Check if item already exists in cart
                        final existingCartItem = await cartRef
                            .where('title', isEqualTo: itemData['title'])
                            .limit(1)
                            .get();
                            
                        if (existingCartItem.docs.isNotEmpty) {
                          // Update quantity if item exists
                          final existingDoc = existingCartItem.docs.first;
                          final existingQty = (existingDoc.data()['quantity'] as int?) ?? 1;
                          await cartRef.doc(existingDoc.id).update({
                            'quantity': existingQty + quantity,
                          });
                        } else {
                          // Add new item to cart
                          await cartRef.add({
                            'title': itemData['title'],
                            'price': itemData['price'],
                            'imageUrl': itemData['imageUrl'],
                            'quantity': quantity,
                            'addedAt': FieldValue.serverTimestamp(),
                          });
                        }
                      }
                    }
                    
                    // Reset selections
                    setState(() {
                      for (var key in _selectedItems.keys) {
                        _selectedItems[key] = false;
                      }
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selected items added to cart.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}