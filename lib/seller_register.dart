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
      final String joinDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final sellerData = {
        'storeName': _storeNameController.text.trim(),
        'storeDescription': _storeDescriptionController.text.trim(),
        'userId': user.uid,
        'sellerStatus': 'pending', // Default status for new applications
        'createdAt': FieldValue.serverTimestamp(), // Add timestamp
        'joinDate': joinDate, // Add join date
        'role': 'seller', // Explicitly set role to seller
      };

      // First check if the user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userDoc.exists) {
        throw Exception("User profile not found. Please create a profile first.");
      }

      // Use a batch to ensure both operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();
      
      // Save the application in the sellerApplications collection
      batch.set(
        FirebaseFirestore.instance.collection('sellerApplications').doc(user.uid),
        sellerData
      );

      // Create a more minimal set of data for the user update
      final userUpdateData = {
        'role': 'seller',
        'sellerStatus': 'pending',
        'storeName': _storeNameController.text.trim(),
        'joinDate': joinDate,
      };

      // Update the user document with just seller-related fields
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        userUpdateData
      );
      
      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application submitted successfully!',
            style: TextStyle(fontFamily: 'PixelFont'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Navigate back to the previous screen
    } else {
      throw Exception("You must be logged in to submit a seller application");
    }
  } catch (e) {
    print("Error submitting seller application: $e"); // Add logging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to submit application: ${e.toString()}',
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
