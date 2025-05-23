import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RateUsPage extends StatefulWidget {
  const RateUsPage({Key? key}) : super(key: key);

  @override
  State<RateUsPage> createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasRatedBefore = false;
  String _previousFeedback = '';

  @override
  void initState() {
    super.initState();
    _checkPreviousRating();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _checkPreviousRating() async {
    final prefs = await SharedPreferences.getInstance();
    final previousRating = prefs.getInt('user_rating') ?? 0;
    final previousFeedback = prefs.getString('user_feedback') ?? '';

    if (previousRating > 0) {
      setState(() {
        _hasRatedBefore = true;
        _selectedRating = previousRating;
        _previousFeedback = previousFeedback;
      });
    }
  }

  Future<void> _saveRating(int rating, String feedback) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_rating', rating);
    await prefs.setString('user_feedback', feedback);
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating first'),
          backgroundColor: Color(0xFFFF0077),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    // Save rating locally
    await _saveRating(_selectedRating, _feedbackController.text);

    setState(() {
      _isSubmitting = false;
      _hasRatedBefore = true;
      _previousFeedback = _feedbackController.text;
    });

    if (mounted) {
      if (_selectedRating >= 4) {
        _showStoreRedirectDialog();
      } else {
        _showFeedbackThankYouDialog();
      }
    }
  }

  void _showStoreRedirectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Thank You!',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'We\'re glad you love GameBox! Would you like to rate us on the app store to help others discover us?',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Now',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchStoreUrl();
            },
            child: const Text(
              'Rate on Store',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackThankYouDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Feedback Received',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Thank you for your feedback! We\'ll use it to improve GameBox and provide a better experience.',
          style: TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchStoreUrl() async {
    // Replace with actual store URLs when you have them
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.gamebox.app');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open app store'),
            backgroundColor: Color(0xFFFF0077),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'RATE GAMEBOX',
          style: TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF0077)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(top: 16, bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0077).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'GX',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Title
            const Text(
              'How would you rate your\nexperience with GameBox?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            // Previous rating notification
            if (_hasRatedBefore)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00E5FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You previously rated us $_selectedRating stars. You can update your rating below.',
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Star rating
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        _selectedRating > index
                            ? Icons.star
                            : Icons.star_border,
                        size: 48,
                        color: _selectedRating > index
                            ? const Color(0xFFFFD700)
                            : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Feedback text field
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _feedbackController,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  color: Colors.white,
                ),
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: _hasRatedBefore && _previousFeedback.isNotEmpty
                      ? 'Your previous feedback: $_previousFeedback'
                      : 'Tell us what you think about GameBox...',
                  hintStyle: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
              ),
            ),

            // Submit button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 32),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0077),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFFFF0077).withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('SUBMIT RATING'),
              ),
            ),

            // Additional note
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Your feedback helps us improve GameBox for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            
            // Contact support option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need help with something?',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact our support team for assistance',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to help center
                      Navigator.pushNamed(context, '/help_center');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                    ),
                    child: const Text(
                      'CONTACT',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
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
}