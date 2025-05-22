import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/message_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double walletBalance = 0.0;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  bool isProcessing = false; // Add flag to prevent multiple transactions
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch wallet balance
      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .get();

      // Create wallet document if it doesn't exist
      if (!walletDoc.exists) {
        await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user.uid)
            .set({'balance': 0.0});
      }

      // Fetch transaction history
      final transactionsQuery = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        walletBalance = walletDoc.data()?['balance'] ?? 0.0;
        transactions = transactionsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'amount': data['amount'] ?? 0.0,
            'type': data['type'] ?? 'Unknown',
            'description': data['description'] ?? '',
            'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching wallet data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addBalance(double amount, String paymentMethod) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Prevent multiple transactions
    if (isProcessing) return;

    setState(() {
      isLoading = true;
      isProcessing = true;
    });

    try {
      // Update wallet balance in Firestore
      final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
      
      // Check if wallet exists and create if needed
      final walletDoc = await walletRef.get();
      if (!walletDoc.exists) {
        await walletRef.set({'balance': 0.0});
      }
      
      // Use a transaction to ensure atomicity
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);
        final currentBalance = walletDoc.data()?['balance'] ?? 0.0;
        transaction.update(walletRef, {'balance': currentBalance + amount});
      });

      // Add transaction record
      await walletRef.collection('transactions').add({
        'amount': amount,
        'type': 'credit',
        'description': 'Added via $paymentMethod',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success message
      MessageService.showGameMessage(
        context,
        message: 'Successfully added ₱${amount.toStringAsFixed(2)} to your wallet!',
        isSuccess: true,
      );

      // Refresh wallet data
      _fetchWalletData();
      _amountController.clear();
    } catch (e) {
      print('Error adding balance: $e');
      setState(() {
        isLoading = false;
        isProcessing = false;
      });
      
      // Show error message
      MessageService.showGameMessage(
        context,
        message: 'Failed to add balance. Please try again.',
        isSuccess: false,
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showAddBalanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Text(
                  'ADD BALANCE',
                  style: TextStyle(
                    color: Color.fromARGB(255, 212, 0, 0),
                    fontSize: 20,
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'PixelFont',
                  ),
                  prefixText: '₱ ',
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 212, 0, 0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick amount selection
              const Text(
                'QUICK SELECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmountButton(100),
                  _buildQuickAmountButton(500),
                  _buildQuickAmountButton(1000),
                ],
              ),
              const SizedBox(height: 24),
              
              // Payment method selection
              const Text(
                'PAYMENT METHOD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPaymentMethodButton(
                    'GCash',
                    Icons.account_balance_wallet,
                    Colors.pink,
                  ),
                  _buildPaymentMethodButton(
                    'Credit Card',
                    Icons.credit_card,
                    Color.fromARGB(255, 212, 0, 0),
                  ),
                  _buildPaymentMethodButton(
                    'PayMaya',
                    Icons.payment,
                    Colors.pink.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildQuickAmountButton(double amount) {
    return InkWell(
      onTap: () {
        setState(() {
          _amountController.text = amount.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Text(
          '₱${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethodButton(String method, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        if (_amountController.text.isEmpty) {
          MessageService.showGameMessage(
            context,
            message: 'Please enter an amount first',
            isSuccess: false,
          );
          return;
        }
        
        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) {
          MessageService.showGameMessage(
            context,
            message: 'Please enter a valid amount',
            isSuccess: false,
          );
          return;
        }
        
        Navigator.pop(context);
        _showPaymentConfirmation(amount, method);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: color),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            method,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPaymentConfirmation(double amount, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Confirm Payment',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PixelFont',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add ₱${amount.toStringAsFixed(2)} to your wallet via $method?',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a demo functionality. No actual payment will be processed.',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'PixelFont',
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 212, 0, 0),
            ),
            onPressed: () {
              Navigator.pop(context);
              _addBalance(amount, method);
            },
            child: const Text(
              'CONFIRM',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PixelFont',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Wallet',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 212, 0, 0)),
            )
          : Column(
              children: [
                // Wallet Balance Card
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF880E4F), Color(0xFFC2185B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GameBox Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'PixelFont',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Image.asset(
                            'assets/images/wallet_icon.png',
                            height: 30,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWalletAction(
                            icon: Icons.add,
                            label: 'Add Money',
                            onTap: _showAddBalanceModal,
                          ),
                          _buildWalletAction(
                            icon: Icons.refresh,
                            label: 'Refresh',
                            onTap: _fetchWalletData,
                          ),
                          _buildWalletAction(
                            icon: Icons.history,
                            label: 'History',
                            onTap: () {
                              // Scroll to transactions
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction History
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TRANSACTION HISTORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${transactions.length} records',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Colors.grey.shade700,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add money to your wallet to get started',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final DateTime date = transaction['timestamp'];
                            final String formattedDate = 
                                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: transaction['type'] == 'credit'
                                        ? Color.fromARGB(255, 212, 0, 0).withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    transaction['type'] == 'credit'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: transaction['type'] == 'credit'
                                        ? Color.fromARGB(255, 212, 0, 0)
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  transaction['description'] != ''
                                      ? transaction['description']
                                      : transaction['type'] == 'credit'
                                          ? 'Added to Wallet'
                                          : 'Spent',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PixelFont',
                                  ),
                                ),
                                subtitle: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'PixelFont',
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  transaction['type'] == 'credit'
                                      ? '+₱${transaction['amount'].toStringAsFixed(2)}'
                                      : '-₱${transaction['amount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: transaction['type'] == 'credit'
                                        ? Color.fromARGB(255, 212, 0, 0)
                                        : Colors.red,
                                    fontFamily: 'PixelFont',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildWalletAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'PixelFont',
            ),
          ),
        ],
      ),
    );
  }
}