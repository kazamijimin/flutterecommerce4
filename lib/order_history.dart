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
            color: Colors.white,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 64, color: Colors.pink.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view your orders',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.pink.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No $tabName orders',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'orderId': data['orderId'] ?? 'N/A',
            'orderDate': data['orderDate'] ?? 'N/A',
            'totalPrice': data['totalPrice'] ?? 0.0,
            'items': data['items'] ?? [],
            'status': data['status'] ?? tabName.toLowerCase(),
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, tabName);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String tabName) {
    final items = order['items'] as List<dynamic>;
    
    // Determine status color based on tab
    Color statusColor;
    switch (tabName) {
      case 'To Pay':
        statusColor = Colors.amber;
        break;
      case 'To Ship':
        statusColor = Colors.cyan;
        break;
      case 'To Receive':
        statusColor = Colors.blue;
        break;
      case 'To Review':
        statusColor = Colors.purple;
        break;
      case 'Return/Refund':
        statusColor = Colors.orange;
        break;
      case 'Cancellation':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xFFFF0077);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order['orderId']}',
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tabName,
                    style: TextStyle(
                      color: statusColor,
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Order info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${order['orderDate']}',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Total: \$${order['totalPrice'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.grey, height: 24),
          
          // Items list with images on left
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left-side image in a box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF0077).withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                      ? Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFFF0077),
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${item['price'] ?? '0'}',
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.cyan,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Qty: ${item['quantity'] ?? 1}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'PixelFont',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildActionButtons(order, tabName),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(Map<String, dynamic> order, String tabName) {
    // Create different action buttons based on the tab/status
    switch (tabName) {
      case 'To Pay':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => _cancelOrder(order['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'PixelFont')),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _payOrder(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0077),
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay Now', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      case 'To Ship':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _contactSeller(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('Contact Seller', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      case 'To Receive':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => _trackOrder(order['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyan,
                side: const BorderSide(color: Colors.cyan),
              ),
              child: const Text('Track', style: TextStyle(fontFamily: 'PixelFont')),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _confirmReceipt(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0077),
                foregroundColor: Colors.white,
              ),
              child: const Text('Received', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      case 'To Review':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _writeReview(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Write Review', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      case 'Return/Refund':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _trackRefundStatus(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Track Status', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      case 'Cancellation':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _deleteOrder(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete', style: TextStyle(fontFamily: 'PixelFont')),
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  // Action methods (these would be implemented with actual functionality)
  void _payOrder(String orderId) {
    // Navigate to payment page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to payment...'), backgroundColor: Colors.green),
    );
  }
  
  void _cancelOrder(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({'status': 'cancellation'});
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  void _contactSeller(String orderId) {
    // Navigate to message screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat with seller...'), backgroundColor: Colors.cyan),
    );
  }
  
  void _trackOrder(String orderId) {
    // Navigate to tracking page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading tracking information...'), backgroundColor: Colors.blue),
    );
  }
  
  void _confirmReceipt(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({'status': 'to review'});
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt confirmed'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  void _writeReview(String orderId) {
    // Navigate to review page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening review form...'), backgroundColor: Colors.purple),
    );
  }
  
  void _trackRefundStatus(String orderId) {
    // Show refund details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading refund details...'), backgroundColor: Colors.orange),
    );
  }
  
  void _deleteOrder(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .delete();
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted'), backgroundColor: Colors.grey),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}