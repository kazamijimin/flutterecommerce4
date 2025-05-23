import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_history.dart';
import 'shop.dart';
class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final item = order['items'][0]; // Get the single product being checked out
    final neonPink = const Color(0xFFFF0077);
    final neonBlue = const Color(0xFF00E5FF);
    final neonGreen = const Color(0xFF00FF66);
    final darkBackground = const Color(0xFF0F0F1B);
    final surfaceColor = const Color(0xFF1A1A2E);

    // Get the order status
    final String orderStatus = order['status']?.toString() ?? 'To Pay';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(orderStatus),
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: darkBackground,
        elevation: 0,
      ),
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // Background grid effect
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(
              lineColor: neonBlue.withOpacity(0.15),
              lineWidth: 1,
              gridSpacing: 30,
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status tracker card
                _buildStatusTracker(
                    orderStatus, neonPink, neonBlue, neonGreen, surfaceColor),

                const SizedBox(height: 24),

                // Order information card
                _buildSectionCard(
                  title: 'ORDER INFORMATION',
                  icon: Icons.info_outline,
                  neonPink: neonPink,
                  neonBlue: neonBlue,
                  surfaceColor: surfaceColor,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.confirmation_number,
                        title: 'Order ID',
                        value: '#${order['orderId'] ?? 'N/A'}',
                        iconColor: neonBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: _formatDate(order['orderDate'] ?? 'N/A'),
                        iconColor: neonBlue,
                      ),
                      const SizedBox(height: 12),

                      // Enhanced payment method display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: neonBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontFamily: 'PixelFont',
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildPaymentMethodCard(order, neonPink, neonBlue),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.local_shipping,
                        title: 'Shipping Option',
                        value: order['shippingOption'] ?? 'Standard Shipping',
                        iconColor: neonBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        title: 'Shipping Address',
                        value: order['shippingAddress'] ?? 'N/A',
                        iconColor: neonBlue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Product card
                _buildSectionCard(
                  title: 'YOUR PURCHASE',
                  icon: Icons.shopping_bag,
                  neonPink: neonPink,
                  neonBlue: neonBlue,
                  surfaceColor: surfaceColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image with animated border
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              border: Border.all(
                                color: neonPink,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonPink.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              child: Image.network(
                                item['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: neonPink,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    border: Border.all(
                                      color: Colors.grey.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Quantity: ${item['quantity']}',
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: neonBlue.withOpacity(0.2),
                                    border: Border.all(
                                      color: neonBlue.withOpacity(0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '\$${item['price']}',
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: neonBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Add payment method and shipping address here
                                Row(
                                  children: [
                                    Icon(Icons.payment,
                                        color: neonPink, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      order['paymentMethod'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'PixelFont',
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on,
                                        color: neonBlue, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order['shippingAddress'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 12,
                                          color: Colors.white70,
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment summary card
                _buildSectionCard(
                  title: 'PAYMENT SUMMARY',
                  icon: Icons.account_balance_wallet,
                  neonPink: neonPink,
                  neonBlue: neonBlue,
                  surfaceColor: surfaceColor,
                  child: Column(
                    children: [
                      _buildPaymentRow(
                        title: 'Subtotal',
                        value:
                            '\$${(order['totalPrice'] != null ? (order['totalPrice'] - 4.99) : 0).toStringAsFixed(2)}',
                      ),
                      _buildPaymentRow(
                        title: 'Shipping Fee',
                        value: '\$4.99',
                      ),
                      const SizedBox(height: 4),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 4),
                      _buildPaymentRow(
                        title: 'Total',
                        value:
                            '\$${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                        isTotal: true,
                        neonPink: neonPink,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action button based on order status
                _buildActionButton(
                    context, orderStatus, order, neonPink, neonBlue, neonGreen),

                // Add this to show admin controls (with divider for visual separation)
                if (_isSellerOrAdmin()) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Add this to show order history button
                _buildOrderHistoryButton(context, neonBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Replace your existing _getAppBarTitle method
  String _getAppBarTitle(String status) {
    // Normalize status for consistent comparison
    final String normalizedStatus = status.toString().toLowerCase();

    switch (normalizedStatus) {
      case 'to pay':
        return 'PAYMENT PENDING';
      case 'to ship':
        return 'ORDER CONFIRMED';
      case 'to receive':
        return 'ORDER SHIPPED';
      case 'to review':
        return 'ORDER DELIVERED';
      case 'delivered':
        return 'ORDER DELIVERED';
      case 'completed':
        return 'ORDER COMPLETE';
      case 'cancelled':
        return 'ORDER CANCELLED';
      default:
        return 'ORDER DETAILS';
    }
  }

  // Replace your existing _buildStatusTracker method with this one
  Widget _buildStatusTracker(String status, Color neonPink, Color neonBlue,
      Color neonGreen, Color surfaceColor) {
    // Normalize the status string for consistent comparison
    final String normalizedStatus = status.toString().toLowerCase();

    // Determine which stages are completed
    final isPaid = normalizedStatus != 'to pay';
    final isShipped = ['to receive', 'to review', 'delivered', 'completed']
        .contains(normalizedStatus);
    final isDelivered =
        ['to review', 'delivered', 'completed'].contains(normalizedStatus);
    final isCompleted = ['delivered', 'completed'].contains(normalizedStatus);

    // Determine current active step and its color
    Color activeStepColor;
    String activeStepText;

    switch (normalizedStatus) {
      case 'to pay':
        activeStepColor = Colors.orange;
        activeStepText = 'PAYMENT PENDING';
        break;
      case 'to ship':
        activeStepColor = neonPink;
        activeStepText = 'PREPARING YOUR ORDER';
        break;
      case 'to receive':
        activeStepColor = neonBlue;
        activeStepText = 'YOUR ORDER IS ON THE WAY';
        break;
      case 'to review':
        activeStepColor = neonGreen;
        activeStepText = 'ORDER DELIVERED';
        break;
      case 'delivered':
        activeStepColor = neonGreen;
        activeStepText = 'ORDER DELIVERED';
        break;
      case 'completed':
        activeStepColor = neonGreen;
        activeStepText = 'ORDER COMPLETED';
        break;
      case 'cancelled':
        activeStepColor = Colors.red;
        activeStepText = 'ORDER CANCELLED';
        break;
      default:
        activeStepColor = neonPink;
        activeStepText = 'PROCESSING';
    }

    // Select appropriate icon for current status
    IconData statusIcon;
    switch (normalizedStatus) {
      case 'to pay':
        statusIcon = Icons.hourglass_empty;
        break;
      case 'to ship':
        statusIcon = Icons.inventory;
        break;
      case 'to receive':
        statusIcon = Icons.local_shipping;
        break;
      case 'to review':
        statusIcon = Icons.check_circle;
        break;
      case 'delivered':
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusIcon = Icons.verified;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        break;
      default:
        statusIcon = Icons.help;
    }

    // The rest of your existing method remains the same...
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(
          color: activeStepColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activeStepColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Status header with gradient matching current status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeStepColor.withOpacity(0.7),
                  activeStepColor.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeStepText,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dynamic status tracker steps with individual colors
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Payment step - active only when on "to pay" or completed
                _buildStatusStep(
                    'Payment',
                    isPaid || normalizedStatus == 'to pay',
                    normalizedStatus == 'to pay'
                        ? Colors.orange
                        : (isPaid ? neonPink : Colors.grey.shade800),
                    isCurrentStep: normalizedStatus == 'to pay'),

                _buildStatusLine(
                    isPaid, isPaid ? neonPink : Colors.grey.shade800),

                // Shipping step - active only when on "to ship" or later
                _buildStatusStep(
                    'Processing',
                    isShipped || normalizedStatus == 'to ship',
                    normalizedStatus == 'to ship'
                        ? neonPink
                        : (isShipped ? neonBlue : Colors.grey.shade800),
                    isCurrentStep: normalizedStatus == 'to ship'),

                _buildStatusLine(
                    isShipped, isShipped ? neonBlue : Colors.grey.shade800),

                // Delivery step - active only when on "to receive" or later
                _buildStatusStep(
                    'Shipping',
                    isDelivered || normalizedStatus == 'to receive',
                    normalizedStatus == 'to receive'
                        ? neonBlue
                        : (isDelivered ? neonGreen : Colors.grey.shade800),
                    isCurrentStep: normalizedStatus == 'to receive'),

                _buildStatusLine(isDelivered,
                    isDelivered ? neonGreen : Colors.grey.shade800),

                // Completed step - active only when "completed" or "delivered"
                _buildStatusStep(
                    'Delivered',
                    isCompleted || normalizedStatus == 'to review',
                    normalizedStatus == 'to review'
                        ? neonGreen
                        : (isCompleted ? neonGreen : Colors.grey.shade800),
                    isCurrentStep: normalizedStatus == 'to review' ||
                        normalizedStatus == 'delivered' ||
                        normalizedStatus == 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a single status step circle with pulsing effect for current step
  Widget _buildStatusStep(String label, bool isActive, Color color,
      {bool isCurrentStep = false}) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade800,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : Colors.grey.shade600,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(isCurrentStep ? 0.7 : 0.4),
                      blurRadius: isCurrentStep ? 12 : 8,
                      spreadRadius: isCurrentStep ? 2 : 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isActive
                  ? (isCurrentStep ? Icons.circle : Icons.check)
                  : Icons.circle,
              color: Colors.white,
              size: isActive ? (isCurrentStep ? 10 : 16) : 8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 10,
            color: isActive ? color : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Build the connecting line between status steps
  Widget _buildStatusLine(bool isActive, Color activeColor) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isActive ? activeColor : Colors.grey.shade800,
    );
  }

// Replace your existing _buildActionButton method
  Widget _buildActionButton(
    BuildContext context,
    String status,
    Map<String, dynamic> order,
    Color neonPink,
    Color neonBlue,
    Color neonGreen,
  ) {
    // Normalize status
    final String normalizedStatus = status.toString().toLowerCase();

    // Configure button based on status
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback onPressed;

    switch (normalizedStatus) {
      case 'to pay':
        buttonText = 'CONTINUE TO SHOPPING';
        buttonColor = neonPink;
        buttonIcon = Icons.shopping_cart;
        onPressed = () => _proceedToPayment(context, order);
        break;
      case 'to ship':
        buttonText = 'TRACK ORDER';
        buttonColor = neonBlue;
        buttonIcon = Icons.inventory;
        onPressed = () => _trackOrder(context, order);
        break;
      case 'to receive':
        buttonText = 'TRACK SHIPMENT';
        buttonColor = neonBlue;
        buttonIcon = Icons.local_shipping;
        onPressed = () => _trackShipment(context, order);
        break;
      case 'to review':
        buttonText = 'WRITE A REVIEW';
        buttonColor = neonGreen;
        buttonIcon = Icons.rate_review;
        onPressed = () => _writeReview(context, order);
        break;
      case 'delivered':
        buttonText = 'WRITE A REVIEW';
        buttonColor = neonGreen;
        buttonIcon = Icons.rate_review;
        onPressed = () => _writeReview(context, order);
        break;
      case 'completed':
        buttonText = 'CONTINUE SHOPPING';
        buttonColor = neonGreen;
        buttonIcon = Icons.shopping_cart;
        onPressed =
            () => Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 'cancelled':
        buttonText = 'CONTINUE SHOPPING';
        buttonColor = Colors.grey;
        buttonIcon = Icons.shopping_cart;
        onPressed =
            () => Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      default:
        buttonText = 'CONTINUE SHOPPING';
        buttonColor = neonBlue;
        buttonIcon = Icons.shopping_cart;
        onPressed =
            () => Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(buttonIcon),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Action methods
void _proceedToPayment(BuildContext context, Map<String, dynamic> order) {
  // Navigate to ShopPage instead of showing a snackbar
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(
      builder: (context) => const ShopPage(
        initialCategory: 'All', // You can set any initial category you want
      ),
    ),
  );
}

  void _trackOrder(BuildContext context, Map<String, dynamic> order) {
    // Navigate to order tracking page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tracking your order...',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _trackShipment(BuildContext context, Map<String, dynamic> order) {
    // Navigate to shipment tracking page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tracking your shipment...',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _writeReview(BuildContext context, Map<String, dynamic> order) {
    // Navigate to review writing page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opening review form...',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color neonPink,
    required Color neonBlue,
    required Color surfaceColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: neonBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: neonPink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: neonBlue,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 18,
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
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow({
    required String title,
    required String value,
    bool isTotal = false,
    Color? neonPink,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.white : Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? (neonPink ?? Colors.white) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Add these methods to the OrderDetailsPage class

  // Method to determine if current user is a seller or admin
  bool _isSellerOrAdmin() {
    // For demo purposes - set to true to see admin controls
    // In production, you'd check user roles in Firestore
    return true;
  }

  // Build status update controls for admin/seller users

  // Build individual status update button
  Widget _buildStatusUpdateButton(
      BuildContext context, String status, bool isSelected) {
    // Status-specific styling
    Color color;
    String firestoreStatus = status.toLowerCase();

    switch (status) {
      case 'To Pay':
        color = Colors.orange;
        break;
      case 'To Ship':
        color = const Color(0xFF00E5FF);
        break;
      case 'To Receive':
        color = const Color(0xFFFFCC00);
        break;
      case 'To Review':
        color = const Color(0xFFFF0077);
        break;
      case 'Delivered':
        color = const Color(0xFF00FF66);
        firestoreStatus = 'delivered';
        break;
      default:
        color = const Color(0xFFFF0077);
    }

    return InkWell(
      onTap: () => _updateOrderStatus(context, firestoreStatus),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : color.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Method to update order status in both Firebase collections
  Future<void> _updateOrderStatus(
      BuildContext context, String newStatus) async {
    try {
      final String orderId = order['documentId'] ?? '';
      final String systemOrderId = order['orderId'] ?? '';
      String userId = order['userId'] ?? '';

      if (orderId.isEmpty && systemOrderId.isEmpty) {
        throw Exception("Cannot identify order");
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();

      // Find and update the order document
      DocumentReference? orderRef;

      if (orderId.isNotEmpty) {
        // If we have the document ID, use it directly
        orderRef = firestore.collection('orders').doc(orderId);
      } else if (systemOrderId.isNotEmpty) {
        // Otherwise find by orderId
        QuerySnapshot orderQuery = await firestore
            .collection('orders')
            .where('orderId', isEqualTo: systemOrderId)
            .limit(1)
            .get();

        if (orderQuery.docs.isNotEmpty) {
          orderRef = orderQuery.docs.first.reference;

          // Get userId if not available
          if (userId.isEmpty) {
            final orderData =
                orderQuery.docs.first.data() as Map<String, dynamic>;
            userId = orderData['userId'] ?? '';
          }
        }
      }

      // Update main order document
      if (orderRef != null) {
        batch.update(orderRef, {
          'status': newStatus,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Update user's order copy
      if (userId.isNotEmpty && systemOrderId.isNotEmpty) {
        QuerySnapshot userOrderQuery = await firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .where('orderId', isEqualTo: systemOrderId)
            .limit(1)
            .get();

        if (userOrderQuery.docs.isNotEmpty) {
          batch.update(userOrderQuery.docs.first.reference, {
            'status': newStatus,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order updated to ${newStatus.toUpperCase()}',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Create notification about order status change
      if (userId.isNotEmpty) {
        String title = 'Order Status Updated';
        String message = 'Your order has been updated to $newStatus.';

        // Customize message based on order status
        switch (newStatus) {
          case 'to ship':
            title = 'Order Confirmed';
            message =
                'Your order #$systemOrderId has been confirmed and is being prepared.';
            break;
          case 'to receive':
            title = 'Order Shipped';
            message =
                'Your order #$systemOrderId has been shipped and is on its way!';
            break;
          case 'delivered':
            title = 'Order Delivered';
            message = 'Your order #$systemOrderId has been delivered. Enjoy!';
            break;
          case 'cancelled':
            title = 'Order Cancelled';
            message = 'Your order #$systemOrderId has been cancelled.';
            break;
        }

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'type': 'orders',
          'title': title,
          'message': message,
          'orderId': systemOrderId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Refresh the page - easiest way is to pop and push
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsPage(
            order: {...order, 'status': newStatus},
          ),
        ),
      );
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this new method to the OrderDetailsPage class:
  Widget _buildOrderHistoryButton(BuildContext context, Color neonBlue) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToOrderHistory(context),
          icon: const Icon(Icons.history),
          label: const Text(
            'VIEW ORDER HISTORY',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: neonBlue, width: 1.5),
            foregroundColor: neonBlue,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to handle navigation
  void _navigateToOrderHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderHistory(),
      ),
    );
  }

// Replace the problematic line in the _formatPaymentMethod method:
  String _formatPaymentMethod(String? method, dynamic details) {
    if (method == null) return 'N/A';

    if (method == 'Card' && details != null) {
      // Format card payment details - fix the type casting issue
      final Map<String, dynamic> paymentDetails =
          details is Map<String, dynamic>
              ? details
              : Map<String, dynamic>.from(details as Map);

      if (paymentDetails.containsKey('savedCard') &&
          paymentDetails['savedCard'] == 'true') {
        // Display saved card info
        final String cardNickname =
            paymentDetails['cardNickname'] ?? 'Saved Card';
        final String bank = paymentDetails['bank'] ?? '';
        final String cardNumber = paymentDetails['cardNumber'] ?? '';

        return 'Credit Card - $cardNickname\n$bank ($cardNumber)';
      } else {
        // Display new card info
        final String bank = paymentDetails['bank'] ?? '';
        final String cardNumber = paymentDetails['cardNumber'] ?? '';
        final String lastFour = cardNumber.length > 4
            ? cardNumber.substring(cardNumber.length - 4)
            : cardNumber;

        return 'Credit Card - $bank\n**** **** **** $lastFour';
      }
    } else if (method == 'Wallet') {
      return 'Digital Wallet';
    } else if (method == 'Cash on Delivery (COD)') {
      return 'Cash on Delivery';
    }

    return method;
  }

  // Add this new method to create a nicely formatted payment method card
  Widget _buildPaymentMethodCard(
      Map<String, dynamic> order, Color neonPink, Color neonBlue) {
    final paymentMethod = order['paymentMethod'] ?? 'N/A';
    final paymentDetails = order['paymentDetails'];

    // Default icon and colors
    IconData paymentIcon = Icons.credit_card;
    Color cardColor = neonBlue.withOpacity(0.1);
    Color borderColor = neonBlue.withOpacity(0.3);

    // Set appropriate icon and color based on payment method
    if (paymentMethod == 'Card') {
      paymentIcon = Icons.credit_card;
      cardColor = neonPink.withOpacity(0.1);
      borderColor = neonPink.withOpacity(0.3);
    } else if (paymentMethod == 'Wallet') {
      paymentIcon = Icons.account_balance_wallet;
      cardColor = neonBlue.withOpacity(0.1);
      borderColor = neonBlue.withOpacity(0.3);
    } else if (paymentMethod == 'Cash on Delivery (COD)') {
      paymentIcon = Icons.money;
      cardColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green.withOpacity(0.3);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              paymentIcon,
              color: paymentMethod == 'Card' ? neonPink : neonBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: paymentMethod == 'Card' && paymentDetails != null
                ? _buildCardDetails(paymentDetails)
                : Text(
                    paymentMethod,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(dynamic details) {
    final Map<String, dynamic> paymentDetails = details is Map<String, dynamic>
        ? details
        : Map<String, dynamic>.from(details as Map);

    final bool isSavedCard = paymentDetails.containsKey('savedCard') &&
        paymentDetails['savedCard'] == 'true';
    final String cardNumber =
        paymentDetails['cardNumber'] ?? '**** **** **** ****';
    final String bank = paymentDetails['bank'] ?? 'Unknown Bank';
    final String cardNickname = paymentDetails['cardNickname'] ?? 'Card';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSavedCard ? cardNickname : 'Credit/Debit Card',
          style: const TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cardNumber,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bank,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.cyan,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// Custom painter for grid background
class GridPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double gridSpacing;

  GridPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.gridSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
