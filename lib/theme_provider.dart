import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: const Color(0xFFFF0077),
            scaffoldBackgroundColor: const Color(0xFF0F0F1B),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(0xFF009688),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
            ),
          );
  }
}