import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key}) : super(key: key);

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'To Pay',
    'To Ship',
    'To Receive',
    'To Review',
    'Return/Refund',
    'Cancellation'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the TabController
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    // Dispose of the TabController
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F1B),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFFF0077),
          labelColor: const Color(0xFFFF0077),
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
          ),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      backgroundColor: const Color(0xFF0F0F1B),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildOrderList(tab)).toList(),
      ),
    );
  }

  Widget _buildOrderList(String tabName) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view your orders.',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    // Fetch orders from Firestore based on the tab name (status)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('status', isEqualTo: tabName.toLowerCase()) // Match status with tab name
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $tabName orders',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'orderId': data['orderId'] ?? 'N/A',
            'orderDate': data['orderDate'] ?? 'N/A',
            'totalPrice': data['totalPrice'] ?? 0.0,
            'items': data['items'] ?? [],
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
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
              'Order ID: ${order['orderId']}',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: ${order['orderDate']}',
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