import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'TERMS & CONDITIONS',
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF1A1A2E),
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('GENERAL TERMS'),
              _buildTermsCard(
                icon: Icons.gavel,
                title: 'Legal Agreement',
                content: 'By accessing and using GameBox, you agree to be bound by these terms and conditions.',
              ),
              _buildTermsCard(
                icon: Icons.security,
                title: 'Account Security',
                content: 'You are responsible for maintaining the security of your account credentials.',
              ),
              
              const SizedBox(height: 24),
              _buildSectionHeader('USAGE GUIDELINES'),
              _buildTermsCard(
                icon: Icons.videogame_asset,
                title: 'Game Content',
                content: 'All games and digital content are subject to their respective licenses and terms.',
              ),
              _buildTermsCard(
                icon: Icons.payment,
                title: 'Payments',
                content: 'Purchases are final. Refunds are subject to our refund policy.',
              ),
              
              const SizedBox(height: 24),
              _buildSectionHeader('PRIVACY & DATA'),
              _buildTermsCard(
                icon: Icons.privacy_tip,
                title: 'Data Collection',
                content: 'We collect and process data as described in our Privacy Policy.',
              ),
              _buildTermsCard(
                icon: Icons.cookie,
                title: 'Cookies',
                content: 'This platform uses cookies to enhance user experience.',
              ),

              const SizedBox(height: 24),
              _buildContactSupport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            color: Color(0xFF00E5FF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTermsCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333355),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF0077),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFFF0077),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontFamily: 'PixelFont',
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF0077),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEED HELP?',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Color(0xFFFF0077),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact our support team for any questions about these terms.',
            style: TextStyle(
              fontFamily: 'PixelFont',
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Add your contact support action here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0077),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headset_mic, size: 20),
                SizedBox(width: 8),
                Text(
                  'CONTACT SUPPORT',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}