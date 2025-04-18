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
                          ? () {
                              // Get only the selected items to pass to checkout
                              final selectedItems = items
                                  .where((item) => _selectedItems[item.id] ?? false)
                                  .map((item) {
                                    final data = item.data() as Map<String, dynamic>;
                                    return {
                                      'title': data['title'] ?? data['name'] ?? 'Unknown Item',
                                      'price': data['price'],
                                      'quantity': data['quantity'] ?? 1,
                                      'imageUrl': data['imageUrl'] ?? '',
                                    };
                                  })
                                  .toList();

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
}