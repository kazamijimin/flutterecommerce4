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
        final DateTime now = DateTime.now();
        final String joinDate =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        final sellerData = {
          'storeName': _storeNameController.text.trim(),
          'storeDescription': _storeDescriptionController.text.trim(),
          'userId': user.uid,
          'sellerStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'joinDate': joinDate,
        };

        await FirebaseFirestore.instance
            .collection('sellerApplications')
            .doc(user.uid)
            .set(sellerData);

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

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await _showApplicationPendingDialog();
          Navigator.pop(context);
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

  Future<void> _showApplicationPendingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF13131A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.pink, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Pending Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your seller application is pending approval.\nOur team will review your application shortly. This usually takes 1-2 business days.',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PixelFont',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: use LayoutBuilder for width
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Registration',
          style: TextStyle(fontFamily: 'PixelFont', color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF13131A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          double formWidth = maxWidth < 500 ? maxWidth : 420;
          double horizontalPadding = maxWidth < 500 ? 16 : (maxWidth - formWidth) / 2;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
              child: Center(
                child: Container(
                  width: formWidth,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.pink.shade800, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/cyberpunk_city.jpg',
                                height: 90,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Become a Seller',
                                style: TextStyle(
                                  color: Color(0xFFFF0077),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Apply to open your own store and start selling!',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 14,
                                  fontFamily: 'PixelFont',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black45,
                            hintText: 'Enter your store name',
                            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'),
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
                        const SizedBox(height: 20),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                          ),
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black45,
                            hintText: 'Describe your store',
                            hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'PixelFont'),
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
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitSellerApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF0077),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
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
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
