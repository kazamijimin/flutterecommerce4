import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterecommerce4/authentication_page.dart';
import 'package:flutterecommerce4/home.dart'; // Import HomePage
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutterecommerce4/widgets/no_internet_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  RemoteNotification? notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_channel', 'Chat Messages',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.setLanguageCode('en');

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasInternet = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateConnectionStatus);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel', 'Chat Messages',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      print('Could not check connectivity status: ${e.toString()}');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _hasInternet = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: _hasInternet 
          ? _getInitialScreen()
          : Scaffold(
              backgroundColor: const Color(0xFF0F0F1B),
              body: NoInternetWidget(
                onRetry: _initConnectivity,
              ),
            ),
    );
  }

  Widget _getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in
    if (user != null) {
      return const HomePage(); // Redirect to HomePage if logged in
    } else {
      return const OnboardingCarousel(); // Show onboarding if not logged in
    }
  }
}

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: "Welcome to Cyber Shop",
      description: "Discover the future of shopping with exclusive neon-tech products",
      buttonText: "Next",
      backgroundGradient: const [Color(0xFF1A1A2E), Color(0xFF0F0F1B)],
      iconData: Icons.shopping_bag_outlined,
      onButtonPressed: () {},
    ),
    OnboardingSlide(
      title: "Discover Products",
      description: "Browse our extensive collection of futuristic tech and cyberpunk accessories",
      buttonText: "Explore",
      backgroundGradient: const [Color(0xFF16213E), Color(0xFF1A1A2E)],
      iconData: Icons.search,
      onButtonPressed: () {},
    ),
    OnboardingSlide(
      title: "Quick Checkout",
      description: "Secure payment methods and fast delivery to your location",
      buttonText: "Continue",
      backgroundGradient: const [Color(0xFF0F0F1B), Color(0xFF16213E)],
      iconData: Icons.flash_on,
      onButtonPressed: () {},
    ),
    OnboardingSlide(
      title: "Get Started",
      description: "Join our community of tech enthusiasts and start shopping now",
      buttonText: "Get Started",
      backgroundGradient: const [Color(0xFF0F0F1B), Color(0xFF1A1A2E)],
      iconData: Icons.login,
      onButtonPressed: () {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthenticationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for the carousel
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                slide: _slides[index],
                onButtonPressed: index == _slides.length - 1 
                    ? _navigateToAuth 
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
              );
            },
          ),
          
          // Version badge in corner
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0080),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "VERSION 2.0",
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          // Page indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? const Color(0xFFFF0080) 
                        : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Skip button
          Positioned(
            top: 40,
            left: 20,
            child: TextButton(
              onPressed: _navigateToAuth,
              child: const Text(
                "Skip",
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final String buttonText;
  final List<Color> backgroundGradient;
  final IconData iconData;
  final VoidCallback onButtonPressed;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.backgroundGradient,
    required this.iconData,
    required this.onButtonPressed,
  });
}

class OnboardingPage extends StatefulWidget {
  final OnboardingSlide slide;
  final VoidCallback onButtonPressed;

  const OnboardingPage({
    super.key,
    required this.slide,
    required this.onButtonPressed,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  
  @override
  void initState() {
    super.initState();
    
    // Setup glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.slide.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          // Neon grid effect overlay
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: NeonGridPainter(),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 120),
                
                // Icon with glow
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0080).withOpacity(0.3 + (_glowController.value * 0.4)),
                            spreadRadius: 2 + (_glowController.value * 5),
                            blurRadius: 10 + (_glowController.value * 15),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFFFF0080),
                              const Color(0xFF7928CA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Icon(
                            widget.slide.iconData,
                            size: 50,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // Title text
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF0080), Color(0xFFFF0080)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    widget.slide.title,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Description text
                Text(
                  widget.slide.description,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Button
                ElevatedButton(
                  onPressed: widget.onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0080),
                    foregroundColor: Colors.white,
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFFF0080).withOpacity(0.5),
                  ),
                  child: Text(
                    widget.slide.buttonText,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to create cyberpunk grid effect
class NeonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.08)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double i = 0; i < size.height; i += 25) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Vertical lines
    for (double i = 0; i < size.width; i += 25) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    
    // Add some random "neon" dots for that tech feel
    final dotPaint = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.4)
      ..strokeWidth = 2;
      
    // Add some random bright spots
    final random = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < 15; i++) {
      double x = ((random + i * i) % size.width.toInt()).toDouble();
      double y = ((random + i * i * i) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Call this after login
Future<void> saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }
}