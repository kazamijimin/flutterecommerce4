import 'package:flutter/material.dart';

class GuestActionBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final String message;
  
  const GuestActionBar({
    Key? key,
    required this.onLogin,
    required this.onSignup,
    this.message = 'Sign in to unlock all features',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'PixelFont',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('LOG IN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSignup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan,
                    side: const BorderSide(color: Colors.cyan),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('SIGN UP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}