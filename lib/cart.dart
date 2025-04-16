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
            style: TextStyle(color: Colors.white),
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
        title: const Text('Cart'),
        backgroundColor: Colors.black,
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
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final items = snapshot.data!.docs;
          final totalPrice = _calculateTotalPrice(items);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItems[item.id] ?? false;

                    return ListTile(
                      leading: Image.network(item['imageUrl']),
                      title: Text(
                        item['title'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${item['price']} (Qty: ${item['quantity']})',
                        style: const TextStyle(color: Colors.cyan),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                _selectedItems[item.id] = value ?? false;
                              });
                            },
                            activeColor: Colors.cyan,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await cartRef.doc(item.id).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item removed from cart.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                _selectedItems.remove(item.id);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total: \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedItems.values.contains(true)
                          ? () {
                              // Pass selected items and total price to CheckoutPage
                              final selectedItems = items
                                  .where((item) => _selectedItems[item.id] ?? false)
                                  .map((item) => {
                                        'title': item['title'],
                                        'price': item['price'],
                                        'quantity': item['quantity'],
                                        'imageUrl': item['imageUrl'],
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
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontSize: 16),
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

  // ✅ Helper method to calculate total price based on selected items
  double _calculateTotalPrice(List<QueryDocumentSnapshot> items) {
    double total = 0.0;
    for (var item in items) {
      if (_selectedItems[item.id] ?? false) {
        final price = item['price'] is num
            ? item['price'].toDouble()
            : double.tryParse(item['price'].toString()) ?? 0.0;
        final quantity = item['quantity'] is num
            ? item['quantity']
            : int.tryParse(item['quantity'].toString()) ?? 0;
        total += price * quantity;
      }
    }
    return total;
  }
}