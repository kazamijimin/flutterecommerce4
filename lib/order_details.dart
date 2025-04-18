import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderTablePage extends StatefulWidget {
  const OrderTablePage({Key? key}) : super(key: key);

  @override
  State<OrderTablePage> createState() => _OrderTablePageState();
}

class _OrderTablePageState extends State<OrderTablePage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }
Future<void> _fetchOrders() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();

      setState(() {
        _orders = snapshot.docs.map((doc) {
          final data = doc.data();
          data['orderId'] = data['orderId'] ?? doc.id; // Use saved orderId or fallback to doc.id
          return data;
        }).toList();
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to fetch orders: $e',
          style: const TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F1B),
      ),
      backgroundColor: const Color(0xFF0F0F1B),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
              ),
            )
          : _orders.isEmpty
              ? const Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white70,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>;
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${order['orderId'] ?? 'N/A'}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: ${order['orderDate'] ?? 'N/A'}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Payment: \$${order['totalPrice'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment Method: ${order['paymentMethod'] ?? 'N/A'}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shipping Address: ${order['shippingAddress'] ?? 'N/A'}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF0077)),
                      ),
                      child: Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Price: \$${item['price']} x ${item['quantity']}',
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 12,
                              color: Colors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}