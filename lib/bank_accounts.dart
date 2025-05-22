import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({Key? key}) : super(key: key);

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('paymentMethods')
            .get();

        setState(() {
          paymentMethods = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        throw 'User is not authenticated';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching payment methods: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addPaymentMethod(Map<String, dynamic> paymentMethod) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Add the last 4 digits field for display
        final cardNumber = paymentMethod['cardNumber'] as String;
        if (cardNumber.length >= 4) {
          paymentMethod['lastFourDigits'] = cardNumber.substring(cardNumber.length - 4);
        }
        
        // Mask the card number for security (store only last 4 digits)
        paymentMethod['cardNumber'] = '**** **** **** ${paymentMethod['lastFourDigits']}';

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('paymentMethods')
            .add(paymentMethod);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchPaymentMethods(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding payment method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePaymentMethod(String methodId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('paymentMethods')
            .doc(methodId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchPaymentMethods(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting payment method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddPaymentMethodDialog() {
    final TextEditingController bankController = TextEditingController();
    final TextEditingController cardNameController = TextEditingController();
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController cardHolderController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    
    String selectedCardType = 'Credit Card';
    List<String> cardTypes = ['Credit Card', 'Debit Card', 'Prepaid Card'];
    List<String> banks = [
      'Bank of Simulations',
      'Virtual Bank',
      'Test Bank',
      'Mock Bank',
      'Sample Bank',
      'Global Bank',
      'Digital Bank',
    ];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                'Add Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Type Selection
                    const Text(
                      'Card Type',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: selectedCardType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A2E),
                        underline: Container(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                        ),
                        items: cardTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCardType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bank Selection
                    const Text(
                      'Bank',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        hint: const Text(
                          'Select Bank',
                          style: TextStyle(color: Colors.grey),
                        ),
                        value: bankController.text.isEmpty ? null : bankController.text,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A2E),
                        underline: Container(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                        ),
                        items: banks.map((bank) {
                          return DropdownMenuItem<String>(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            bankController.text = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Card Name (alias for this card)
                    _buildTextField(
                      cardNameController, 
                      'Card Name (e.g., My Personal Card)', 
                      Icons.label
                    ),
                    
                    // Card Number
                    _buildTextField(
                      cardNumberController, 
                      'Card Number', 
                      Icons.credit_card,
                      isCardNumber: true
                    ),
                    
                    // Cardholder Name
                    _buildTextField(
                      cardHolderController, 
                      'Cardholder Name', 
                      Icons.person
                    ),
                    
                    // Expiry Date
                    _buildTextField(
                      expiryController, 
                      'Expiry Date (MM/YY)', 
                      Icons.date_range
                    ),
                    
                    // CVV
                    _buildTextField(
                      cvvController, 
                      'CVV', 
                      Icons.lock,
                      obscureText: true
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'PixelFont'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate inputs
                    if (bankController.text.isEmpty ||
                        cardNameController.text.isEmpty ||
                        cardNumberController.text.isEmpty ||
                        cardHolderController.text.isEmpty ||
                        expiryController.text.isEmpty ||
                        cvvController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Simple card number validation
                    if (cardNumberController.text.length < 16) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid card number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final newPaymentMethod = {
                      'cardType': selectedCardType,
                      'bank': bankController.text,
                      'cardName': cardNameController.text,
                      'cardNumber': cardNumberController.text,
                      'cardHolder': cardHolderController.text,
                      'expiryDate': expiryController.text,
                      'cvv': cvvController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    };
                    
                    _addPaymentMethod(newPaymentMethod);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool obscureText = false, bool isCardNumber = false}
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isCardNumber ? TextInputType.number : TextInputType.text,
        maxLength: isCardNumber ? 16 : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          prefixIcon: Icon(icon, color: Colors.pink, size: 20),
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'PixelFont',
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
      ),
    );
  }

  String _getCardTypeIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'credit card':
        return '💳';
      case 'debit card':
        return '💲';
      case 'prepaid card':
        return '🎁';
      default:
        return '💳';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAddPaymentMethodDialog,
            icon: const Icon(Icons.add, color: Colors.pink),
            label: const Text(
              'Add Method',
              style: TextStyle(
                color: Colors.pink,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.pink,
                ),
              )
            : paymentMethods.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.credit_card_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payment methods found',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add a credit/debit card for faster checkout',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddPaymentMethodDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add Payment Method',
                            style: TextStyle(fontFamily: 'PixelFont'),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCardTypeIcon(method['cardType'] ?? 'Credit Card'),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              method['cardName'] ?? 'Card',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'PixelFont',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8, 
                                                vertical: 2
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.pink.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                method['cardType'] ?? 'Card',
                                                style: const TextStyle(
                                                  color: Colors.pink,
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          method['cardNumber'] ?? '**** **** **** ****',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'PixelFont',
                                            fontSize: 16,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'CARDHOLDER',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  Text(
                                                    method['cardHolder'] ?? 'Name',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'EXPIRES',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  Text(
                                                    method['expiryDate'] ?? 'MM/YY',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          method['bank'] ?? 'Bank',
                                          style: const TextStyle(
                                            color: Colors.cyan,
                                            fontFamily: 'PixelFont',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _deletePaymentMethod(method['id']),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'PixelFont',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}