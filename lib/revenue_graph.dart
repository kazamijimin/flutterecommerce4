import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seller_dashboard.dart';
import 'your_products.dart';
import 'add_product.dart';
import 'order_status.dart';
import 'total_sales.dart'; // Import the CategoryPieChart

class RevenueGraph extends StatelessWidget {
  const RevenueGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      drawer: _buildDrawer(context), // Add the drawer here
      appBar: AppBar(
        title: const Text(
          'REVENUE ANALYTICS',
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
        actions: [
          // Add action button to navigate to Category Pie Chart
          IconButton(
            icon: const Icon(
              Icons.pie_chart,
              color: Color(0xFFFF0077),
            ),
            tooltip: 'View Sales by Category',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryPieChart(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('orders').snapshots(),
            builder: (context, snapshot) {
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
                        'LOADING DATA...',
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
                        Icons.bar_chart,
                        size: 64,
                        color: const Color(0xFFFF0077).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NO REVENUE DATA',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete some sales to see your revenue',
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

              // Process data for the graph
              final orders = snapshot.data!.docs;
              final Map<String, double> revenueByDate = {};
              double totalRevenue = 0;
              double highestDailyRevenue = 0;
              String bestDay = '';

              for (var order in orders) {
                final data = order.data() as Map<String, dynamic>;
                if (data.containsKey('totalPrice') &&
                    data.containsKey('orderDate')) {
                  final revenue = double.parse(data['totalPrice'].toString());
                  totalRevenue += revenue;
                  
                  final orderDate = data['orderDate'] is Timestamp
                      ? (data['orderDate'] as Timestamp).toDate()
                      : DateTime.parse(data['orderDate'].toString());
                  final dateKey =
                      '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';

                  if (revenueByDate.containsKey(dateKey)) {
                    revenueByDate[dateKey] = revenueByDate[dateKey]! + revenue;
                  } else {
                    revenueByDate[dateKey] = revenue;
                  }
                  
                  // Track highest daily revenue
                  if (revenueByDate[dateKey]! > highestDailyRevenue) {
                    highestDailyRevenue = revenueByDate[dateKey]!;
                    bestDay = dateKey;
                  }
                }
              }

              // Format bestDay for better display
              String formattedBestDay = bestDay;
              if (bestDay.isNotEmpty) {
                final parts = bestDay.split('-');
                if (parts.length == 3) {
                  formattedBestDay = '${parts[1]}/${parts[2]}';
                }
              }
              
              // Sort the data by date
              final sortedKeys = revenueByDate.keys.toList()..sort();
              final List<FlSpot> spots = [];
              for (int i = 0; i < sortedKeys.length; i++) {
                spots.add(FlSpot(i.toDouble(), revenueByDate[sortedKeys[i]]!));
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary cards
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                            'REVENUE SUMMARY',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Use responsive layout for summary cards
                          isSmallScreen 
                            ? Column(
                                children: [
                                  _buildStatCard(
                                    'Total Revenue',
                                    '₱${totalRevenue.toStringAsFixed(2)}',
                                    const Color(0xFF00FF66), // Green
                                    Icons.account_balance_wallet,
                                    isFullWidth: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Best Day',
                                          formattedBestDay,
                                          const Color(0xFFFF0077), // Pink
                                          Icons.emoji_events,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Highest Daily',
                                          '₱${highestDailyRevenue.toStringAsFixed(2)}',
                                          const Color(0xFF00F0FF), // Cyan
                                          Icons.trending_up,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Revenue',
                                      '₱${totalRevenue.toStringAsFixed(2)}',
                                      const Color(0xFF00FF66), // Green
                                      Icons.account_balance_wallet,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Best Day',
                                      formattedBestDay,
                                      const Color(0xFFFF0077), // Pink
                                      Icons.emoji_events,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Highest Daily',
                                      '₱${highestDailyRevenue.toStringAsFixed(2)}',
                                      const Color(0xFF00F0FF), // Cyan
                                      Icons.trending_up,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    
                    // Chart title
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(
                          color: const Color(0xFF333355),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'DAILY REVENUE TREND',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    
                    // Chart container
                    Container(
                      height: 300, // Fixed height instead of Expanded
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
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
                      child: sortedKeys.isEmpty 
                          ? const Center(
                              child: Text(
                                'No data points to display',
                                style: TextStyle(
                                  fontFamily: 'PixelFont',
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: const Color(0xFF333355),
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: const Color(0xFF333355),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: SideTitles(
                                    showTitles: true,
                                    getTitles: (value) {
                                      // Simplify large numbers
                                      if (value >= 1000) {
                                        return '₱${(value/1000).toStringAsFixed(1)}K';
                                      }
                                      return '₱${value.toInt()}';
                                    },
                                    reservedSize: 40,
                                    // Fix: Change the parameter signature for getTextStyles
                                    getTextStyles: (value) => const TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'PixelFont',
                                      fontSize: 10,
                                    ),
                                  ),
                                  bottomTitles: SideTitles(
                                    showTitles: true,
                                    rotateAngle: isSmallScreen ? 45 : 0, // Rotate labels on small screens
                                    getTitles: (value) {
                                      // Show fewer labels on small screens
                                      final int index = value.toInt();
                                      if (index >= 0 && index < sortedKeys.length) {
                                        // Show every other label on small screens
                                        if (isSmallScreen && index % 2 != 0 && sortedKeys.length > 5) {
                                          return '';
                                        }
                                        
                                        // Abbreviate the date format for better display
                                        final parts = sortedKeys[index].split('-');
                                        if (parts.length == 3) {
                                          return '${parts[1]}/${parts[2]}';
                                        }
                                        return sortedKeys[index];
                                      }
                                      return '';
                                    },
                                    reservedSize: isSmallScreen ? 30 : 22, // More space for rotated labels
                                    margin: 8,
                                    getTextStyles: (value) => const TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'PixelFont',
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: const Color(0xFF333355),
                                    width: 1,
                                  ),
                                ),
                                minX: 0,
                                maxX: sortedKeys.length - 1.0,
                                minY: 0,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    colors: const [Color(0xFFFF0077)],
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      // Show fewer dots on small screens with many data points
                                      checkToShowDot: (spot, barData) {
                                        return !isSmallScreen || 
                                               sortedKeys.length <= 10 || 
                                               spot.x.toInt() % 2 == 0;
                                      },
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 5,
                                          color: const Color(0xFFFF0077),
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      colors: [
                                        const Color(0xFFFF0077).withOpacity(0.3),
                                        const Color(0xFFFF0077).withOpacity(0.0),
                                      ],
                                      gradientColorStops: [0.5, 1.0],
                                      gradientFrom: const Offset(0, 0),
                                      gradientTo: const Offset(0, 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    
                    // Additional section for trends (if needed)
                    if (sortedKeys.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
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
                              'INSIGHTS',
                              style: TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInsightRow(
                              'Total Orders',
                              orders.length.toString(),
                              Icons.shopping_cart,
                              Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildInsightRow(
                              'Average Order Value',
                              '₱${(totalRevenue / orders.length).toStringAsFixed(2)}',
                              Icons.insights,
                              const Color(0xFF00F0FF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool isFullWidth = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isFullWidth ? 0 : 4),
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  color: Colors.white70,
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
      ],
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
                  'Analytics & Management',
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
            leading: Icon(Icons.bar_chart, color: const Color(0xFFFF0077)),
            title: const Text(
              'Revenue Graphs',
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
          ListTile(
            leading: Icon(Icons.pie_chart, color: const Color(0xFFFF0077)),
            title: const Text(
              'Sales by Category',
              style: TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPieChart()),
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
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderStatus()),
              );
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
}