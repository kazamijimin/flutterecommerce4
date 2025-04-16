import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TERMS AND CONDITIONS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Here are the terms and conditions of using this application...\n\n'
            '1. You agree to use this app responsibly.\n'
            '2. All data provided must be accurate.\n'
            '3. The app is not liable for any misuse.\n'
            '4. Terms are subject to change without notice.\n\n'
            'For more details, contact support.',
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF0F0F1B),
    );
  }
}