import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import for icons
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordsMatch = true;
  bool _isLoading = false;
  bool _obscurePassword = true; // Add this for password visibility toggle
  bool _obscureConfirmPassword =
      true; // Add this for confirm password visibility toggle
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Add password validation variables
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Add this method to check password strength
  void _checkPassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void onSubmit() async {
    if (_isLoading) return;

    final emailAddress = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (emailAddress.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Check if password meets all requirements
    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigit || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password does not meet security requirements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _passwordsMatch = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _passwordsMatch = true;
      _isLoading = true;
    });

    try {
      await createUserWithEmailAndPassword(emailAddress, password);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> createUserWithEmailAndPassword(String emailAddress, String password) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      // Add the user to Firestore with minimal required fields
      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': emailAddress,
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': user.displayName ?? '',
          // Add any other fields you want
        });
      }

      // Show success dialog
      showSuccessDialog(
        context,
        'Account Created',
        'Your account has been created successfully. Welcome to the app!',
      );

      // Navigate to the HomePage after the dialog is dismissed
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Sign out from any previously signed-in Google account
      await _googleSignIn.signOut();

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      // Obtain the authentication details from the Google user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if the user is restricted
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['accountStatus'] == 'restricted') {
            // Log the user out since they're restricted
            await FirebaseAuth.instance.signOut();

            if (!mounted) return;

            // Replace the dialog with a simple message or alternative logic
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Your account is restricted.')),
            );
            return;
          }
        }
      }

      // If not restricted, navigate to the home page
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      showErrorDialog(context, 'Google Sign-In Failed',
          'Failed to sign in with Google: ${e.toString()}');
    }
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(color: Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelFont',
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'PixelFont',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'PixelFont',
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

  // Add a password requirements widget
  Widget _buildPasswordRequirements() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: const Color(0xFFF43E69).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'PixelFont',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirement('At least 8 characters', _hasMinLength),
          _buildRequirement('One uppercase letter', _hasUppercase),
          _buildRequirement('One lowercase letter', _hasLowercase),
          _buildRequirement('One number', _hasDigit),
          _buildRequirement('One special character', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.red.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.white70,
            fontSize: 12,
            fontFamily: 'PixelFont',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SingleChildScrollView(
        // Wrap the body with SingleChildScrollView
        child: Column(
          children: [
            // Cyberpunk city image with back button
            Stack(
              children: [
                Container(
                  height: 340,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/cyberpunk_city.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: 40, // Adjust the position as needed
                  left: 16,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(
                          context); // Navigate back to the previous screen
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            // Sign In text
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: const [
                  Text(
                    "Sign In",
                    style: TextStyle(
                      color: Color(0xFFF43E69),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PixelFont', // Use the custom font
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Sign in to continue shopping",
                    style: TextStyle(
                      color: Color(0xFFF43E69),
                      fontSize: 14,
                      fontFamily: 'PixelFont', // Use the custom font
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: const Color(0xFF161625), // Dark blue background
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email field
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontFamily: 'PixelFont', // Use the custom font
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: "Email",
                        hintStyle: TextStyle(
                          fontFamily: 'PixelFont', // Use the custom font
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  // Password field - updated with show/hide toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: _checkPassword, // Add this line
                      style: const TextStyle(
                        fontFamily: 'PixelFont', // Use the custom font
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: "Password",
                        hintStyle: const TextStyle(
                          fontFamily: 'PixelFont', // Use the custom font
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  // Password requirements widget
                  _buildPasswordRequirements(),

                  // Confirm Password field - updated with show/hide toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: !_passwordsMatch ? Colors.red : Colors.black,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontFamily: 'PixelFont', // Use the custom font
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: "Confirm Password",
                        hintStyle: const TextStyle(
                          fontFamily: 'PixelFont', // Use the custom font
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  // Submit button
                  Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0066),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : onSubmit,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                    ),
                  ),

                  // Error message for password mismatch
                  if (!_passwordsMatch)
                    const Text(
                      "Passwords don't match",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Sign in buttons
                  Row(
                    children: [
                      // Google button
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFF43E69), width: 1),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: signInWithGoogle,
                            icon: const FaIcon(FontAwesomeIcons.google,
                                color: Colors.white), // Use FontAwesome icon
                            label: const Text(
                              "Google",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'PixelFont', // Use the custom font
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Apple button
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFF43E69), width: 1),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const FaIcon(FontAwesomeIcons.apple,
                                color: Colors.white), // Use FontAwesome icon
                            label: const Text(
                              "iOS Apple",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'PixelFont', // Use the custom font
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Forgot password text
                  const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Color(0xFFF43E69),
                      fontSize: 14,
                      fontFamily: 'PixelFont', // Use the custom font
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
