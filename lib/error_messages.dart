import 'package:flutter/material.dart';

class MessageService {
  static void showGameMessage(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    int durationSeconds = 3,
    VoidCallback? onTap,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    
    // Determine color scheme based on success/error
    final Color backgroundColor = isSuccess 
        ? const Color(0xFF0D2B45).withOpacity(0.95)
        : const Color(0xFF380000).withOpacity(0.95);
    final Color borderColor = isSuccess 
        ? Colors.cyan 
        : const Color(0xFFFF3860);
    final Color textColor = Colors.white;
    final IconData icon = isSuccess 
        ? Icons.check_circle_outline 
        : Icons.error_outline;
    
    scaffold.showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            scaffold.hideCurrentSnackBar();
            if (onTap != null) onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(icon, color: borderColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontFamily: 'PixelFont',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.close,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: durationSeconds),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}