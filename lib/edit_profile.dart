import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String gender = "Not specified"; // Default gender value
  File? _selectedImage; // To store the selected image
  final User? user = FirebaseAuth.instance.currentUser; // Get current user
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          nameController.text = data?['displayName'] ?? '';
          emailController.text = data?['email'] ?? '';
          phoneController.text = data?['phone'] ?? '';
          ageController.text = data?['age']?.toString() ?? '';
          gender = data?['gender'] ?? "Not specified";
        });
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Upload profile image to Firebase Storage and get download URL
  Future<String?> _uploadProfileImage(File image) async {
    try {
      // Create a unique file name for the uploaded image
      String fileName = 'profile_images/${user!.uid}_profile.jpg';

      // Reference to the file location in storage
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      // Upload the file
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL after successful upload
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Function to save profile changes
  Future<void> _saveProfileChanges() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (user != null) {
        // Update display name
        await user!.updateDisplayName(nameController.text);

        // Upload profile image if selected
        String? uploadedImageUrl;
        if (_selectedImage != null) {
          uploadedImageUrl = await _uploadProfileImage(_selectedImage!);
          if (uploadedImageUrl != null) {
            // Update the photoURL in Firebase Authentication
            await user!.updatePhotoURL(uploadedImageUrl);
            print('Profile picture updated: $uploadedImageUrl');
          }
        }

        // Save user details in Firestore
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user!.uid);
        await userDoc.set({
          'displayName': nameController.text,
          'email': emailController.text,
          'photoURL': uploadedImageUrl ?? user!.photoURL,
          'phone': phoneController.text,
          'age': int.tryParse(ageController.text) ?? 0,
          'gender': gender,
        }, SetOptions(merge: true));

        // Reload user to reflect changes
        await user!.reload();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Profile updated successfully!',
                style: TextStyle(fontFamily: 'PixelFont'),
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        // Navigate back to the ProfileScreen
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: const TextStyle(fontFamily: 'PixelFont'),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EDIT PROFILE',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0F0F1B),
                ],
              ),
            ),
          ),
          
          // Neon grid effect overlay
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: NeonGridPainter(),
          ),
          
          // Content
          _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF0080),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section with neon glow effect
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF0080).withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (user?.photoURL != null
                                          ? NetworkImage(user!.photoURL!)
                                          : const AssetImage('assets/default_profile.png'))
                                          as ImageProvider,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF0080),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF0080).withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Custom form fields with cyberpunk design
                      buildFormField(
                        label: 'NAME', 
                        controller: nameController, 
                        icon: Icons.person,
                      ),
                      
                      buildFormField(
                        label: 'PHONE', 
                        controller: phoneController, 
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      buildFormField(
                        label: 'AGE', 
                        controller: ageController, 
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Gender dropdown with cyberpunk design
                      Text(
                        'GENDER',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF0080).withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0080).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          items: const [
                            DropdownMenuItem(value: "Male", child: Text("Male")),
                            DropdownMenuItem(value: "Female", child: Text("Female")),
                            DropdownMenuItem(value: "Not specified", child: Text("Not specified")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              gender = value!;
                            });
                          },
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFF0080)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Save button with neon effect
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0080).withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveProfileChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF0080),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 36, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SAVE CHANGES',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'PixelFont',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.save, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
  
  Widget buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontFamily: 'PixelFont',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFF0080).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF0080).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'PixelFont',
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFFFF0080),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter to create cyberpunk grid effect
class NeonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.08)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Vertical lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    
    // Add some random "neon" dots for that tech feel
    final dotPaint = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.4)
      ..strokeWidth = 2;
      
    // Add random dots to simulate twinkling lights
    for (int i = 0; i < 30; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 53) % size.height;
      canvas.drawCircle(Offset(x, y), 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}