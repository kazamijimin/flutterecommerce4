import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> with SingleTickerProviderStateMixin {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'HOW DO I CREATE AN ACCOUNT?',
      answer: 'To create an account, tap on the Profile icon at the bottom right of the screen, then select "Sign Up". Fill in your email, password, and other required information to complete the registration process.',
    ),
    FAQItem(
      question: 'HOW DO I ADD GAMES TO MY WISHLIST?',
      answer: 'To add a game to your wishlist, navigate to the game\'s details page and tap the heart icon. You can view your wishlist by tapping the heart icon in the top navigation bar or through your profile page.',
    ),
    FAQItem(
      question: 'WHAT PAYMENT METHODS DO YOU ACCEPT?',
      answer: 'We accept credit/debit cards (Visa, Mastercard), PayPal, GCash, and various e-wallets. All payment methods are secure and encrypted for your protection.',
    ),
    FAQItem(
      question: 'HOW DO I DOWNLOAD MY PURCHASED GAMES?',
      answer: 'After purchasing a game, it will appear in your Library. Go to "MENU" > "Library" to see all your purchases. Select the game and tap "Download" to begin the installation process.',
    ),
    FAQItem(
      question: 'ARE THERE REFUNDS AVAILABLE?',
      answer: 'Refunds are available within 14 days of purchase if you have not downloaded or played the game for more than 2 hours. To request a refund, go to your purchase history in your profile and select "Request Refund" for the specific game.',
    ),
    FAQItem(
      question: 'HOW CAN I CHANGE MY PASSWORD?',
      answer: 'To change your password, go to your Profile, tap on "Settings", then select "Security". From there, you can update your password by entering your current password and creating a new one.',
    ),
    FAQItem(
      question: 'WHAT ARE THE SYSTEM REQUIREMENTS?',
      answer: 'System requirements vary by game. Each game\'s detail page includes the minimum and recommended system requirements. Make sure your device meets these requirements before purchasing.',
    ),
    FAQItem(
      question: 'HOW DO I CONTACT CUSTOMER SUPPORT?',
      answer: 'You can contact our customer support team through the "Support" section in your profile or by sending an email to support@gamebox.com. Our team is available 24/7 to assist you with any issues.',
    ),
  ];

  // Animation controller for the pixel glitch effect
  late AnimationController _glitchController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Start the looping glitch animation
    _glitchController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  // Function to create pixel font text style
  TextStyle pixelFontStyle({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontFamily: 'PixelFont',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'PixelFont',
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              // Apply a subtle glitch effect to the title
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.cyan.withOpacity(_glitchController.value * 0.8 + 0.2),
                      Colors.white,
                      Colors.pink.withOpacity((1 - _glitchController.value) * 0.8 + 0.2),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: Text(
                  'FAQ',
                  style: pixelFontStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Pixel art decorative header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900,
                    Colors.purple.shade900,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: pixelFontStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
            ),
            
            // Stylized divider
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade800,
                    Colors.purple.shade800,
                    Colors.blue.shade800,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // FAQ List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _faqItems.length,
                itemBuilder: (context, index) {
                  final isExpanded = _expandedIndex == index;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      border: Border.all(
                        color: isExpanded ? Colors.cyan : Colors.pink.shade800,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedIndex = expanded ? index : -1;
                            
                            // Play a quick glitch animation when expanding/collapsing
                            if (expanded) {
                              _glitchController.forward(from: 0.0);
                              _glitchController.repeat(reverse: true);
                            }
                          });
                        },
                        collapsedIconColor: Colors.cyan,
                        iconColor: Colors.pink,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        title: Text(
                          _faqItems[index].question,
                          style: pixelFontStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExpanded ? Colors.cyan : Colors.white,
                          ),
                        ),
                        children: [
                          // Pixel-style divider
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.cyan.withOpacity(0.2), 
                                  Colors.cyan, 
                                  Colors.cyan.withOpacity(0.2)
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                          ),
                          Text(
                            _faqItems[index].answer,
                            style: pixelFontStyle(
                              fontSize: 14,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Contact support footer
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border(
                  top: BorderSide(
                    color: Colors.pink.shade800, 
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CAN\'T FIND WHAT YOU\'RE LOOKING FOR?',
                    style: pixelFontStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Add your contact support logic here
                      _showContactDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 212, 0, 0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'CONTACT SUPPORT',
                      style: pixelFontStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
  
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border.all(color: Colors.cyan, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONTACT SUPPORT',
                style: pixelFontStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Our support team is available 24/7',
                style: pixelFontStyle(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'support@gamebox.com',
                      style: pixelFontStyle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.headset_mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '+1-800-GAMEBOX',
                      style: pixelFontStyle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 212, 0, 0),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'CLOSE',
                  style: pixelFontStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FAQ data model
class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}