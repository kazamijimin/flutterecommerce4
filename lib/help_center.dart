import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutterecommerce4/shopee_policies.dart';
class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({Key? key}) : super(key: key);

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter help topics based on search query
  List<HelpTopic> _getFilteredTopics() {
    if (_searchQuery.isEmpty) {
      return helpTopics;
    }
    return helpTopics
        .where((topic) =>
            topic.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            topic.keywords.any((keyword) =>
                keyword.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@gamebox.com',
      query: 'subject=Customer Support Request&body=Hello GameBox Support Team,',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Color(0xFFFF0077),
          ),
        );
      }
    }
  }

  Future<void> _submitTicket() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate ticket submission
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Ticket Submitted',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Your support ticket has been submitted successfully. Our team will respond within 24 hours.',
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
  }

  @override
  Widget build(BuildContext context) {
    final filteredTopics = _getFilteredTopics();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'HELP CENTER',
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
      body: Column(
        children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3A1078).withOpacity(0.8),
                  const Color(0xFF4E31AA).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for help topics...',
                    hintStyle: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.white.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF00E5FF),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Help topics
          Expanded(
            child: filteredTopics.isEmpty
                ? _buildNoResultsFound()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = filteredTopics[index];
                      return _buildHelpTopicCard(topic);
                    },
                  ),
          ),

          // Contact options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFF00E5FF),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('EMAIL US'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0077),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _launchEmail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.support_agent),
                        label: Text(_isLoading ? 'SUBMITTING...' : 'OPEN TICKET'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitTicket,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords or contact support',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTopicCard(HelpTopic topic) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: topic.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: topic.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              topic.icon,
              color: topic.color,
              size: 24,
            ),
          ),
          title: Text(
            topic.title,
            style: const TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            ...topic.questions.map((question) => _buildQuestionItem(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(HelpQuestion question) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question.question,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.answer,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          if (question.actionText != null && question.actionRoute != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => question.actionRoute!,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  question.actionText!,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HelpTopic {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final List<HelpQuestion> questions;

  HelpTopic({
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
    required this.keywords,
  });
}

class HelpQuestion {
  final String question;
  final String answer;
  final String? actionText;
  final Widget? actionRoute;

  HelpQuestion({
    required this.question,
    required this.answer,
    this.actionText,
    this.actionRoute,
  });
}

// Sample help topics and questions
final List<HelpTopic> helpTopics = [
  HelpTopic(
    title: 'Account & Login',
    icon: Icons.person,
    color: const Color(0xFFFF0077),
    keywords: ['account', 'login', 'signup', 'password', 'email', 'profile'],
    questions: [
      HelpQuestion(
        question: 'How do I create a GameBox account?',
        answer:
            'To create a GameBox account:\n\n'
            '1. Tap on the "Sign Up" button on the login screen\n'
            '2. Enter your email address and create a password\n'
            '3. Verify your email address by clicking the link sent to your inbox\n'
            '4. Complete your profile with your display name and optional details\n\n'
            'You can also sign up using your Google account for faster registration.',
      ),
      HelpQuestion(
        question: 'I forgot my password. How do I reset it?',
        answer:
            'To reset your password:\n\n'
            '1. On the login screen, tap "Forgot Password"\n'
            '2. Enter the email address associated with your account\n'
            '3. Check your email for a password reset link\n'
            '4. Click the link and follow the instructions to create a new password\n\n'
            'If you don\'t receive the email within a few minutes, check your spam folder.',
      ),
      HelpQuestion(
        question: 'How do I change my display name or profile picture?',
        answer:
            'You can update your profile information at any time:\n\n'
            '1. Go to Settings > My Profile\n'
            '2. Tap on your current display name or profile picture\n'
            '3. Enter your new display name or select a new image\n'
            '4. Tap "Save" to update your profile\n\n'
            'Note that display names must be unique and follow our community guidelines.',
      ),
      HelpQuestion(
        question: 'Can I link multiple email addresses to my account?',
        answer:
            'Currently, each GameBox account can only be associated with one email address. If you need to change your email address:\n\n'
            '1. Go to Settings > My Profile > Email\n'
            '2. Tap "Change Email Address"\n'
            '3. Enter your new email and confirm with your password\n'
            '4. Verify your new email by clicking the link sent to that address\n\n'
            'Your account will retain all purchases and game history after the email change.',
      ),
    ],
  ),
  HelpTopic(
    title: 'Purchases & Payments',
    icon: Icons.payment,
    color: const Color(0xFF00E5FF),
    keywords: ['purchase', 'payment', 'refund', 'billing', 'transaction', 'buy'],
    questions: [
      HelpQuestion(
        question: 'What payment methods are accepted?',
        answer:
            'GameBox accepts the following payment methods:\n\n'
            '• Credit/Debit Cards (Visa, Mastercard, American Express)\n'
            '• Digital Wallets (PayPal, Apple Pay, Google Pay)\n'
            '• Bank Transfers (where available)\n'
            '• Prepaid GameBox Cards\n'
            '• Mobile Carrier Billing (select regions)\n\n'
            'Payment methods may vary by region. You can manage your payment methods in Settings > Bank Account/Cards.',
      ),
      HelpQuestion(
        question: 'How do I request a refund?',
        answer:
            'To request a refund for a game purchase:\n\n'
            '1. Go to Purchase History in your account\n'
            '2. Select the game you want to refund\n'
            '3. Tap "Request Refund" and select a reason\n'
            '4. Submit your request\n\n'
            'Remember that refunds are eligible within 14 days of purchase and with less than 2 hours of gameplay. For more details, refer to our Refund Policy.',
        actionText: 'View Refund Policy',
        actionRoute: const ShopeePoliciesPage(),
      ),
      HelpQuestion(
        question: 'Why was my payment declined?',
        answer:
            'Payments may be declined for several reasons:\n\n'
            '• Insufficient funds in your account\n'
            '• Incorrect card information\n'
            '• Expired card\n'
            '• Unusual activity flagged by your bank\n'
            '• Regional restrictions\n\n'
            'If your payment was declined, try another payment method or contact your bank for more information. If problems persist, contact our support team.',
      ),
      HelpQuestion(
        question: 'Where can I find my purchase history?',
        answer:
            'To view your purchase history:\n\n'
            '1. Go to your Account page\n'
            '2. Tap on "Purchase History"\n'
            '3. You\'ll see a list of all transactions\n\n'
            'You can filter by date range or purchase type. Receipt details can be viewed by tapping on any transaction.',
      ),
    ],
  ),
  HelpTopic(
    title: 'Games & Downloads',
    icon: Icons.gamepad,
    color: const Color(0xFFFFA726),
    keywords: ['games', 'download', 'install', 'play', 'save', 'progress'],
    questions: [
      HelpQuestion(
        question: 'How do I download a game after purchase?',
        answer:
            'After purchasing a game, you can download it by:\n\n'
            '1. Going to your Library\n'
            '2. Finding the game in your collection\n'
            '3. Tapping "Download" or "Install"\n\n'
            'The game will begin downloading automatically. You can track download progress in the Notifications panel.',
      ),
      HelpQuestion(
        question: 'My game won\'t launch. What should I do?',
        answer:
            'If a game won\'t launch, try these troubleshooting steps:\n\n'
            '1. Restart the app\n'
            '2. Check for app updates\n'
            '3. Verify your device meets the minimum requirements\n'
            '4. Clear the app cache (Settings > Apps > GameBox > Storage > Clear Cache)\n'
            '5. Reinstall the game\n\n'
            'If these steps don\'t work, contact our support team with details about your device and the specific game.',
      ),
      HelpQuestion(
        question: 'Will I lose my save data if I uninstall a game?',
        answer:
            'Your game progress is typically saved in two ways:\n\n'
            '1. Cloud saves: Most games automatically sync progress to your GameBox account\n'
            '2. Local saves: Some games store data locally on your device\n\n'
            'If a game supports cloud saves, you can safely uninstall and reinstall without losing progress. For games with only local saves, uninstalling may delete your progress unless you back up your data first.',
      ),
      HelpQuestion(
        question: 'How can I request a specific game be added to GameBox?',
        answer:
            'We\'re always looking to expand our game library! To suggest a game:\n\n'
            '1. Tap on your profile icon\n'
            '2. Select "Game Suggestions"\n'
            '3. Fill out the suggestion form with details about the game\n\n'
            'Our content team reviews suggestions regularly and works with developers to bring popular requests to the platform.',
      ),
    ],
  ),
  HelpTopic(
    title: 'Technical Issues',
    icon: Icons.build,
    color: const Color(0xFFFFD700),
    keywords: ['bug', 'crash', 'error', 'problem', 'technical', 'fix', 'loading'],
    questions: [
      HelpQuestion(
        question: 'The app is crashing frequently. How can I fix this?',
        answer:
            'If the app is crashing, try these solutions:\n\n'
            '1. Update to the latest version of GameBox\n'
            '2. Restart your device\n'
            '3. Clear app cache and data\n'
            '4. Check that your device has sufficient storage space\n'
            '5. Ensure your device\'s operating system is up to date\n\n'
            'If crashes continue, please contact support with your device model and OS version.',
      ),
      HelpQuestion(
        question: 'Games are loading slowly. What can I do?',
        answer:
            'Slow loading games may be caused by:\n\n'
            '• Insufficient device memory\n'
            '• Slow internet connection\n'
            '• Many background apps running\n'
            '• Outdated app version\n\n'
            'Try closing background apps, connecting to faster Wi-Fi, and ensuring your device meets the game\'s recommended specifications.',
      ),
      HelpQuestion(
        question: 'How do I report a bug?',
        answer:
            'To report a bug in GameBox:\n\n'
            '1. Go to Settings > Help > Report a Bug\n'
            '2. Select the bug category\n'
            '3. Describe the issue in detail (include steps to reproduce)\n'
            '4. Add screenshots if available\n'
            '5. Submit the report\n\n'
            'Our development team reviews all bug reports and prioritizes fixes based on severity and impact.',
      ),
      HelpQuestion(
        question: 'Can I play games offline?',
        answer:
            'Many games on GameBox can be played offline, but there are some limitations:\n\n'
            '• You must first download the game while online\n'
            '• Some games require an internet connection for certain features\n'
            '• Multiplayer games need an internet connection\n'
            '• Your device must connect online at least once every 30 days to verify your licenses\n\n'
            'Games that can be played fully offline are marked with an "Offline Play" badge in the store.',
      ),
    ],
  ),
  HelpTopic(
    title: 'Community & Social',
    icon: Icons.groups,
    color: const Color(0xFFA020F0),
    keywords: ['community', 'friends', 'social', 'chat', 'message', 'multiplayer', 'team'],
    questions: [
      HelpQuestion(
        question: 'How do I add friends on GameBox?',
        answer:
            'To add friends to your GameBox network:\n\n'
            '1. Go to the Friends tab in the app\n'
            '2. Tap the "+" icon in the top right\n'
            '3. Search by username, email, or phone number\n'
            '4. Send a friend request\n\n'
            'You can also connect your social media accounts to find friends who use GameBox.',
      ),
      HelpQuestion(
        question: 'Someone is harassing me. What should I do?',
        answer:
            'We take harassment seriously. If you\'re experiencing harassment:\n\n'
            '1. Block the user from your profile page\n'
            '2. Report the behavior through Settings > Support > Report User\n'
            '3. Include screenshots or message logs as evidence\n\n'
            'Our moderation team will review your report and take appropriate action according to our community guidelines.',
        actionText: 'View User Conduct Policy',
        actionRoute: const ShopeePoliciesPage(),
      ),
      HelpQuestion(
        question: 'How do I create a team for multiplayer games?',
        answer:
            'To create a team for multiplayer gaming:\n\n'
            '1. Go to the Teams tab\n'
            '2. Tap "Create New Team"\n'
            '3. Set a team name and optional logo\n'
            '4. Invite friends or other players\n'
            '5. Assign roles if desired (captain, member, etc.)\n\n'
            'Teams can be public (anyone can request to join) or private (invitation only).',
      ),
      HelpQuestion(
        question: 'Can I stream or create content about GameBox games?',
        answer:
            'Yes! We encourage content creation featuring GameBox games:\n\n'
            '• You may create videos, streams, and screenshots for most games\n'
            '• You can monetize your content on platforms like YouTube and Twitch\n'
            '• Some games may have specific content creation policies set by their publishers\n\n'
            'For more information on content creation guidelines, check our Content Guidelines policy.',
        actionText: 'View Content Guidelines',
        actionRoute: const ShopeePoliciesPage(),
      ),
    ],
  ),
];