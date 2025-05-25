import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details.dart';
import 'dart:math';
import 'card_payment_dialog.dart';
import 'wallet.dart';

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
  String _selectedAddress = '';
  List<Map<String, dynamic>> _addresses = [];
  double _shippingFee = 4.99; // Default shipping fee
  double _totalPayment = 0.0;
  bool _addressesLoading = true;
  double _walletBalance = 0.0; // Add this for wallet balance
  bool _isWalletLoading = true; // Add this for wallet loading state

  final Color _neonPink = const Color(0xFFFF0077);
  final Color _neonBlue = const Color(0xFF00E5FF);
  final Color _darkBackground = const Color(0xFF0F0F1B);
  final Color _surfaceColor = const Color(0xFF1A1A2E);

  // Controllers for address form
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _fetchWalletBalance(); // Add this new method call
    _calculateTotalPayment();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _addressesLoading = true;
    });

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

            // Select the first address by default
            if (_addresses.isNotEmpty) {
              final address = _addresses.first;
              _selectedAddress =
                  '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}';
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading addresses: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _addressesLoading = false;
      });
    }
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isWalletLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final walletDoc = await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user.uid)
            .get();

        // Check if wallet exists
        if (walletDoc.exists) {
          setState(() {
            _walletBalance = walletDoc.data()?['balance'] ?? 0.0;
          });
        } else {
          // Create wallet if it doesn't exist
          await FirebaseFirestore.instance
              .collection('wallets')
              .doc(user.uid)
              .set({'balance': 0.0});
          setState(() {
            _walletBalance = 0.0;
          });
        }
      }
    } catch (e) {
      print('Error fetching wallet balance: $e');
    } finally {
      setState(() {
        _isWalletLoading = false;
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
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT ADDRESS',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _neonBlue,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _neonPink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add new address button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddAddressDialog();
                },
                icon: Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'ADD NEW ADDRESS',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonPink,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white30),
              const SizedBox(height: 8),

              Text(
                'YOUR ADDRESSES',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: _neonBlue,
                ),
              ),

              const SizedBox(height: 16),

              _addresses.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No addresses available.\nPlease add one to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final address = _addresses[index];
                          final formattedAddress =
                              '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}';
                          final isSelected =
                              _selectedAddress == formattedAddress;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? _neonPink
                                    : Colors.grey.shade700,
                                width: 1.5,
                              ),
                              color: isSelected
                                  ? _neonPink.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: ListTile(
                              title: Text(
                                address['street'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'PixelFont',
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                '${address['city']}, ${address['state']}, ${address['country']} - ${address['postalCode']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'PixelFont',
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: _neonPink)
                                  : Icon(Icons.radio_button_unchecked,
                                      color: Colors.grey),
                              onTap: () {
                                setState(() {
                                  _selectedAddress = formattedAddress;
                                });
                                Navigator.pop(context);
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAddressDialog() {
    // Reset form controllers
    _streetController.clear();
    _cityController.clear();
    _stateController.clear();
    _countryController.clear();
    _postalCodeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ADD NEW ADDRESS',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _neonBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: _neonPink),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address form fields
                    _buildTextField(
                      controller: _streetController,
                      label: 'Street Address',
                      icon: Icons.home,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State/Province',
                            icon: Icons.map,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            icon: Icons.markunread_mailbox,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      icon: Icons.public,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveNewAddress(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _neonPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'SAVE ADDRESS',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
        prefixIcon: Icon(icon, color: _neonPink),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _neonBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Future<void> _saveNewAddress(BuildContext context) async {
    // Validate form
    if (_streetController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _countryController.text.isEmpty ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all address fields',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in to add an address',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Add new address to Firestore
      final addressData = {
        'street': _streetController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'postalCode': _postalCodeController.text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final addressRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add(addressData);

      // Update addresses list and select the new address
      setState(() {
        final newAddressMap = {
          'id': addressRef.id,
          ...addressData,
        };
        _addresses.add(newAddressMap);
        _selectedAddress =
            '${addressData['street']}, ${addressData['city']}, ${addressData['state']}, ${addressData['country']}';
      });

      // Close the modal
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Address added successfully',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add address: $e',
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
          _addressesLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading addresses...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Shipping address section
                    _buildSectionCard(
                      title: 'SHIPPING ADDRESS',
                      icon: Icons.location_on,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _selectedAddress.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _neonPink),
                                    color: _neonPink.withOpacity(0.1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning, color: _neonPink),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Please select an address to continue',
                                          style: TextStyle(
                                            fontFamily: 'PixelFont',
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  _selectedAddress,
                                  style: const TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  _addresses.isEmpty ? Icons.add : Icons.edit,
                                  color: _neonBlue,
                                  size: 16,
                                ),
                                label: Text(
                                  _addresses.isEmpty ? 'ADD ADDRESS' : 'CHANGE',
                                  style: const TextStyle(
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
               // Payment method section
_buildSectionCard(
  title: 'PAYMENT METHOD',
  icon: Icons.payment,
  child: Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Radio<String>(
          value: 'Card',
          groupValue: _selectedPaymentMethod,
          activeColor: _neonPink,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        title: const Text(
          'Credit/Debit Card',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Radio<String>(
          value: 'E-Wallet',
          groupValue: _selectedPaymentMethod,
          activeColor: _neonPink,
          onChanged: _walletBalance >= _totalPayment
              ? (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                }
              : null,
        ),
        title: Row(
          children: [
            const Text(
              'GameBox E-Wallet',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            _isWalletLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_neonPink),
                    ),
                  )
                : Text(
                    '(₱${_walletBalance.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 13,
                      color: _walletBalance >= _totalPayment
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
            if (_walletBalance < _totalPayment) ...[
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WalletPage()),
                  ).then((_) {
                    _fetchWalletBalance();
                  });
                },
                child: Icon(
                  Icons.add_circle_outline,
                  color: _neonPink,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
        subtitle: _walletBalance < _totalPayment
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Insufficient balance. Tap + to add funds.',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              )
            : null,
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Radio<String>(
          value: 'Cash on Delivery (COD)',
          groupValue: _selectedPaymentMethod,
          activeColor: _neonPink,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
        title: const Text(
          'Cash on Delivery (COD)',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 15,
            color: Colors.white,
          ),
        ),
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
                          const Divider(color: Colors.white30),
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
                    onPressed: _selectedAddress.isEmpty
                        ? null
                        : _showPaymentConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neonPink,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: const Text(
                      'PROCEED TO PAYMENT',
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

  Map<String, dynamic> _paymentDetails = {};
// Update this function in your CheckoutPage class
Future<void> _confirmOrder() async {
  // Validate that an address is selected
  if (_selectedAddress.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a shipping address')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Process e-wallet payment if selected
      if (_selectedPaymentMethod == 'E-Wallet') {
        await _processWalletPayment(user.uid);
      }

      // Generate a 12-digit order ID
      final random = Random();
      final orderId = List.generate(12, (_) => random.nextInt(10)).join();

      // Make sure all items have productId - this is the critical fix
      final itemsWithIds = await _ensureItemsHaveIds(widget.selectedItems);

      // Determine initial order status based on payment method
      String initialStatus;
      if (_selectedPaymentMethod == 'Cash on Delivery (COD)') {
        initialStatus = 'to ship'; // COD orders go directly to shipping
      } else {
        initialStatus = 'to pay'; // Card and E-wallet need payment first
      }

      // Create the order data
      final orderData = {
        'orderId': orderId,
        'totalPrice': _totalPayment,
        'paymentMethod': _selectedPaymentMethod,
        'paymentDetails': _paymentDetails,
        'shippingOption': _selectedShippingOption,
        'shippingAddress': _selectedAddress,
        'orderDate': DateTime.now().toIso8601String(),
        'items': itemsWithIds,
        'status': initialStatus,
        'userId': user.uid,
      };

      // Add the order to the user's orders collection
      final userOrdersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders');
      await userOrdersRef.add(orderData);

      // Add the order to the global orders collection
      final globalOrdersRef = FirebaseFirestore.instance.collection('orders');
      await globalOrdersRef.add(orderData);

      // Create notification
      String itemsText = widget.selectedItems.length == 1
          ? widget.selectedItems.first['title']
          : "${widget.selectedItems.first['title']} and ${widget.selectedItems.length - 1} more item(s)";

      String notificationMessage;
      if (_selectedPaymentMethod == 'Cash on Delivery (COD)') {
        notificationMessage = 'Your COD order for $itemsText has been placed and is being processed.';
      } else {
        notificationMessage = 'Your order for $itemsText has been placed and is awaiting payment.';
      }

      final notification = {
        'userId': user.uid,
        'type': 'orders',
        'title': 'Order #$orderId Placed Successfully',
        'message': notificationMessage,
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'imageUrl': widget.selectedItems.first['imageUrl'] ?? '',
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification);

      // Delete purchased items from cart
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final cartSnapshot = await cartRef.get();

      for (var item in widget.selectedItems) {
        final String purchasedTitle = item['title'] ?? '';
        for (var cartDoc in cartSnapshot.docs) {
          final cartData = cartDoc.data();
          if (cartData['title'] == purchasedTitle) {
            await cartRef.doc(cartDoc.id).delete();
            break;
          }
        }
      }

      if (mounted) {
        _showOrderSuccessDialog(orderId);
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to place order: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
// Add this method to handle wallet payments 
Future<bool> _processWalletPayment(String userId) async {
  try {
    // Check if wallet balance is sufficient
    if (_walletBalance < _totalPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Insufficient wallet balance',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Deduct payment from wallet
    final newBalance = _walletBalance - _totalPayment;
    
    // Update wallet balance in Firestore
    await FirebaseFirestore.instance
        .collection('wallets')
        .doc(userId)
        .update({'balance': newBalance});
    
    // Update local balance state
    setState(() {
      _walletBalance = newBalance;
    });
    
    // Add transaction record
    await FirebaseFirestore.instance
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .add({
          'type': 'payment',
          'amount': _totalPayment,
          'description': 'Payment for order - ${widget.selectedItems.length} items',
          'timestamp': FieldValue.serverTimestamp(),
          'balanceAfter': newBalance,
        });
    
    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Payment processed successfully from wallet',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.green,
      ),
    );
    
    return true;
  } catch (e) {
    print('Error processing wallet payment: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to process wallet payment: $e',
          style: const TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
}
// Add this new method to ensure all items have productId values
Future<List<Map<String, dynamic>>> _ensureItemsHaveIds(List<Map<String, dynamic>> items) async {
  List<Map<String, dynamic>> updatedItems = [];
  
  for (var item in items) {
    Map<String, dynamic> updatedItem = Map<String, dynamic>.from(item);
    
    // If productId is null or missing, generate a unique ID
    if (!item.containsKey('productId') || item['productId'] == null) {
      // Try to find product by title
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isEqualTo: item['title'])
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          // Use the found product's ID
          updatedItem['productId'] = querySnapshot.docs.first.id;
        } else {
          // Generate a fallback ID if product not found
          updatedItem['productId'] = 'generated-${DateTime.now().millisecondsSinceEpoch}-${updatedItems.length}';
        }
      } catch (e) {
        print('Error finding product by title: $e');
        // Generate a fallback ID if there's an error
        updatedItem['productId'] = 'generated-${DateTime.now().millisecondsSinceEpoch}-${updatedItems.length}';
      }
    }
    
    updatedItems.add(updatedItem);
  }
  
  return updatedItems;
}
  // Add this method after _confirmOrder
  void _showOrderSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: _neonPink,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your order #$orderId has been placed successfully.',
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Total Amount: \$${_totalPayment.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                color: _neonBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to OrderDetailsPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(
                    order: {
                      'orderId': orderId,
                      'totalPrice': _totalPayment,
                      'paymentMethod': _selectedPaymentMethod,
                      'shippingOption': _selectedShippingOption,
                      'shippingAddress': _selectedAddress,
                      'items': widget.selectedItems,
                      'status': 'to pay',
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonPink,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text(
              'VIEW ORDER DETAILS',
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

  void _showPaymentConfirmationDialog() {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a shipping address to proceed.',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Payment',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _neonPink,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Address:',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: _neonBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedAddress,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Method:',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: _neonBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPaymentMethod,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Payment:',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: _neonBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_totalPayment.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _neonPink,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_selectedPaymentMethod == 'Card') {
                  showDialog(
                    context: context,
                    builder: (context) => CardPaymentDialog(
                      neonPink: _neonPink,
                      neonBlue: _neonBlue,
                      surfaceColor: _surfaceColor,
                      onSubmit: (cardData) {
                        // Store the payment details for order creation
                        _paymentDetails = Map<String, dynamic>.from(cardData);

                        // Check if using saved card or new card
                        String paymentDetail;
                        if (cardData.containsKey('savedCard') &&
                            cardData['savedCard'] == 'true') {
                          // Using a saved card
                          paymentDetail =
                              'Payment processed using ${cardData['cardNickname']} (${cardData['bank']})';
                        } else {
                          // Using a new card
                          paymentDetail =
                              'Payment processed with ${cardData['bank']} card';
                        }

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              paymentDetail,
                              style: const TextStyle(fontFamily: 'PixelFont'),
                            ),
                            backgroundColor: _neonPink,
                          ),
                        );

                        // Proceed with order confirmation
                        _confirmOrder();
                      },
                    ),
                  );
                  return; // Prevent double dialog
                }
                _confirmOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonPink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Proceed',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _addSellerIdsToItems(
      List<Map<String, dynamic>> items) async {
    List<Map<String, dynamic>> updatedItems = [];
    for (var item in items) {
      if (item.containsKey('sellerId') && item['sellerId'] != null) {
        updatedItems.add(item);
      } else {
        // Fetch the product from Firestore to get the sellerId
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item['productId'])
            .get();
        final productData = productDoc.data();
        updatedItems.add({
          ...item,
          'sellerId': productData?['sellerId'] ?? '',
        });
      }
    }
    return updatedItems;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
