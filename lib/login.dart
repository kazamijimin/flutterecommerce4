import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'forgot_password.dart'; // Add this import
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import for icons
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart'; // Add this import

class Login extends StatefulWidget {
  final bool isSignUp;

  const Login({Key? key, this.isSignUp = false}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _obscurePassword = true; // Add this for password visibility toggle
  bool _isLoading = false;
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

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
      showErrorDialog(context, 'Missing Information',
          'Please fill in both email and password fields to continue.');
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

  void showAccountRestrictedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.pink[400]!, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Restricted',
                  style: TextStyle(
                    color: Colors.pink[400],
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
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your account has been restricted.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reason: $reason',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[400]!, Colors.purple[900]!],
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

  void showPasswordErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.red[700]!, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Invalid Password',
                  style: TextStyle(
                    color: Colors.red[400],
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
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'The password you entered is incorrect.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Please try again or reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[800]!, Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 45,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan[700]!, Colors.cyan[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ForgotPassword()),
                            );
                          },
                          child: const Text(
                            'Reset Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAccountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.red[700]!, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Deletion Pending',
                  style: TextStyle(
                    color: Colors.red[400],
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
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'This account has been scheduled for deletion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'If you believe this is an error, please contact customer support immediately.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'PixelFont',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[600]!),
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
                        fontSize: 14,
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

  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.red[700]!, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.red[400],
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
                    border: Border.all(color: Colors.red, width: 1),
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
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Future<void> signInWithEmailAndPassword(
      String emailAddress, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      // Check if the user is restricted or has an approved deletion request
      final user = credential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            // Check for account restriction
            if (userData['accountStatus'] == 'restricted') {
              // Log the user out since they're restricted
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              // Show custom restriction dialog with reason
              final reason =
                  userData['restrictionReason'] ?? 'Violation of terms';
              showAccountRestrictedDialog(context, reason);
              return;
            }

            // Check for approved deletion request
            final deletionRequestQuery = await FirebaseFirestore.instance
                .collection('deletion_requests')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'approved')
                .get();

            if (deletionRequestQuery.docs.isNotEmpty) {
              // Log the user out since their account is pending deletion
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              // Show account deletion dialog
              showAccountDeletionDialog(context);
              return;
            }
          }
        }
      }

      // If not restricted or pending deletion, navigate to the home page
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle other authentication exceptions as before
      if (e.code == 'user-not-found') {
        showErrorDialog(context, 'User Not Found',
            'No user account exists with this email address. Please check your email or create a new account.');
      } else if (e.code == 'wrong-password') {
        // Show the custom password error dialog with "Invalid Password" title
        showPasswordErrorDialog(context);
      } else if (e.code == 'invalid-email') {
        showErrorDialog(context, 'Invalid Email',
            'The email address format is invalid. Please enter a valid email address.');
      } else if (e.code == 'user-disabled') {
        showErrorDialog(context, 'Account Disabled',
            'This account has been disabled. Please contact support for assistance.');
      } else if (e.code == 'too-many-requests') {
        showErrorDialog(context, 'Too Many Attempts',
            'Access to this account has been temporarily disabled due to many failed login attempts. Please try again later.');
      } else {
        showErrorDialog(context, 'Login Error',
            'An error occurred during login: ${e.message}');
      }
    } catch (e) {
      showErrorDialog(context, 'Unexpected Error',
          'An unexpected error occurred. Please try again later.');
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

      // Check if the user is restricted or has an approved deletion request
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            // Check for account restriction
            if (userData['accountStatus'] == 'restricted') {
              // Log the user out since they're restricted
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              // Show restriction dialog with reason
              final reason =
                  userData['restrictionReason'] ?? 'Violation of terms';
              showAccountRestrictedDialog(context, reason);
              return;
            }

            // Check for approved deletion request
            final deletionRequestQuery = await FirebaseFirestore.instance
                .collection('deletion_requests')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'approved')
                .get();

            if (deletionRequestQuery.docs.isNotEmpty) {
              // Log the user out since their account is pending deletion
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              // Show account deletion dialog
              showAccountDeletionDialog(context);
              return;
            }
          }
        }
      }

      // If not restricted or pending deletion, navigate to the home page
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

  Future<void> signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign In not implemented yet')),
    );
  }

  void _toggleAuthMode() {
    if (_isSignUp) {
      // If already in sign up mode, toggle back to login
      setState(() {
        _isSignUp = false;
      });
    } else {
      // If in login mode, navigate to dedicated signup screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Signup()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 380;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Cyberpunk city image with responsive height
                SizedBox(
                  height: screenSize.height * (isSmallScreen ? 0.35 : 0.4),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/cyberpunk_city.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Sign in container
                Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Title section with responsive padding
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 15 : 20,
                          horizontal: isSmallScreen ? 10 : 20,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isSignUp ? "Create Account" : "Log in",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[400],
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? "Sign up to start your gaming journey"
                                  : "Log in to continue shopping",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.pink[200],
                                fontFamily: 'PixelFont',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Form section with responsive padding
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
                          padding: EdgeInsets.fromLTRB(screenSize.width * 0.05,
                              16, screenSize.width * 0.05, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email TextField
                              Container(
                                height: isSmallScreen ? 45 : 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'PixelFont',
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'PixelFont',
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 12),

                              // Password TextField with corrected alignment
                              Container(
                                height: isSmallScreen ? 45 : 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDDDDD),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'PixelFont',
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    hintStyle: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'PixelFont',
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isSmallScreen ? 12 : 14),
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black54,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    isDense:
                                        true, // This helps with vertical alignment
                                    alignLabelWithHint:
                                        true, // This helps align the hint text properly
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),

                              // Submit button with responsive height
                              Container(
                                width: double.infinity,
                                height: isSmallScreen ? 50 : 56,
                                margin: EdgeInsets.only(
                                    bottom: isSmallScreen ? 20 : 24),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF0066),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextButton(
                                  onPressed: _isLoading ? null : onSubmit,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black),
                                        )
                                      : Text(
                                          'LOG IN',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            letterSpacing: 1.5,
                                            fontFamily: 'PixelFont',
                                          ),
                                        ),
                                ),
                              ),

                              // Social login buttons with responsive height
                              Row(
                                children: [
                                  // Google Sign In button
                                  Expanded(
                                    child: Container(
                                      height: isSmallScreen ? 40 : 44,
                                      margin: const EdgeInsets.only(right: 6),
                                      child: OutlinedButton.icon(
                                        onPressed: signInWithGoogle,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(
                                              color: Colors.pink[400]!,
                                              width: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        icon: Icon(
                                          FontAwesomeIcons.google,
                                          size: isSmallScreen ? 14 : 16,
                                        ),
                                        label: Text(
                                          "Google",
                                          style: TextStyle(
                                            fontFamily: 'PixelFont',
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Apple Sign In button
                                  Expanded(
                                    child: Container(
                                      height: isSmallScreen ? 40 : 44,
                                      margin: const EdgeInsets.only(left: 6),
                                      child: OutlinedButton.icon(
                                        onPressed: signInWithApple,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(
                                              color: Colors.pink[400]!,
                                              width: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        icon: Icon(
                                          FontAwesomeIcons.apple,
                                          size: isSmallScreen ? 14 : 16,
                                        ),
                                        label: Text(
                                          "iOS Apple",
                                          style: TextStyle(
                                            fontFamily: 'PixelFont',
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 12),

                              // Forgot password link with responsive font size
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPassword()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.pink[400],
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontFamily: 'PixelFont',
                                    ),
                                  ),
                                ),
                              ),

                              // Toggle between login and signup with responsive font size
                              TextButton(
                                onPressed: _toggleAuthMode,
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Log in'
                                      : 'Need an account? Sign up',
                                  style: TextStyle(
                                    color: Colors.cyan,
                                    fontFamily: 'PixelFont',
                                    fontSize: isSmallScreen ? 12 : 14,
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

          // Back button overlay with responsive position
          Positioned(
            top: MediaQuery.of(context).padding.top + (isSmallScreen ? 5 : 10),
            left: isSmallScreen ? 10 : 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
