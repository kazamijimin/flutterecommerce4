import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescriptionController =
      TextEditingController();
  bool _isSubmitting = false;
  Future<void> _submitSellerApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the current date in "YYYY-MM-DD" format
        final DateTime now = DateTime.now();
        final String joinDate =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        final sellerData = {
          'storeName': _storeNameController.text.trim(),
          'storeDescription': _storeDescriptionController.text.trim(),
          'userId': user.uid,
          'sellerStatus': 'pending', // Default status for new applications
          'createdAt': FieldValue.serverTimestamp(), // Add timestamp
          'joinDate': joinDate, // Add join date
        };

        // Save the application in the sellerApplications collection
        await FirebaseFirestore.instance
            .collection('sellerApplications')
            .doc(user.uid)
            .set(sellerData);

        // Also update the users collection with the same data
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(sellerData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted! Waiting for approval...',
              style: TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Add slight delay before showing the dialog
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await _showApplicationPendingDialog();
          Navigator.pop(context); // Navigate back after dialog is dismissed
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit application: $e',
            style: const TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

// Add this new method to show pending status dialog
  Future<void> _showApplicationPendingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF13131A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.pink, width: 2),
          ),
          title: const Text(
            'Application Pending Review',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.hourglass_top,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Your seller application is pending approval',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Our team will review your application shortly. This usually takes 1-2 business days.',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'You can check your application status in your profile.',
                style: TextStyle(
                  color: Colors.cyan,
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                  ),
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
      appBar: AppBar(
        title: const Text(
          'Seller Registration',
          style: TextStyle(fontFamily: 'PixelFont'),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF13131A),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black45,
                  hintText: 'Enter your store name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Store name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Store Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeDescriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black45,
                  hintText: 'Describe your store',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.cyan),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Store description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSellerApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'PixelFont',
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
