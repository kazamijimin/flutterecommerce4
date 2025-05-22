import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'category.dart';
import 'message.dart';
import 'profile.dart';
import 'cart.dart';
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
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Added horizontal margin
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.grey.shade800), // Added border
                        borderRadius: BorderRadius.circular(4), // Added rounded corners
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Changed to align at top
                        children: [
                          // Game image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            child: SizedBox(
                              width: 110, // Reduced width
                              height: 80,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade900,
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          
                          // Game details and controls
                          Expanded(
                            child: Container(
                              height: 80,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Title and price
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start, // Changed to start
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14, // Reduced font size
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'PixelFont',
                                          ),
                                          maxLines: 2, // Limit to 2 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          color: Colors.grey[800],
                                          child: Text(
                                            price,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11, // Reduced font size
                                              fontFamily: 'PixelFont',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 4),
                                  
                                  // Quantity controls and checkbox
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end, // Align to end
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min, // Make row take minimum space
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (_itemQuantities[item.id]! > 1) {
                                                    _itemQuantities[item.id] = _itemQuantities[item.id]! - 1;
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: 18, // Smaller width
                                                height: 18, // Smaller height
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  "—",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16, // Smaller font
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                "$quantity",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14, // Smaller font
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
                                              child: Container(
                                                width: 18, // Smaller width
                                                height: 18, // Smaller height
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  "+",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16, // Smaller font
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min, // Make row take minimum space
                                          children: [
                                            Container(
                                              width: 16, // Smaller checkbox
                                              height: 16, // Smaller checkbox
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
                                                fontSize: 10, // Smaller font
                                                fontFamily: 'PixelFont',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Delete button - made more compact
                                        InkWell(
                                          onTap: () => _confirmDelete(context, item.id, title),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.red, width: 0.5), // Thinner border
                                              borderRadius: BorderRadius.circular(2), // Smaller radius
                                            ),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10, // Smaller font
                                                fontFamily: 'PixelFont',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 212, 0, 0),
        unselectedItemColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        currentIndex: 1, // Set to 1 because Wishlist is the second item
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1: // Wishlist - already here
              break;
            case 2: // Message
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
              break;
            case 3: // Cart
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
              break;
            case 4: // Profile
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Method to show delete confirmation dialog
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
          'Remove $itemName from your wishlist?',
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
                  // Delete the wishlist item
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('wishlist')
                      .doc(itemId)
                      .delete();
                  
                  // Update state to remove the deleted item
                  setState(() {
                    _selectedItems.remove(itemId);
                    _itemQuantities.remove(itemId);
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed $itemName from wishlist',
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
}