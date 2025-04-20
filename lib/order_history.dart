import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key}) : super(key: key);

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'To Pay',
    'To Ship',
    'To Receive',
    'To Review',
    'Completed',  // Added Completed tab
    'Return/Refund',
    'Cancellation'
  ];
  
  // Map for converting tab names to Firestore status values
  final Map<String, String> _tabToStatusMap = {
    'To Pay': 'to pay',
    'To Ship': 'to ship',
    'To Receive': 'to receive',
    'To Review': 'to review',
    'Completed': 'completed',  // Added mapping for Completed
    'Return/Refund': 'return/refund',
    'Cancellation': 'cancellation'
  };

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

    // Convert tab name to status format using the map
    String statusFilter = _tabToStatusMap[tabName] ?? tabName.toLowerCase();

    // Fetch orders from Firestore based on the status
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('status', isEqualTo: statusFilter)
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
                Icon(
                  _getStatusIcon(statusFilter),
                  size: 48,
                  color: _getStatusColor(statusFilter).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No $tabName orders',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(statusFilter),
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
            'status': data['status'] ?? statusFilter,
            'documentId': doc.id, // Store document ID for reference
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, statusFilter);
          },
        );
      },
    );
  }

  // Helper function to get status-specific icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'to pay':
        return Icons.payment;
      case 'to ship':
        return Icons.inventory;
      case 'to receive':
        return Icons.local_shipping;
      case 'to review':
        return Icons.rate_review;
      case 'return/refund':
        return Icons.assignment_return;
      case 'cancellation':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.shopping_bag;
    }
  }

// Helper function to get status-specific color
  Color _getStatusColor(String status) {
    // Convert status to tab format for consistency
    String tabStatus = status;
    _tabToStatusMap.forEach((key, value) {
      if (value == status) {
        tabStatus = key;
      }
    });
    
    switch (tabStatus) {
      case 'To Pay':
        return Colors.orange;
      case 'To Ship':
        return const Color(0xFFFF0077); // Pink
      case 'To Receive':
        return const Color(0xFF00E5FF); // Cyan
      case 'To Review':
        return const Color(0xFFFFCC00); // Yellow
      case 'Completed':
        return const Color(0xFF00FF66); // Green
      case 'Return/Refund':
        return Colors.redAccent;
      case 'Cancellation':
        return Colors.red;
      default:
        return const Color(0xFFFF0077);
    }
  }

  // Helper function to get empty state messages
  String _getEmptyStateMessage(String status) {
    switch (status) {
      case 'to pay':
        return 'You have no orders waiting for payment';
      case 'to ship':
        return 'You have no orders waiting to be shipped';
      case 'to receive':
        return 'You have no orders in transit';
      case 'to review':
        return 'You have no orders waiting for review';
      case 'completed':
        return 'You have no completed orders';
      case 'return/refund':
        return 'You have no return or refund requests';
      case 'cancellation':
        return 'You have no cancelled orders';
      default:
        return 'No orders found in this category';
    }
  }

  // Updated order card with status indicators
  Widget _buildOrderCard(Map<String, dynamic> order, String currentTab) {
    final items = order['items'] as List<dynamic>;
    final status = order['status'] as String;
    final Color statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () {
        // Navigate to the OrderDetailsPage when card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(
              order: {
                ...order,
                'status': status,
              },
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF1A1A2E),
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: statusColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order ID: ${order['orderId']}',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Order details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
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
                              border: Border.all(color: statusColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  );
                                },
                              ),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

                  // Action button based on status
                  const SizedBox(height: 12),
                  _buildActionButton(order, status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper to get a user-friendly status label
  String _getStatusLabel(String status) {
    switch (status) {
      case 'to pay':
        return 'PAYMENT PENDING';
      case 'to ship':
        return 'PROCESSING';
      case 'to receive':
        return 'SHIPPING';
      case 'to review':
        return 'DELIVERED';
      case 'completed':
        return 'COMPLETED';
      case 'return/refund':
        return 'RETURN/REFUND';
      case 'cancellation':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  // Add a context-appropriate action button
  Widget _buildActionButton(Map<String, dynamic> order, String status) {
    late String buttonText;
    late Color buttonColor;
    late IconData buttonIcon;
    late VoidCallback onPressed;

    switch (status) {
      case 'to pay':
        buttonText = 'PAY NOW';
        buttonColor = Colors.orange;
        buttonIcon = Icons.payment;
        onPressed = () => _handlePayment(order);
        break;
      case 'to ship':
        buttonText = 'VIEW DETAILS';
        buttonColor = const Color(0xFFFF0077);
        buttonIcon = Icons.visibility;
        onPressed = () => _viewOrderDetails(order);
        break;
      case 'to receive':
        buttonText = 'TRACK ORDER';
        buttonColor = const Color(0xFF00E5FF);
        buttonIcon = Icons.local_shipping;
        onPressed = () => _trackShipment(order);
        break;
      case 'to review':
        buttonText = 'WRITE REVIEW';
        buttonColor = const Color(0xFF00FF66);
        buttonIcon = Icons.rate_review;
        onPressed = () => _writeReview(order);
        break;
      case 'completed':  // ADD THIS CASE
        buttonText = 'ORDER DETAILS';
        buttonColor = const Color(0xFF00FF66);  // Green
        buttonIcon = Icons.check_circle;
        onPressed = () => _viewOrderDetails(order);
        break;
      case 'return/refund':
        buttonText = 'VIEW REQUEST';
        buttonColor = Colors.redAccent;
        buttonIcon = Icons.assignment_return;
        onPressed = () => _viewReturnRequest(order);
        break;
      case 'cancellation':
        buttonText = 'VIEW DETAILS';
        buttonColor = Colors.red;
        buttonIcon = Icons.info_outline;
        onPressed = () => _viewOrderDetails(order);
        break;
      default:
        buttonText = 'VIEW DETAILS';
        buttonColor = const Color(0xFFFF0077);
        buttonIcon = Icons.visibility;
        onPressed = () => _viewOrderDetails(order);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(buttonIcon, size: 16),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  // Action handlers
  void _handlePayment(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing payment...'),
        backgroundColor: Colors.orange,
      ),
    );
    _viewOrderDetails(order);
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
          order: order,
        ),
      ),
    );
  }

  void _trackShipment(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking your order...'),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
    _viewOrderDetails(order);
  }

  void _writeReview(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening review form...'),
        backgroundColor: Color(0xFF00FF66),
      ),
    );
    _viewOrderDetails(order);
  }

  void _viewReturnRequest(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing return/refund request...'),
        backgroundColor: Colors.redAccent,
      ),
    );
    _viewOrderDetails(order);
  }
}
