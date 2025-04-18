import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details.dart';
import 'dart:math';
class CheckoutPage extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> selectedItems;

  const CheckoutPage({
    Key? key,
    required this.totalPrice,
    required this.selectedItems,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'Card';
  String _selectedShippingOption = 'Standard Shipping';
  bool _isLoading = false;
  String _selectedAddress = 'Loading...';
  List<Map<String, dynamic>> _addresses = [];
  double _shippingFee = 4.99; // Default shipping fee
  double _totalPayment = 0.0;

  final Color _neonPink = const Color(0xFFFF0077);
  final Color _neonBlue = const Color(0xFF00E5FF);
  final Color _darkBackground = const Color(0xFF0F0F1B);
  final Color _surfaceColor = const Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _calculateTotalPayment();
  }

  Future<void> _fetchAddresses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _addresses = snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();
            _selectedAddress = _addresses.first['street'] ?? 'No address found';
          });
        } else {
          setState(() {
            _selectedAddress = 'No addresses available';
          });
        }
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Failed to load addresses';
      });
    }
  }

  void _calculateTotalPayment() {
    setState(() {
      _totalPayment = widget.totalPrice + _shippingFee;
    });
  }

  void _showAddressSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _addresses.isEmpty
            ? const Center(
                child: Text(
                  'No addresses available. Please add one.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return ListTile(
                    title: Text(
                      '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedAddress =
                            '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CHECKOUT',
          style: TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _neonPink,
        ),
      ),
      backgroundColor: _darkBackground,
      body: Stack(
        children: [
          // Background grid lines effect
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(
              lineColor: _neonBlue.withOpacity(0.15),
              lineWidth: 1,
              gridSpacing: 30,
            ),
          ),
          // Main content
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Shipping address section
              _buildSectionCard(
                title: 'SHIPPING ADDRESS',
                icon: Icons.location_on,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAddress,
                      style: const TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(
                            Icons.edit,
                            color: _neonBlue,
                            size: 16,
                          ),
                          label: const Text(
                            'CHANGE',
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              color: Colors.cyan,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: _showAddressSelectionDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order items section
              _buildSectionCard(
                title: 'ORDER ITEMS',
                icon: Icons.shopping_bag,
                child: Column(
                  children: [
                    for (final item in widget.selectedItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _neonPink,
                                  width: 1.5,
                                ),
                              ),
                              child: Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
              const SizedBox(height: 16),

              // Payment method section
              _buildSectionCard(
                title: 'PAYMENT METHOD',
                icon: Icons.payment,
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Credit/Debit Card',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      value: 'Card',
                      groupValue: _selectedPaymentMethod,
                      activeColor: _neonPink,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Digital Wallet',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      value: 'Wallet',
                      groupValue: _selectedPaymentMethod,
                      activeColor: _neonPink,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Cash on Delivery (COD)',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      value: 'Cash on Delivery (COD)',
                      groupValue: _selectedPaymentMethod,
                      activeColor: _neonPink,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order summary section
              _buildSectionCard(
                title: 'ORDER SUMMARY',
                icon: Icons.receipt_long,
                child: Column(
                  children: [
                    _buildSummaryRow(
                      title: 'Merchandise Subtotal',
                      value: '\$${widget.totalPrice.toStringAsFixed(2)}',
                    ),
                    _buildSummaryRow(
                      title: 'Shipping Fee',
                      value: '\$${_shippingFee.toStringAsFixed(2)}',
                    ),
                    Divider(color: Colors.white30),
                    _buildSummaryRow(
                      title: 'Total Payment',
                      value: '\$${_totalPayment.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _surfaceColor,
          boxShadow: [
            BoxShadow(
              color: _neonPink.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PAYMENT',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '\$${_totalPayment.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _neonPink,
                  ),
                ),
              ],
            ),
            _isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
                  )
                : ElevatedButton(
                    onPressed: _confirmOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neonPink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: const Text(
                      'PLACE ORDER',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border.all(
          color: _neonBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _neonBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: _neonPink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _neonBlue,
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

  Widget _buildSummaryRow({
    required String title,
    required String value,
    bool isTotal = false,
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
              color: isTotal ? _neonBlue : Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? _neonPink : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
Future<void> _confirmOrder() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Generate a 12-digit order ID
      final random = Random();
      final orderId = List.generate(12, (_) => random.nextInt(10)).join();

      // Add order to the user's orders collection
      final userOrdersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders');

      final orderData = {
        'orderId': orderId, // Save the generated order ID
        'totalPrice': _totalPayment,
        'paymentMethod': _selectedPaymentMethod,
        'shippingOption': _selectedShippingOption,
        'shippingAddress': _selectedAddress,
        'orderDate': DateTime.now().toIso8601String(),
        'items': widget.selectedItems,
        'status': 'to pay', // Set the initial status to "to pay"
        'userId': user.uid, // Add user ID for reference
      };

      await userOrdersRef.add(orderData);

      // Add order to the global orders collection
      final globalOrdersRef = FirebaseFirestore.instance.collection('orders');
      await globalOrdersRef.add(orderData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ORDER CONFIRMED!',
            style: TextStyle(
              fontFamily: 'PixelFont',
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the Order Table Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrderTablePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'YOU MUST BE LOGGED IN TO PLACE AN ORDER.',
            style: TextStyle(
              fontFamily: 'PixelFont',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'FAILED TO PLACE ORDER: $e',
          style: TextStyle(
            fontFamily: 'PixelFont',
          ),
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
}

// Custom painter for cyberpunk grid background effect
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