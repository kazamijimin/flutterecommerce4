import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterecommerce4/authentication_page.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart'; // Make sure Firebase is initialized

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );
    await FirebaseAuth.instance.setLanguageCode('en'); // You can change 'en' to the language you need.

  runApp(   ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      theme: themeProvider.currentTheme,

      home: const AuthenticationPage(),
    );
  }
}
