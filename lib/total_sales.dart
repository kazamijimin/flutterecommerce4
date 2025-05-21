import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key});

  // List of vibrant colors for the pie chart sections
  final List<Color> categoryColors = const [
    Color(0xFFFF0077), // Pink
    Color(0xFF00F0FF), // Cyan
    Color(0xFF00FF66), // Green
    Color(0xFFFFBB00), // Yellow
    Color(0xFF8855FF), // Purple
    Color(0xFFFF5500), // Orange
    Color(0xFF00BBFF), // Blue
    Color(0xFFFF88AA), // Light Pink
  ];

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SALES BY CATEGORY',
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
                        Icons.pie_chart,
                        size: 64,
                        color: const Color(0xFFFF0077).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NO SALES DATA',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete some sales to see category insights',
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

              // Process data for the pie chart
              final orders = snapshot.data!.docs;
              final Map<String, double> revenueByCategory = {};
              double totalRevenue = 0;
              String topCategory = '';
              double topCategoryRevenue = 0;
              int totalItems = 0;
              
              for (var order in orders) {
                final data = order.data() as Map<String, dynamic>;
                if (data.containsKey('items')) {
                  final items = data['items'] as List<dynamic>;
                  
                  for (var item in items) {
                    if (item is Map<String, dynamic> &&
                        item.containsKey('category') &&
                        item.containsKey('price') &&
                        item.containsKey('quantity') &&
                        item.containsKey('sellerId') &&
                        item['sellerId'] == currentUserId) {  // Only process current seller's items
                          
                      final category = item['category'] as String;
                      final price = double.parse(item['price'].toString());
                      final quantity = int.parse(item['quantity'].toString());
                      final itemRevenue = price * quantity;
                      
                      totalRevenue += itemRevenue;
                      totalItems += quantity;
                      
                      if (revenueByCategory.containsKey(category)) {
                        revenueByCategory[category] = revenueByCategory[category]! + itemRevenue;
                      } else {
                        revenueByCategory[category] = itemRevenue;
                      }
                      
                      // Track top category
                      if (revenueByCategory[category]! > topCategoryRevenue) {
                        topCategoryRevenue = revenueByCategory[category]!;
                        topCategory = category;
                      }
                    }
                  }
                }
              }
              
              // Prepare pie chart sections
              final List<PieChartSectionData> sections = [];
              int colorIndex = 0;
              
              // Sort categories by revenue (descending)
              final sortedCategories = revenueByCategory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
                
              for (var entry in sortedCategories) {
                final percentage = (entry.value / totalRevenue) * 100;
                // Skip very small segments (less than 1%)
                if (percentage < 1 && sortedCategories.length > 6) continue;
                
                sections.add(
                  PieChartSectionData(
                    color: categoryColors[colorIndex % categoryColors.length],
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: percentage < 5 ? null : _Badge(
                      entry.key,
                      size: 40,
                      borderColor: categoryColors[colorIndex % categoryColors.length],
                    ),
                    badgePositionPercentageOffset: 1.0,
                  ),
                );
                colorIndex++;
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
                                          'Total Items',
                                          totalItems.toString(),
                                          const Color(0xFFFFBB00), // Yellow
                                          Icons.shopping_cart,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Categories',
                                          revenueByCategory.length.toString(),
                                          const Color(0xFF00F0FF), // Cyan
                                          Icons.category,
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
                                      'Total Items',
                                      totalItems.toString(),
                                      const Color(0xFFFFBB00), // Yellow
                                      Icons.shopping_cart,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Categories',
                                      revenueByCategory.length.toString(),
                                      const Color(0xFF00F0FF), // Cyan
                                      Icons.category,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    
                    // Best selling category card
                    if (topCategory.isNotEmpty)
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
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1A1A2E),
                              const Color(0xFFFF0077).withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0077).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF0077).withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: Color(0xFFFF0077),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOP SELLING CATEGORY',
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF0077),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topCategory,
                                    style: const TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${topCategoryRevenue.toStringAsFixed(2)} · ${((topCategoryRevenue / totalRevenue) * 100).toStringAsFixed(1)}% of total',
                                    style: const TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
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
                        'SALES BY CATEGORY',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    
                    // Pie chart container
                    Container(
                      height: 320, // Fixed height
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
                      child: sections.isEmpty 
                          ? const Center(
                              child: Text(
                                'No category data to display',
                                style: TextStyle(
                                  fontFamily: 'PixelFont',
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: sections,
                                      pieTouchData: PieTouchData(
                                        enabled: true, // Just enable touch without callback
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap on a category to view details',
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                    
                    // Category breakdown list
                    if (sortedCategories.isNotEmpty) ...[
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
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CATEGORY BREAKDOWN',
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  'REVENUE',
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 12,
                                    color: Colors.white54,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedCategories.length,
                              separatorBuilder: (context, index) => const Divider(
                                color: Color(0xFF333355),
                                height: 16,
                              ),
                              itemBuilder: (context, index) {
                                final category = sortedCategories[index].key;
                                final revenue = sortedCategories[index].value;
                                final percentage = (revenue / totalRevenue) * 100;
                                
                                return Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: categoryColors[index % categoryColors.length],
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₱${revenue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 14,
                                          color: categoryColors[index % categoryColors.length],
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 55,
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );
                              },
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
}

// Custom badge widget for pie chart sections
class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text,
    {
      required this.size,
      required this.borderColor,
      Key? key,
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 2,
            color: borderColor.withOpacity(0.5),
          )
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}