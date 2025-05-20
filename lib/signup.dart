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
  bool _obscureConfirmPassword = true; // Add this for confirm password visibility toggle
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
      Navigator.pop(context);
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
      showErrorDialog(
        context,
        'Google Sign-In Failed',
        'Failed to sign in with Google: ${e.toString()}'
      );
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SingleChildScrollView( // Wrap the body with SingleChildScrollView
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
                      Navigator.pop(context); // Navigate back to the previous screen
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: const TextStyle(
                        fontFamily: 'PixelFont', // Use the custom font
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: "Password",
                        hintStyle: const TextStyle(
                          fontFamily: 'PixelFont', // Use the custom font
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: "Confirm Password",
                        hintStyle: const TextStyle(
                          fontFamily: 'PixelFont', // Use the custom font
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                            border: Border.all(color: const Color(0xFFF43E69), width: 1),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: signInWithGoogle,
                            icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white), // Use FontAwesome icon
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
                            border: Border.all(color: const Color(0xFFF43E69), width: 1),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white), // Use FontAwesome icon
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