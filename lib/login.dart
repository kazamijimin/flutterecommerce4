import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'forgot_password.dart'; // Add this import
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import for icons
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onSubmit() async {
    if (_isLoading) return;

    final emailAddress = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (emailAddress.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await signInWithEmailAndPassword(emailAddress, password);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithEmailAndPassword(String emailAddress, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid password';
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

// Google sign-in
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
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credentials
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // If successful, navigate to the homepage
    if (userCredential.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google Sign-In failed: $e')),
    );
  }
}

  Future<void> signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign In not implemented yet')),
    );
  }

  // ...existing code...

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SingleChildScrollView( // Wrap the body with SingleChildScrollView
      child: Column(
        children: [
          // Cyberpunk city image with back button
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // Adjust height dynamically
            child: Stack(
              children: [
                Container(
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
          ),
          
          // Sign in container
          Container(
            color: Colors.black,
            width: double.infinity,
            child: Column(
              children: [
                // Title section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        "Log in",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[400],
                          fontFamily: 'PixelFont', // Use a pixel-like font
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Log in to continue shopping",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.pink[200],
                          fontFamily: 'PixelFont', // Use a pixel-like font
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form section with gray divider
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFF333333),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email TextField - Styled like pixel art
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDDDDD),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'PixelFont',
                            ),
                            decoration: const InputDecoration(
                              hintText: "Email",
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'PixelFont',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Password TextField - Styled like pixel art
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDDDDD),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'PixelFont',
                            ),
                            decoration: const InputDecoration(
                              hintText: "Password",
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'PixelFont',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Submit button
                        Container(
                          width: double.infinity,
                          height: 56,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF0066),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextButton(
                            onPressed: _isLoading ? null : onSubmit,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  )
                                : const Text(
                                    'LOG IN',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                      fontFamily: 'PixelFont',
                                    ),
                                  ),
                          ),
                        ),
                        
                        // Social login buttons
                        Row(
                          children: [
                            // Google Sign In button
                            Expanded(
                              child: Container(
                                height: 44,
                                margin: const EdgeInsets.only(right: 6),
                                child: OutlinedButton.icon(
                                  onPressed: signInWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: Colors.pink[400]!, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  icon: const Icon(
                                    FontAwesomeIcons.google, 
                                    size: 16,
                                  ),
                                  label: const Text(
                                    "Google",
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Apple Sign In button
                            Expanded(
                              child: Container(
                                height: 44,
                                margin: const EdgeInsets.only(left: 6),
                                child: OutlinedButton.icon(
                                  onPressed: signInWithApple,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: Colors.pink[400]!, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  icon: const Icon(
                                    FontAwesomeIcons.apple, 
                                    size: 16,
                                  ),
                                  label: const Text(
                                    "iOS Apple",
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Forgot password link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPassword()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.pink[400],
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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