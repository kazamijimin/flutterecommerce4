import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seller_dashboard.dart';
import 'your_products.dart';
import 'add_product.dart';
import 'revenue_graph.dart'; // Import the RevenueGraph screen

class OrderStatus extends StatelessWidget {
  const OrderStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: _buildDrawer(context), // Add the drawer here
      appBar: AppBar(
        title: const Text(
          'ORDER STATUS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Sales summary - fixed at the top, NOT part of the scrollable content
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF333355),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALES SUMMARY',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('orders').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF0077),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        'No sales data available',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    }

                    // Calculate statistics
                    final orders = snapshot.data!.docs;
                    int totalOrders = orders.length;
                    double totalRevenue = 0;

                    // Count status types
                    int toShip = 0;
                    int toDeliver = 0;
                    int delivered = 0;
                    int canceled = 0;

                    for (var order in orders) {
                      final data = order.data() as Map<String, dynamic>;

                      // Add to total revenue
                      if (data.containsKey('totalPrice')) {
                        totalRevenue +=
                            double.parse(data['totalPrice'].toString());
                      }

                      // Count by status
                      final status =
                          data['status']?.toString().toLowerCase() ?? '';
                      switch (status) {
                        case 'to ship':
                          toShip++;
                          break;
                        case 'to deliver':
                          toDeliver++;
                          break;
                        case 'delivered':
                          delivered++;
                          break;
                        case 'canceled':
                          canceled++;
                          break;
                      }
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatTile(
                                'Total Orders',
                                totalOrders.toString(),
                                const Color(0xFFFF0077)),
                            _buildStatTile(
                                'Total Revenue',
                                '₱${totalRevenue.toStringAsFixed(2)}',
                                const Color(0xFF00FF66)),
                            _buildStatTile('Delivered', delivered.toString(),
                                const Color(0xFF00FF66)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatTile('To Ship', toShip.toString(),
                                const Color(0xFF00F0FF)),
                            _buildStatTile('To Deliver', toDeliver.toString(),
                                const Color(0xFFFFCC00)),
                            _buildStatTile('Canceled', canceled.toString(),
                                const Color(0xFFFF3366)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Scrollable orders list in an Expanded widget
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D0D0D),
                    Colors.black,
                  ],
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  // Your existing order list StreamBuilder code
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: const Color(0xFFFF0077),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'LOADING ORDERS...',
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

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: const Color(0xFFFF0077).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'NO ORDERS FOUND',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Orders will appear here',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      // existing order list item rendering code
                      final order = orders[index];
                      final orderData = order.data() as Map<String, dynamic>;

                      // Safely handle the items field
                      final items = orderData['items'] as List<dynamic>? ?? [];

                      // Determine status color
                      // Determine status color
                      Color statusColor;
                      final status = orderData['status'] ?? 'Unknown';

                      // Convert to consistent format for comparison
                      String statusLower = status.toString().toLowerCase();

                      switch (statusLower) {
                        case 'to pay':
                          statusColor = Colors.orange; // Orange
                          break;
                        case 'to ship':
                          statusColor = const Color(0xFFFF0077); // Pink
                          break;
                        case 'to receive':
                          statusColor = const Color(0xFF00F0FF); // Cyan
                          break;
                        case 'to review':
                          statusColor = const Color(0xFFFFCC00); // Yellow
                          break;
                        case 'delivered':
                          statusColor = const Color(0xFF00FF66); // Green
                          break;
                        case 'cancellation':
                        case 'cancelled':
                          statusColor = const Color(0xFFFF3366); // Red
                          break;
                        default:
                          statusColor = const Color(0xFFFF0077); // Pink
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF333355),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          // Rest of your existing order item code...
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with glowing effect
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F23),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag,
                                        color: statusColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ORDER #${orderData['orderId']?.toString().substring(0, 8) ?? order.id.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      status.toString().toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'PixelFont',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Order details
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (orderData['orderDate'] != null) ...[
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white54,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(
                                                    orderData['orderDate']),
                                                style: const TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                        FutureBuilder<DocumentSnapshot>(
                                          future: _firestore
                                              .collection('users')
                                              .doc(orderData['userId'])
                                              .get(),
                                          builder: (context, snapshot) {
                                            String customerName = 'Anonymous';
                                            if (snapshot.hasData &&
                                                snapshot.data!.exists) {
                                              final userData =
                                                  snapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              customerName =
                                                  userData['displayName'] ??
                                                      'Anonymous';
                                            }

                                            return Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: Colors.white54,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Customer: $customerName',
                                                  style: const TextStyle(
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F0FF)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF00F0FF)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '₱${orderData['totalPrice']?.toString() ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontFamily: 'PixelFont',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00F0FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(
                              color: Color(0xFF333355),
                              height: 1,
                              thickness: 1,
                            ),

                            // Products heading
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF0077)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PRODUCTS',
                                      style: TextStyle(
                                        fontFamily: 'PixelFont',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF0077),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Products list
                            ...items.map((item) {
                              // Rest of your product rendering code
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(10),
                                // Remaining code for rendering products
                                // ... (rest of product item code)
                                // Your existing product item rendering
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252542),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade800,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image with glow effect
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF0077)
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: item['imageUrl'] != null &&
                                                item['imageUrl']
                                                    .toString()
                                                    .isNotEmpty
                                            ? Image.network(
                                                item['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                  color:
                                                      const Color(0xFF333355),
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white30,
                                                    size: 30,
                                                  ),
                                                ),
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color:
                                                        const Color(0xFF333355),
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: const Color(
                                                            0xFFFF0077),
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: const Color(0xFF333355),
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Colors.white30,
                                                  size: 30,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Product details with pixel style
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? 'Unknown Product',
                                            style: const TextStyle(
                                              fontFamily: 'PixelFont',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black38,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade700),
                                                ),
                                                child: Text(
                                                  'QTY: ${item['quantity'] ?? 1}',
                                                  style: const TextStyle(
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 11,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '₱${item['price'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 14,
                                                  color: Color(0xFF00F0FF),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                height: 6,
                                                width: 6,
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Status: ${orderData['status']?.toString().toUpperCase() ?? 'PROCESSING'}',
                                                style: TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 11,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            // Action buttons
                            // Action buttons
                            // Action buttons - Fix overflow by using a Wrap widget
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing:
                                    8, // horizontal spacing between buttons
                                runSpacing: 8, // vertical spacing between rows
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildNeonButton(
                                      context,
                                      'To Pay',
                                      orderData['status'] == 'To Pay',
                                      order.id,
                                      _firestore),
                                  _buildNeonButton(
                                      context,
                                      'To Ship',
                                      orderData['status'] == 'To Ship',
                                      order.id,
                                      _firestore),
                                  _buildNeonButton(
                                      context,
                                      'To Receive',
                                      orderData['status'] == 'To Receive',
                                      order.id,
                                      _firestore),
                                  _buildNeonButton(
                                      context,
                                      'To Review',
                                      orderData['status'] == 'To Review',
                                      order.id,
                                      _firestore),
                                  _buildNeonButton(
                                      context,
                                      'Delivered',
                                      orderData['status'] == 'Delivered',
                                      order.id,
                                      _firestore),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the drawer/hamburger menu
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  const Color(0xFFFF0077).withOpacity(0.6)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'SELLER MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your orders & products',
                  style: TextStyle(
                    color: const Color(0xFF00F0FF),
                    fontSize: 14,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: const Color(0xFFFF0077)),
            title: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SellerDashboard()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory, color: const Color(0xFFFF0077)),
            title: const Text(
              'Your Products',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => YourProducts()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add_box, color: const Color(0xFFFF0077)),
            title: const Text(
              'Add Product',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProduct()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart, color: const Color(0xFFFF0077)), // Icon for Revenue Graphs
            title: const Text(
              'Revenue Graphs',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RevenueGraph()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: const Color(0xFFFF0077)),
            title: const Text(
              'Order Status',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
            tileColor: const Color(0xFFFF0077).withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              // Already on this page
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: Icon(Icons.settings, color: const Color(0xFFFF0077)),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: const Color(0xFFFF0077)),
            title: const Text(
              'Help',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help page
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: const Color(0xFFFF0077)),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Navigate to login screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton(BuildContext context, String status, bool isSelected,
      String orderId, FirebaseFirestore firestore) {
    // Map status to colors
    Color color;

    // Status values to store in Firestore - lowercase with spaces
    String firestoreStatus = status.toLowerCase();

    switch (status) {
      case 'To Pay':
        color = Colors.orange; // Orange
        break;
      case 'To Ship':
        color = const Color(0xFF00F0FF); // Cyan
        break;
      case 'To Receive':
        color = const Color(0xFFFFCC00); // Yellow
        break;
      case 'To Review':
        color = const Color(0xFFFF0077); // Pink
        break;
      case 'Delivered':  // Changed from 'Completed'
        color = const Color(0xFF00FF66); // Green
        firestoreStatus = 'delivered'; // Changed from 'completed'
        break;
      default:
        color = const Color(0xFFFF0077); // Pink
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () async {
          try {
            // 1. First get the complete order document to access essential data
            DocumentSnapshot orderDoc = await firestore.collection('orders').doc(orderId).get();
            
            if (!orderDoc.exists) {
              throw Exception("Order not found");
            }
            
            // 2. Extract necessary information
            Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
            String userId = orderData['userId'] ?? '';
            String systemOrderId = orderData['orderId'] ?? '';
            
            if (userId.isEmpty || systemOrderId.isEmpty) {
              throw Exception("Invalid order data: missing userId or orderId");
            }
            
            // 3. Begin a batch operation for atomicity
            WriteBatch batch = firestore.batch();
            
            // 4. Update the main order document
            batch.update(firestore.collection('orders').doc(orderId), {
              'status': firestoreStatus,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            
            // 5. Find the corresponding order in user's subcollection
            QuerySnapshot userOrdersQuery = await firestore
                .collection('users')
                .doc(userId)
                .collection('orders')
                .where('orderId', isEqualTo: systemOrderId)
                .get();
            
            // 6. Update each matching user's order document
            for (var doc in userOrdersQuery.docs) {
              batch.update(doc.reference, {
                'status': firestoreStatus,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
            }
            
            // 7. Commit the batch to ensure all updates happen or none do
            await batch.commit();
            
            // 8. Show confirmation to the user
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Order status updated to ${status}',
                  style: const TextStyle(fontFamily: 'PixelFont'),
                ),
                backgroundColor: Colors.green,
              ),
            );
            
            // 9. Show delivered dialog if applicable
            if (firestoreStatus == 'delivered') {
              // Using the complete order data that we already retrieved
              // ignore: use_build_context_synchronously
              _showSalesDeliveredDialog(context, orderData);
            }
            
          } catch (e) {
            print("Error updating order status: $e");
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error updating order: $e',
                  style: const TextStyle(fontFamily: 'PixelFont'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Text(
            status,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 11, // Reduced font size
              fontWeight: FontWeight.bold,
              color: isSelected ? color : color.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Add this new method to show sales completion dialog
  void _showSalesDeliveredDialog(
      BuildContext context, Map<String, dynamic> orderData) {
    double totalAmount = 0.0;
    if (orderData.containsKey('totalPrice')) {
      totalAmount = double.parse(orderData['totalPrice'].toString());
    }

    // Use the customerName field we added in the _buildNeonButton method
    String customerName = orderData['customerName'] ?? 'Customer';
    List<dynamic> items = orderData['items'] ?? [];
    int itemCount = items.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF00FF66),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF66).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sales completed icon with animation
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF66).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00FF66),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ORDER DELIVERED!',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order has been marked as delivered',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // Sale details
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CUSTOMER:',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ITEMS:',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            itemCount.toString(),
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                        color: Color(0xFF333355),
                        height: 1,
                        thickness: 1,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT:',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₱${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                              color: Color(0xFF00FF66),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00FF66),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          color: Color(0xFF00FF66),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      // Handle different date formats
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Invalid Date';
      }

      // Format to YYYY-MM-DD
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildStatTile(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Near the bottom of the file, modify the updateOrderStatus function:

Future<void> updateOrderStatus(String orderId, String newStatus, BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // 1. Convert the status to the proper format for Firestore
    String firestoreStatus = newStatus.toLowerCase();
    
    // Map specific status values if needed
    if (newStatus == 'Delivered') {
      firestoreStatus = 'delivered';
    }
    
    // 2. Start a batch operation
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    // 3. First find the order in the main orders collection
    // This is preferable to looking up in the user collection first
    QuerySnapshot orderQuery = await FirebaseFirestore.instance
        .collection('orders')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
        
    if (orderQuery.docs.isEmpty) {
      throw Exception("Order not found in main collection");
    }
    
    // Get the main order document and its data
    DocumentReference mainOrderRef = orderQuery.docs.first.reference;
    Map<String, dynamic> orderData = orderQuery.docs.first.data() as Map<String, dynamic>;
    String userId = orderData['userId'];
    
    // 4. Update in the main orders collection
    batch.update(mainOrderRef, {
      'status': firestoreStatus,
      'lastUpdated': FieldValue.serverTimestamp()
    });
    
    // 5. Find and update in user's orders collection
    if (userId != null && userId.isNotEmpty) {
      QuerySnapshot userOrderQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
          
      if (userOrderQuery.docs.isNotEmpty) {
        batch.update(userOrderQuery.docs.first.reference, {
          'status': firestoreStatus,
          'lastUpdated': FieldValue.serverTimestamp()
        });
      }
    }
    
    // 6. Commit the batch
    await batch.commit();
    
    // 7. Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order status updated to $newStatus',
          style: const TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.green,
      ),
    );
    
  } catch (e) {
    print('Error updating order status: $e');
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
