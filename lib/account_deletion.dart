import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({Key? key}) : super(key: key);

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _agreeToDeletion = false;
  String _deleteReason = '';
  final TextEditingController _passwordController = TextEditingController();
  final List<String> _deletionReasons = [
    'I created a new account',
    'I don\'t use GameBox anymore',
    'I\'m having technical issues',
    'I\'m concerned about my data privacy',
    'I don\'t find the games interesting',
    'App performance is poor on my device',
    'Other reason'
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletionRequest() async {
    if (!_formKey.currentState!.validate() || !_agreeToDeletion) {
      if (!_agreeToDeletion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm that you understand the consequences of account deletion'),
            backgroundColor: Color(0xFFFF0077),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify password
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get the user's email
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Reauthenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Store deletion request in Firestore
      await FirebaseFirestore.instance.collection('deletion_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'reason': _deleteReason,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFFF0077),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Request Received',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account deletion request has been submitted successfully.',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What happens next:',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Our team will review your request within 7 days\n'
                '• You\'ll receive a confirmation email when processing begins\n'
                '• Your account and data will be permanently deleted\n'
                '• This process cannot be reversed once completed',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to settings
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'ACCOUNT DELETION',
          style: TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0077).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFFFF0077),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF0077),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'WARNING',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF0077),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Account deletion is permanent and cannot be undone. When you delete your account:',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• All your personal data will be permanently deleted\n'
                      '• You will lose access to all purchased games and content\n'
                      '• Your in-game progress and achievements will be lost\n'
                      '• Any store credit or unused balances will be forfeit\n'
                      '• You cannot recover this account after deletion',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'REASON FOR DELETION',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Dropdown for deletion reason
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Select a reason',
                    hintStyle: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                  ),
                  dropdownColor: const Color(0xFF1A1A2E),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF00E5FF),
                  ),
                  items: _deletionReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _deleteReason = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a reason';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'CONFIRM WITH YOUR PASSWORD',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your password to confirm your identity',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Checkbox for confirmation
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToDeletion,
                        onChanged: (bool? value) {
                          setState(() {
                            _agreeToDeletion = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFFF0077),
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I understand that deleting my account is permanent and all my data, purchases, and progress will be permanently lost. This action cannot be undone.',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDeletionRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0077),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'REQUEST ACCOUNT DELETION',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Having technical issues? Contact support instead',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to help center
                    Navigator.pushNamed(context, '/help_center');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                  ),
                  child: const Text(
                    'CONTACT SUPPORT',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}