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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
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
            const SnackBar(content: Text('Profile updated successfully!')),
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
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontFamily: 'PixelFont'), // Apply PixelFont
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/default_profile.png'))
                            as ImageProvider,
                    child: _selectedImage == null && user?.photoURL == null
                        ? const Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 40,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'PixelFont', // Apply PixelFont
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Phone Number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your phone number',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'PixelFont', // Apply PixelFont
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Age',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your age',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'PixelFont', // Apply PixelFont
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gender',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
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
                dropdownColor: Colors.grey[800],
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont', // Apply PixelFont
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont', // Apply PixelFont
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}