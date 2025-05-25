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
    'Delivered',      // <-- Move Delivered before To Review
    'To Review',      // <-- Move To Review after Delivered
    'Return/Refund',
    'Cancellation'
  ];

  // Map for converting tab names to Firestore status values
  final Map<String, String> _tabToStatusMap = {
    'To Pay': 'to pay',
    'To Ship': 'to ship',
    'To Receive': 'to receive',
    'Delivered': 'delivered',      // <-- Delivered mapping
    'To Review': 'to review',      // <-- To Review mapping
    'Return/Refund': 'return/refund',
    'Cancellation': 'cancellation'
  };

  // Add this near the top of your _OrderHistoryState class
  void safeTabNavigate(int index) {
    try {
      if (index >= 0 && index < _tabController.length && mounted) {
        _tabController.animateTo(index);
      } else {
        print(
            'Tab index out of bounds: $index (length: ${_tabController.length})');
      }
    } catch (e) {
      print('Error navigating to tab: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      // Make sure _tabs is not empty before initializing TabController
      if (_tabs.isEmpty) {
        print('Warning: _tabs is empty during TabController initialization');
        _tabController = TabController(length: 1, vsync: this);
      } else {
        _tabController = TabController(length: _tabs.length, vsync: this);
      }
    } catch (e) {
      print('Error initializing TabController: $e');
      // Fallback to a single tab if there's an error
      _tabController = TabController(length: 1, vsync: this);
    }
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
      case 'delivered': // Changed from 'completed'
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
      case 'Delivered': // Changed from 'Completed'
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
      case 'delivered': // Changed from 'completed'
        return 'You have no delivered orders'; // Updated message
      case 'return/refund':
        return 'You have no return or refund requests';
      case 'cancellation':
        return 'You have no cancelled orders';
      default:
        return 'No orders found in this category';
    }
  }

  // Modify _buildOrderCard to display item-specific status
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
            // Status header (Same as before)
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
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Product image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: statusColor),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.network(
                                      item['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Product details with status indicator
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item['price']} × ${item['quantity']}',
                                            style: const TextStyle(
                                              fontFamily: 'PixelFont',
                                              fontSize: 14,
                                              color: Colors.cyan,
                                            ),
                                          ),
                                          // Status indicator for item
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: statusColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(status),
                                                  color: statusColor,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getStatusLabel(status),
                                                  style: TextStyle(
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 10,
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Product ID for reference
                                      if (item.containsKey('productId'))
                                        Text(
                                          'Product ID: ${item['productId'].toString().substring(0, 6)}...',
                                          style: const TextStyle(
                                            fontFamily: 'PixelFont',
                                            fontSize: 11,
                                            color: Colors.white38,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Order tracking timeline
                  const SizedBox(height: 16),
                  _buildOrderTimeline(status),

                  // Action button based on status
                  const SizedBox(height: 16),
                  _buildActionButton(order, status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Replace the _buildOrderTimeline method with this improved version with error handling
  Widget _buildOrderTimeline(String status) {
    try {
      // Print debug info
      print('Building timeline for status: $status');

      // Define the main steps in the order process
      final List<Map<String, dynamic>> steps = [
        {'status': 'to pay', 'label': 'Payment', 'icon': Icons.payment},
        {'status': 'to ship', 'label': 'Processing', 'icon': Icons.inventory},
        {
          'status': 'to receive',
          'label': 'Shipping',
          'icon': Icons.local_shipping
        },
        {
          'status': 'to review',
          'label': 'To Review',
          'icon': Icons.rate_review
        },
        {
          'status': 'delivered',
          'label': 'Delivered',
          'icon': Icons.check_circle
        },
      ];

      print('Steps length: ${steps.length}'); // Should be 5

      // Handle special statuses that don't fit in the timeline
      if (status == 'return/refund' || status == 'cancellation') {
        print('Special status detected: $status');
        // Special handling for these statuses
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                status == 'return/refund'
                    ? Icons.assignment_return
                    : Icons.cancel,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status == 'return/refund'
                      ? 'Return/Refund requested'
                      : 'Order cancelled',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Find the current step index safely
      int currentStepIndex =
          steps.indexWhere((step) => step['status'] == status);
      print('Current step index for $status: $currentStepIndex');

      if (currentStepIndex == -1) {
        // If status not found in steps, default to first step
        print('Status not found in steps, defaulting to first step');
        currentStepIndex = 0;
      }

      // Ensure List.generate never exceeds bounds
      final safeStepsLength = steps.length;
      print('Safe steps length: $safeStepsLength');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          // Timeline circles and connecting lines
          Row(
            children: List.generate(safeStepsLength, (index) {
              // Safety check for index
              if (index >= safeStepsLength) {
                print(
                    'WARNING: Index $index exceeds safe length $safeStepsLength');
                return const SizedBox.shrink(); // Return empty widget
              }

              // Determine colors based on completed/active/upcoming
              Color circleColor;
              Color lineColor;

              if (index < currentStepIndex) {
                // Completed step
                circleColor = const Color(0xFF00FF66);
                lineColor = const Color(0xFF00FF66);
              } else if (index == currentStepIndex) {
                // Current step
                circleColor = _getStatusColor(steps[index]['status'] as String);
                lineColor = Colors.grey.withOpacity(0.5);
              } else {
                // Upcoming step
                circleColor = Colors.grey.withOpacity(0.3);
                lineColor = Colors.grey.withOpacity(0.3);
              }

              return Expanded(
                child: Row(
                  children: [
                    // Status circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: circleColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: circleColor,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          steps[index]['icon'] as IconData,
                          color: circleColor,
                          size: 12,
                        ),
                      ),
                    ),

                    // Connecting line (except for last item)
                    if (index < safeStepsLength - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: lineColor,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          // Labels
          const SizedBox(height: 4),
          Row(
            children: List.generate(safeStepsLength, (index) {
              // Safety check for index
              if (index >= safeStepsLength) {
                print(
                    'WARNING: Index $index exceeds safe length $safeStepsLength in labels');
                return const SizedBox.shrink(); // Return empty widget
              }

              Color textColor;

              if (index < currentStepIndex) {
                textColor = Colors.white60;
              } else if (index == currentStepIndex) {
                textColor = _getStatusColor(steps[index]['status'] as String);
              } else {
                textColor = Colors.white38;
              }

              return Expanded(
                child: Center(
                  child: Text(
                    steps[index]['label'] as String,
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 10,
                      color: textColor,
                      fontWeight: index == currentStepIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } catch (e, stackTrace) {
      print('Error in _buildOrderTimeline: $e');
      print('Stack trace: $stackTrace');

      // Fallback UI in case of error
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.amber),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Order status information unavailable',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.amber,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
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
        return 'TO REVIEW';
      case 'delivered':
        return 'DELIVERED';
      case 'return/refund':
        return 'RETURN/REFUND';
      case 'cancellation':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  // Modify the _buildActionButton method to include a cancel option for "to pay" orders
  Widget _buildActionButton(Map<String, dynamic> order, String status) {
    final paymentMethod = order['paymentMethod'] as String? ?? '';
    final isCOD = paymentMethod == 'Cash on Delivery (COD)';

    // For COD orders that are in "to ship" status
    if (isCOD && status == 'to ship') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _viewOrderDetails(order),
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text(
                'TRACK ORDER',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0077),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          if (order['status'] == 'to ship') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(order),
                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                label: const Text(
                  'CANCEL ORDER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    late String buttonText;
    late Color buttonColor;
    late IconData buttonIcon;
    late VoidCallback onPressed;

    switch (status) {
      case 'to pay':
        // For "to pay" orders, show both Pay Now and Cancel buttons
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handlePayment(order),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text(
                  'PAY NOW',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(order),
                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                label: const Text(
                  'CANCEL ORDER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'to ship':
        // Show both View Details and Cancel Order buttons
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewOrderDetails(order),
                icon:
                    const Icon(Icons.visibility, size: 16, color: Colors.black),
                label: const Text(
                  'VIEW DETAILS',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0077),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(order),
                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                label: const Text(
                  'CANCEL ORDER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'to receive':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _trackShipment(order),
                icon: const Icon(Icons.local_shipping,
                    size: 16, color: Colors.black),
                label: const Text(
                  'TRACK ORDER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                label: const Text(
                  'CANCEL ORDER',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.grey,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You cannot cancel order at this stage.',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'to review':
        buttonText = 'WRITE REVIEW';
        buttonColor = const Color(0xFF00FF66);
        buttonIcon = Icons.rate_review;
        onPressed = () => _writeReview(order);
        break;
      case 'delivered':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Confirm order received
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Color(0xFF00FF66), width: 1),
                      ),
                      title: const Text(
                        'Order Received',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Color(0xFF00FF66),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Have you received your order?',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white70,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'NO',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              color: Colors.cyan,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF66),
                          ),
                          child: const Text(
                            'YES, RECEIVED',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await updateOrderStatus(order['documentId'], 'To Review');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order marked as received.',
                            style: TextStyle(fontFamily: 'PixelFont'),
                          ),
                          backgroundColor: Color(0xFF00FF66),
                        ),
                      );
                      safeTabNavigate(_tabs.indexOf('To Review'));
                    }
                  }
                },
                icon: const Icon(Icons.check_circle,
                    color: Colors.black, size: 16),
                label: const Text(
                  'ORDER RECEIVED',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReturnRefundDialog(order),
                icon: const Icon(Icons.assignment_return,
                    color: Colors.redAccent, size: 16),
                label: const Text(
                  'RETURN / REFUND',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
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
        icon: Icon(
          buttonIcon,
          color: Colors.black,
          size: 16, // <-- Add this line to make the icon black
        ),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
            color: Colors.black,
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

  // Add this method to show a confirmation dialog before cancelling
  void _showCancelConfirmation(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        title: const Text(
          'Cancel Order',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can only cancel orders in "To Pay" status.',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'NO, KEEP ORDER',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.cyan,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to handle the actual cancellation
  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    try {
      final documentId = order['documentId'];

      // Show loading indicator
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
              ),
              SizedBox(height: 16),
              Text(
                'Cancelling your order...',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );

      try {
        // Update order status to 'cancellation'
        await updateOrderStatus(documentId, 'Cancellation');

        // Dismiss loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Order cancelled successfully',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Navigate to the Cancellation tab
        if (mounted) {
          int cancellationIndex = -1;
          try {
            cancellationIndex = _tabs.indexOf('Cancellation');
          } catch (e) {
            print('Error finding Cancellation tab: $e');
          }
          safeTabNavigate(cancellationIndex);
        }
      } catch (e) {
        // Dismiss loading dialog if there's an error
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel order: $e',
                style: const TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _cancelOrder: $e');
      // Make sure dialog is dismissed
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

// Fix the _handlePayment method to properly handle COD orders
  void _handlePayment(Map<String, dynamic> order) async {
    try {
      final paymentMethod = order['paymentMethod'] as String? ?? '';
      final isCOD = paymentMethod.toLowerCase().contains('cod') ||
          paymentMethod.toLowerCase().contains('cash on delivery');

      // Show loading dialog
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0077)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Processing payment...',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \$${order['totalPrice'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      try {
        // Simulate payment processing delay
        await Future.delayed(const Duration(seconds: 2));

        // Update order status to 'to ship'
        final documentId = order['documentId'];
        await updateOrderStatus(documentId, 'To Ship');

        // Update payment details in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .doc(documentId)
              .update({
            'paymentStatus': 'completed',
            'paymentDate': DateTime.now().toIso8601String(),
            'paymentMethod':
                isCOD ? 'Cash on Delivery (COD)' : 'Online Payment',
          });
        }

        // Dismiss loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment successful! Your order will be processed shortly.',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Safely navigate to the "To Ship" tab
        if (mounted) {
          int toShipIndex = -1;
          try {
            toShipIndex = _tabs.indexOf('To Ship');
          } catch (e) {
            print('Error finding To Ship tab: $e');
            toShipIndex = -1;
          }

          safeTabNavigate(toShipIndex);
        }
      } catch (e) {
        print('Error in payment processing: $e');
        // Dismiss loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed: $e',
                style: const TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _handlePayment: $e');
      // Make sure dialog is dismissed if something went wrong
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

// Fix the updateOrderStatus method to handle special COD case
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Get the status value from your map
      String firestoreStatus =
          _tabToStatusMap[newStatus] ?? newStatus.toLowerCase();

      // 2. Get the order document first to check if it's COD
      final orderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final data = orderDoc.data();
        final paymentMethod = data?['paymentMethod'] as String? ?? '';
        final isCOD = paymentMethod.toLowerCase().contains('cod') ||
            paymentMethod.toLowerCase().contains('cash on delivery');

        // 3. Update in user's orders collection with special handling for COD
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({
          'status': firestoreStatus,
          // For COD orders going to 'to ship', mark payment as completed automatically
          if (isCOD && firestoreStatus == 'to ship') ...{
            'paymentStatus': 'completed',
            'paymentDate': DateTime.now().toIso8601String(),
          }
        });

        // 4. Update in global orders collection if needed
        final orderRef = await FirebaseFirestore.instance
            .collection('orders')
            .where('orderId', isEqualTo: data?['orderId'])
            .limit(1)
            .get();

        if (orderRef.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderRef.docs.first.id)
              .update({
            'status': firestoreStatus,
            if (isCOD && firestoreStatus == 'to ship') ...{
              'paymentStatus': 'completed',
              'paymentDate': DateTime.now().toIso8601String(),
            }
          });
        }

        // 5. Show success message if context is still valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order status updated to $newStatus',
                style: const TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating order status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update order status: $e',
              style: const TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showReturnRefundDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        title: Row(
          children: const [
            Icon(Icons.assignment_return, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Return / Refund Request',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to request a return or refund for this order?\n\n'
          'This action will move your order to the Return/Refund tab and notify the seller.',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'NO, KEEP ORDER',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.cyan,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading dialog while updating
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  backgroundColor: Color(0xFF1A1A2E),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Submitting your request...',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              await updateOrderStatus(order['documentId'], 'Return/Refund');
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Return/Refund requested.',
                      style: TextStyle(fontFamily: 'PixelFont'),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                safeTabNavigate(_tabs.indexOf('Return/Refund'));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              'YES, REQUEST',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viewing return/refund request...'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _viewOrderDetails(order);
    } catch (e) {
      print('Error in _viewReturnRequest: $e');
    }
  }

  // Add this method to your OrderHistory class to update order status
}
