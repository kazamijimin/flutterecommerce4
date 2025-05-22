import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardPaymentDialog extends StatefulWidget {
  final Color neonPink;
  final Color neonBlue;
  final Color surfaceColor;
  final void Function(Map<String, String>) onSubmit;

  const CardPaymentDialog({
    super.key,
    required this.neonPink,
    required this.neonBlue,
    required this.surfaceColor,
    required this.onSubmit,
  });

  @override
  State<CardPaymentDialog> createState() => _CardPaymentDialogState();
}

class _CardPaymentDialogState extends State<CardPaymentDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedCards = [];
  Map<String, dynamic>? _selectedCard;
  bool _useNewCard = false;
  
  // Controllers for new card form
  final _formKey = GlobalKey<FormState>();
  String _selectedBank = 'Bank of Simulations';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSavedCards();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNicknameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('paymentMethods')
            .orderBy('timestamp', descending: true)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _savedCards = snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();
            
            // Select the first card by default
            if (_savedCards.isNotEmpty) {
              _selectedCard = _savedCards.first;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching saved cards: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddCardForm() {
    setState(() {
      _useNewCard = true;
      _selectedCard = null;
    });
  }

  Future<void> _saveNewCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get last 4 digits of card number
        final cardNumber = _cardNumberController.text;
        final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
        
        // Prepare payment method data
        final paymentMethodData = {
          'cardType': 'Credit Card',
          'bank': _selectedBank,
          'cardNickname': _cardNicknameController.text.isNotEmpty 
              ? _cardNicknameController.text 
              : '$_selectedBank Card',
          'cardNumber': '**** **** **** $lastFourDigits',
          'lastFourDigits': lastFourDigits,
          'cardHolder': _cardHolderController.text,
          'expiryDate': _expiryController.text,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Add to Firestore
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('paymentMethods')
            .add(paymentMethodData);
        
        // Add the document ID to the data
        final newCard = {
          'id': docRef.id,
          ...paymentMethodData,
        };
        
        // Update state and select the new card
        setState(() {
          _savedCards.insert(0, newCard);
          _selectedCard = newCard;
          _useNewCard = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Card added successfully',
              style: TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add card: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.neonPink),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading payment methods...',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PAYMENT METHOD',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.neonBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: widget.neonPink),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Main content - Either card selection or new card form
                  _useNewCard
                      ? _buildNewCardForm()
                      : _buildCardSelection(),
                      
                  const SizedBox(height: 16),
                  
                  // Action buttons at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_useNewCard) {
                            _saveNewCard();
                          } else if (_selectedCard != null) {
                            widget.onSubmit({
                              'bank': _selectedCard!['bank'] ?? 'Unknown Bank',
                              'cardNumber': _selectedCard!['cardNumber'] ?? '**** **** **** ****',
                              'cardHolder': _selectedCard!['cardHolder'] ?? 'Card Owner',
                              'savedCard': 'true',
                              'cardId': _selectedCard!['id'],
                              'cardNickname': _selectedCard!['cardNickname'] ?? 
                                            _selectedCard!['cardName'] ?? 'Saved Card',
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a card',
                                  style: TextStyle(fontFamily: 'PixelFont'),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.neonPink,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          _useNewCard ? 'Save & Use' : 'Confirm',
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildCardSelection() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Button to add new card
          ElevatedButton.icon(
            onPressed: _showAddCardForm,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'ADD NEW CARD',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.neonPink,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 8),
          
          Text(
            'YOUR SAVED CARDS',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: widget.neonBlue,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _savedCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No cards available.\nPlease add one to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                )
              : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _savedCards.length,
                    itemBuilder: (context, index) {
                      final card = _savedCards[index];
                      final isSelected = _selectedCard == card;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                                ? widget.neonPink 
                                : Colors.grey.shade700,
                            width: 1.5,
                          ),
                          color: isSelected
                              ? widget.neonPink.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.neonPink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.credit_card,
                              color: widget.neonPink,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            card['cardNickname'] ?? card['cardName'] ?? 'Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PixelFont',
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card['cardNumber'] ?? '**** **** **** ****',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'PixelFont',
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${card['bank'] ?? 'Bank'} • Expires: ${card['expiryDate'] ?? 'MM/YY'}',
                                style: TextStyle(
                                  color: widget.neonBlue,
                                  fontFamily: 'PixelFont',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: widget.neonPink)
                              : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                          onTap: () {
                            setState(() {
                              _selectedCard = card;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildNewCardForm() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _useNewCard = false;
                      });
                    },
                  ),
                  Text(
                    'ADD NEW CARD',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.neonBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Bank selection
              const Text(
                'Bank',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.black26,
                ),
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  dropdownColor: widget.surfaceColor,
                  underline: Container(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                  ),
                  items: [
                    'Bank of Simulations',
                    'Virtual Bank',
                    'Test Bank',
                    'Mock Bank',
                    'Sample Bank',
                    'Global Bank',
                    'Digital Bank',
                  ].map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBank = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Card nickname
              TextFormField(
                controller: _cardNicknameController,
                style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                decoration: InputDecoration(
                  labelText: 'Card Nickname (optional)',
                  labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
                  prefixIcon: Icon(Icons.label, color: widget.neonPink),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.neonBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                ),
              ),
              const SizedBox(height: 16),
              
              // Card number
              TextFormField(
                controller: _cardNumberController,
                style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
                  prefixIcon: Icon(Icons.credit_card, color: widget.neonPink),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.neonBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) =>
                    value == null || value.length != 16 ? 'Enter 16-digit card number' : null,
              ),
              const SizedBox(height: 16),
              
              // Card holder name
              TextFormField(
                controller: _cardHolderController,
                style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
                  prefixIcon: Icon(Icons.person, color: widget.neonPink),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.neonBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter cardholder name' : null,
              ),
              const SizedBox(height: 16),
              
              // Expiry date and CVV in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
                        prefixIcon: Icon(Icons.calendar_today, color: widget.neonPink),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.neonBlue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        counterText: '',
                      ),
                      keyboardType: TextInputType.datetime,
                      maxLength: 5,
                      validator: (value) =>
                          value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)
                              ? 'Format MM/YY'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'PixelFont'),
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'PixelFont'),
                        prefixIcon: Icon(Icons.lock, color: widget.neonPink),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.neonBlue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.length != 3 ? 'Enter 3-digit CVV' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}