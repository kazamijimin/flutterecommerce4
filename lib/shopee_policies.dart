import 'package:flutter/material.dart';

class ShopeePoliciesPage extends StatelessWidget {
  const ShopeePoliciesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'GAMEBOX POLICIES',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('PLATFORM POLICIES'),
            const SizedBox(height: 16),
            _buildPolicyCard(
              title: 'Refund Policy',
              icon: Icons.money_off,
              color: const Color(0xFFFF0077),
              onTap: () => _showPolicyDetails(
                context,
                'Refund Policy',
                _refundPolicyContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Game Return Policy',
              icon: Icons.replay,
              color: const Color(0xFF00E5FF),
              onTap: () => _showPolicyDetails(
                context,
                'Game Return Policy',
                _gameReturnPolicyContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'User Conduct',
              icon: Icons.people,
              color: const Color(0xFFA020F0),
              onTap: () => _showPolicyDetails(
                context,
                'User Conduct',
                _userConductContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Intellectual Property',
              icon: Icons.copyright,
              color: const Color(0xFFFFD700),
              onTap: () => _showPolicyDetails(
                context,
                'Intellectual Property',
                _intellectualPropertyContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Payment Processing',
              icon: Icons.payment,
              color: const Color(0xFF4CAF50),
              onTap: () => _showPolicyDetails(
                context,
                'Payment Processing',
                _paymentProcessingContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Content Guidelines',
              icon: Icons.content_paste,
              color: const Color(0xFFFFA726),
              onTap: () => _showPolicyDetails(
                context,
                'Content Guidelines',
                _contentGuidelinesContent(),
              ),
            ),
            const SizedBox(height: 32),
            _buildHeader('DATA & PRIVACY'),
            const SizedBox(height: 16),
            _buildPolicyCard(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              color: const Color(0xFF00E5FF),
              onTap: () => _showPolicyDetails(
                context,
                'Privacy Policy',
                _privacyPolicyContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Data Collection',
              icon: Icons.data_usage,
              color: const Color(0xFFFF0077),
              onTap: () => _showPolicyDetails(
                context,
                'Data Collection',
                _dataCollectionContent(),
              ),
            ),
            _buildPolicyCard(
              title: 'Cookie Policy',
              icon: Icons.cookie,
              color: const Color(0xFFFFD700),
              onTap: () => _showPolicyDetails(
                context,
                'Cookie Policy',
                _cookiePolicyContent(),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Last Updated: May 23, 2025',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00E5FF),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPolicyDetails(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar at the top
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // Divider
                Divider(
                  color: Colors.grey[800],
                  thickness: 1,
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: content,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _policySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 14,
            color: Colors.grey[300],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _refundPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'General Refund Policy',
          'GameBox offers refunds under specific conditions to ensure customer satisfaction while maintaining platform integrity. All refunds are processed to the original payment method within 7-14 business days.',
        ),
        _policySection(
          'Digital Game Purchases',
          '• Refund requests must be made within 14 days of purchase\n'
          '• Game must have been played for less than 2 hours\n'
          '• Pre-ordered games can be refunded at any time prior to release\n'
          '• Games with technical issues may qualify for refunds outside standard policy',
        ),
        _policySection(
          'In-Game Purchases',
          '• Virtual currency and in-game items are generally non-refundable\n'
          '• Exceptions may be made for accidental purchases if reported within 48 hours\n'
          '• Unused virtual items may be eligible for store credit at GameBox\'s discretion',
        ),
        _policySection(
          'Subscription Services',
          '• Pro subscriptions can be cancelled at any time\n'
          '• Refunds are prorated based on unused time if requested within 30 days\n'
          '• Free trial conversions to paid subscriptions are eligible for refund within 7 days',
        ),
        _policySection(
          'Ineligible for Refunds',
          '• Games removed for violating Terms of Service\n'
          '• Accounts banned for fraudulent activity\n'
          '• Purchases made over 14 days ago\n'
          '• Games with more than 2 hours of playtime',
        ),
      ],
    );
  }

  Widget _gameReturnPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Digital Game Returns',
          'As GameBox primarily deals with digital content, we have special policies for game returns that differ from physical merchandise returns.',
        ),
        _policySection(
          'Return Eligibility',
          '• Digital games may be returned within 14 days of purchase\n'
          '• Total gameplay must be under 2 hours\n'
          '• Technical issues that prevent gameplay may extend the return window\n'
          '• Beta or early access games follow the same policy unless otherwise stated',
        ),
        _policySection(
          'Return Process',
          '1. Submit return request through Account > Purchase History\n'
          '2. Select the game and reason for return\n'
          '3. Our system will verify eligibility based on purchase date and playtime\n'
          '4. Approved returns are processed within 3-5 business days',
        ),
        _policySection(
          'Special Considerations',
          '• Games purchased during sales may have modified return policies (noted at time of purchase)\n'
          '• Bundle purchases are evaluated on a case-by-case basis\n'
          '• DLC and expansions follow the same policy as full games',
        ),
      ],
    );
  }

  Widget _userConductContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Community Standards',
          'GameBox is committed to maintaining a respectful, inclusive environment for all users. These standards apply to all interactions on our platform including forums, reviews, and in-game communications.',
        ),
        _policySection(
          'Prohibited Conduct',
          '• Harassment, hate speech, or discrimination of any kind\n'
          '• Threats or incitement of violence\n'
          '• Impersonation of other users or GameBox staff\n'
          '• Sharing explicit, illegal, or harmful content\n'
          '• Intentional disruption of services or user experience\n'
          '• Cheating, hacking, or exploitation of platform vulnerabilities',
        ),
        _policySection(
          'Content Guidelines',
          '• User-generated content must comply with all applicable laws\n'
          '• Content should be appropriate for the game\'s age rating\n'
          '• Reviews should be honest and related to the game experience\n'
          '• Commercial promotion is prohibited without prior authorization',
        ),
        _policySection(
          'Enforcement Actions',
          'Violations may result in:\n'
          '• Content removal\n'
          '• Temporary suspension\n'
          '• Permanent account termination\n'
          '• Restriction of platform features',
        ),
        _policySection(
          'Reporting Violations',
          'If you encounter inappropriate conduct, please use the "Report" function or contact support@gamebox.com with details of the incident.',
        ),
      ],
    );
  }

  Widget _intellectualPropertyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Intellectual Property Rights',
          'GameBox respects the intellectual property rights of others and expects users to do the same. This policy outlines how we protect IP rights and handle potential infringements.',
        ),
        _policySection(
          'Platform Content',
          '• All GameBox branding, design, and proprietary software are protected by copyright and trademark laws\n'
          '• Game listings and official descriptions are provided by rights holders or with their permission\n'
          '• Screenshots, videos, and promotional materials are used under license from publishers/developers',
        ),
        _policySection(
          'User-Generated Content',
          '• By uploading content to GameBox, users grant us a non-exclusive license to display and distribute that content\n'
          '• Users retain ownership of their original content\n'
          '• Users must have rights to any content they upload\n'
          '• Fan art and derivative works must comply with the original creator\'s terms',
        ),
        _policySection(
          'DMCA Compliance',
          'GameBox follows the Digital Millennium Copyright Act process for handling copyright infringement claims:\n'
          '1. Rights holders may submit DMCA notices to legal@gamebox.com\n'
          '2. We will remove alleged infringing content pending investigation\n'
          '3. Users may submit counter-notices if they believe content was removed in error\n'
          '4. Repeat infringers will have their accounts terminated',
        ),
        _policySection(
          'Content Usage Policy',
          '• Users may create content about games purchased on GameBox for non-commercial purposes\n'
          '• Streaming and content creation policies are determined by individual game publishers\n'
          '• GameBox name and logo may not be used to suggest partnership or endorsement without written permission',
        ),
      ],
    );
  }

  Widget _paymentProcessingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Payment Methods',
          'GameBox accepts various payment methods to ensure convenient purchasing options for our global user base:\n\n'
          '• Credit/Debit Cards (Visa, Mastercard, American Express)\n'
          '• Digital Wallets (PayPal, Apple Pay, Google Pay)\n'
          '• Bank Transfers (where available)\n'
          '• Prepaid GameBox Cards\n'
          '• Mobile Carrier Billing (select regions)',
        ),
        _policySection(
          'Transaction Security',
          'All transactions on GameBox are secured using industry-standard encryption and security protocols:\n\n'
          '• PCI DSS compliant payment processing\n'
          '• End-to-end encryption for all financial data\n'
          '• Multi-factor authentication for high-value transactions\n'
          '• Regular security audits and compliance reviews',
        ),
        _policySection(
          'Billing Verification',
          'For security purposes, we may occasionally request verification for transactions:\n\n'
          '• New payment methods may require additional verification\n'
          '• Purchases from new devices or locations might trigger security checks\n'
          '• Large or unusual transactions may require confirmation',
        ),
        _policySection(
          'Currency & Pricing',
          '• Prices are displayed in your local currency when available\n'
          '• Exchange rates for international transactions are determined by your payment provider\n'
          '• GameBox does not charge currency conversion fees, but your payment method might\n'
          '• Regional pricing variations may exist based on local market conditions',
        ),
        _policySection(
          'Subscriptions & Recurring Payments',
          '• Subscription charges are processed automatically on the renewal date\n'
          '• Email notifications are sent before each renewal\n'
          '• Users can cancel subscriptions at any time through Account Settings\n'
          '• Payment method updates can be managed in the Payment Settings section',
        ),
      ],
    );
  }

  Widget _contentGuidelinesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Game Content Ratings',
          'GameBox uses standardized age and content rating systems to help users make informed decisions:\n\n'
          '• All games display appropriate age ratings (ESRB, PEGI, etc.)\n'
          '• Content descriptors indicate specific types of content (violence, language, etc.)\n'
          '• Parental controls can be configured to restrict access based on these ratings',
        ),
        _policySection(
          'User Reviews & Ratings',
          'User-generated reviews must adhere to these guidelines:\n\n'
          '• Reviews should focus on the game experience and be relevant to other players\n'
          '• Personal attacks against developers or other users are prohibited\n'
          '• Spoilers should be properly marked and not included in review summaries\n'
          '• Reviews suspected of manipulation (paid reviews, review bombing) will be removed',
        ),
        _policySection(
          'Streaming & Content Creation',
          'When creating content featuring games from GameBox:\n\n'
          '• Users may create and monetize videos/streams of gameplay for most titles\n'
          '• Some games may have specific restrictions set by publishers\n'
          '• GameBox branding may be used in content that features our platform\n'
          '• Users must comply with the specific content creation policies of each game',
        ),
        _policySection(
          'User-Generated Content',
          'For platforms that allow user-generated content (mods, custom levels, etc.):\n\n'
          '• Content must not infringe on intellectual property rights\n'
          '• Content must comply with the age rating of the base game\n'
          '• Harmful content (malware, exploits) is strictly prohibited\n'
          '• GameBox reserves the right to remove content that violates our guidelines',
        ),
        _policySection(
          'Community Forums & Chat',
          '• Communications should be respectful and constructive\n'
          '• No spamming, excessive self-promotion, or advertising\n'
          '• Personal information should not be shared publicly\n'
          '• Moderators may remove content or restrict access for users who violate guidelines',
        ),
      ],
    );
  }

  Widget _privacyPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Information We Collect',
          'GameBox collects several types of information to provide and improve our service:\n\n'
          '• Account information (name, email, date of birth)\n'
          '• Payment details (securely stored in compliance with industry standards)\n'
          '• Device information (hardware, operating system, unique identifiers)\n'
          '• Gameplay data (games owned, playtime, achievements)\n'
          '• Communications (customer support interactions, forum posts)',
        ),
        _policySection(
          'How We Use Your Information',
          'We use the collected information for various purposes including:\n\n'
          '• Providing and maintaining our service\n'
          '• Improving and personalizing user experience\n'
          '• Processing transactions and preventing fraud\n'
          '• Communication about updates, offers, and support\n'
          '• Analytics to understand usage patterns',
        ),
        _policySection(
          'Information Sharing',
          'GameBox may share your information in limited circumstances:\n\n'
          '• With game publishers/developers (for game-specific functions)\n'
          '• With service providers (payment processors, hosting services)\n'
          '• For legal compliance and protection of rights\n'
          '• With your consent (when you choose to share information)',
        ),
        _policySection(
          'Your Privacy Rights',
          'Depending on your location, you may have rights regarding your personal data:\n\n'
          '• Access your personal information\n'
          '• Correct inaccurate information\n'
          '• Delete your data (subject to legal requirements)\n'
          '• Restrict or object to certain processing\n'
          '• Data portability\n'
          '• Withdraw consent',
        ),
        _policySection(
          'Data Security',
          'We implement various security measures to protect your information:\n\n'
          '• Encryption of sensitive data\n'
          '• Regular security assessments\n'
          '• Access controls and authentication requirements\n'
          '• Continuous monitoring for suspicious activity',
        ),
      ],
    );
  }

  Widget _dataCollectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'Types of Data Collected',
          'GameBox collects different categories of data to provide our services:\n\n'
          '• Personal Information: Name, email, phone number, billing address\n'
          '• Account Information: Username, password, preferences, game library\n'
          '• Transaction Data: Purchase history, payment methods (card last 4 digits only)\n'
          '• Usage Data: Login times, playtime, feature usage, device information\n'
          '• Performance Data: Crash reports, technical issues, system specifications',
        ),
        _policySection(
          'Collection Methods',
          'We collect information through various methods:\n\n'
          '• Direct Provision: Information you provide when creating an account or making purchases\n'
          '• Automated Collection: Usage data collected through cookies and analytics tools\n'
          '• Third-Party Sources: Information from connected services (if you link accounts)\n'
          '• Game Publishers: Game-specific data shared by publishers when you play their games',
        ),
        _policySection(
          'Legal Basis for Collection',
          'We collect and process data based on the following legal grounds:\n\n'
          '• Contract: To fulfill our obligations to you under our Terms of Service\n'
          '• Consent: When you explicitly agree to specific data processing activities\n'
          '• Legitimate Interests: For purposes that are reasonable in operating our business\n'
          '• Legal Compliance: To comply with applicable laws and regulations',
        ),
        _policySection(
          'Data Retention',
          'We retain different types of data for varying periods:\n\n'
          '• Account information: For as long as your account remains active\n'
          '• Transaction records: As required by financial regulations (typically 7 years)\n'
          '• Communication history: 2 years from last interaction\n'
          '• Usage data: In identifiable form for 2 years, then anonymized',
        ),
        _policySection(
          'Your Control Over Data Collection',
          '• Profile Settings: Manage personal information and privacy preferences\n'
          '• Cookie Preferences: Control non-essential cookies through our Cookie Banner\n'
          '• Marketing Preferences: Opt-out of promotional communications\n'
          '• Device Settings: Configure app permissions on your device\n'
          '• Data Requests: Submit requests for data access, correction, or deletion',
        ),
      ],
    );
  }

  Widget _cookiePolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policySection(
          'What Are Cookies',
          'Cookies are small text files stored on your device that help us improve your experience on GameBox:\n\n'
          '• They remember your preferences and settings\n'
          '• Enable core functionality like shopping carts and login sessions\n'
          '• Help us understand how users interact with our platform\n'
          '• Allow for personalized content and recommendations',
        ),
        _policySection(
          'Types of Cookies We Use',
          '• Essential Cookies: Required for basic platform functionality (cannot be disabled)\n'
          '• Preference Cookies: Remember your settings and improve usability\n'
          '• Analytics Cookies: Help us understand usage patterns and improve our service\n'
          '• Marketing Cookies: Used for targeted advertising and promotion\n'
          '• Social Media Cookies: Enable sharing and integration with social platforms',
        ),
        _policySection(
          'Third-Party Cookies',
          'Some cookies are placed by third-party services we use:\n\n'
          '• Analytics providers (Google Analytics, Mixpanel)\n'
          '• Advertising networks\n'
          '• Social media platforms\n'
          '• Payment processors\n'
          '• Game publishers (for game-specific features)',
        ),
        _policySection(
          'Cookie Management',
          'You can control how cookies are used when you visit GameBox:\n\n'
          '• Cookie Banner: Set preferences when you first visit our site\n'
          '• Browser Settings: Most browsers allow you to block or delete cookies\n'
          '• Preference Center: Adjust cookie settings at any time through your account\n'
          '• Do Not Track: We respect browser DNT signals where applicable',
        ),
        _policySection(
          'Cookie Lifespan',
          '• Session Cookies: Temporary and deleted when you close your browser\n'
          '• Persistent Cookies: Remain on your device for a specified period\n'
          '• First-Party Cookies: Set by GameBox (typically 1-2 years maximum)\n'
          '• Third-Party Cookies: Lifespan determined by the third-party service',
        ),
      ],
    );
  }
}