import 'package:flutter/material.dart';

class TeamMembersPage extends StatelessWidget {
  const TeamMembersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1B),
      appBar: AppBar(
        title: const Text(
          'OUR TEAM',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header with cover photo
            Container(
              width: double.infinity,
              height: 220, // Increased height to accommodate the cover photo
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/cover.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0077).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F0F1B).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Text content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Optional: Team logo or emblem
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0077).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'GX',
                              style: TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'MEET THE TEAM',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF0077),
                                offset: Offset(0, 2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF0077), Color(0xFF00E5FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The duo behind GameBox',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                            color: Colors.grey[300],
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Optional: Animated neon effect
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF00E5FF),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Founders section
            _buildTeamSection(
              'FOUNDERS',
              [
                _buildTeamMember(
                  'Nick Narry Sofer Mendoza',
                  'Co-Founder & Lead Developer',
                  'assets/images/nick_profile.jpg', // Updated to use Nick's profile image
                  'Visionary developer with expertise in mobile applications and backend systems. Passionate about creating innovative digital experiences for gamers worldwide.',
                  const Color(0xFFFF0077),
                ),
                _buildTeamMember(
                  'Jerick Estrada Mendez',
                  'Co-Founder & UX/UI Designer',
                  'assets/images/jerick_profile.jpg', // Updated to use Jerick's profile image
                  'Creative designer with a keen eye for user experience and interface design. Specializes in crafting the distinctive cyberpunk aesthetic of GameBox.',
                  const Color(0xFF00E5FF),
                ),
              ],
            ),

            // Our Story section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF0077).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0077).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: Color(0xFFFF0077),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'OUR STORY',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF0077),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GameBox began as a passion project between two friends who saw an opportunity to revolutionize the gaming marketplace. What started as late-night coding sessions and design sprints has evolved into a platform that connects gamers with unique digital experiences.',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'As a small team, we pride ourselves on our agility and direct connection with our users. Every feature and design choice comes from our personal experiences as gamers and our ongoing conversations with our community.',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Our Roles section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.assignment_ind,
                        color: Color(0xFF00E5FF),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'HOW WE WORK',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRoleItem(
                    'Nick',
                    'Leads backend development, database architecture, and payment systems',
                    Icons.code,
                  ),
                  _buildRoleItem(
                    'Jerick',
                    'Creates the user interface, visual design, and user experience flows',
                    Icons.brush,
                  ),
                  _buildRoleItem(
                    'Together',
                    'Customer support, community engagement, and strategic planning',
                    Icons.groups,
                  ),
                ],
              ),
            ),

            // Company values
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'OUR VALUES',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildValueItem(
                    'INNOVATION',
                    'Pushing the boundaries of what a game marketplace can be',
                    Icons.rocket_launch,
                  ),
                  _buildValueItem(
                    'COMMUNITY',
                    'Creating spaces for players and developers to connect',
                    Icons.people,
                  ),
                  _buildValueItem(
                    'QUALITY',
                    'Curating exceptional games and delivering polished experiences',
                    Icons.star,
                  ),
                  _buildValueItem(
                    'TRANSPARENCY',
                    'Being honest with our users and open about our process',
                    Icons.verified_user,
                  ),
                ],
              ),
            ),

            // Contact us
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade900.withOpacity(0.7),
                    Colors.indigo.shade900.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'GET IN TOUCH',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Have questions or feedback? We\'d love to hear from you!',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildContactMethod(
                        Icons.email,
                        'Email',
                        'support@gamebox.com',
                        Colors.pink.shade300,
                      ),
                      const SizedBox(width: 24),
                      _buildContactMethod(
                        Icons.discord,
                        'Discord',
                        'GameBox Official',
                        Colors.indigo.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.black,
              child: const Text(
                '© 2025 Nick & Jerick - GameBox Team',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(String title, List<Widget> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                color: const Color(0xFFFF0077),
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ...members,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTeamMember(
    String name,
    String role,
    String imageUrl,
    String bio,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: accentColor.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            name.substring(0, 1),
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Name, role and bio
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 12,
                          color: Colors.grey[400],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Social links
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.email, accentColor),
                const SizedBox(width: 16),
                _buildSocialIcon(Icons.code, accentColor),
                const SizedBox(width: 16),
                _buildSocialIcon(Icons.gamepad, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 18,
      ),
    );
  }

  Widget _buildValueItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(String name, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00E5FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 12,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}