// screens/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:pick_my_dish/Models/developer_model.dart';
import 'package:pick_my_dish/constants.dart';
import 'package:pick_my_dish/widgets/cached_image.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final developers = _getDevelopers();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 30, top: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.orange,
                  size: iconSize,
                ),
              ),
            ),
            title: Text(
              'About Us',
              style: title.copyWith(fontSize: 24),
            ),
            centerTitle: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE53935),
                      Color(0xFFFF9800),
                    ],
                  ),
                ),
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/login/background.png', // Using existing background
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Description
                  _buildAppDescription(),
                  const SizedBox(height: 32),
                  
                  // Team Section Title
                  Text(
                    'Meet Our Team',
                    style: mediumtitle.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 20),
                  
                  // Developers List
                  ...developers.map((developer) => 
                    _buildDeveloperCard(context, developer)
                  ).toList(),
                  
                  const SizedBox(height: 30),
                  
                  // App Info Section
                  _buildAppInfoSection(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/login/logo.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'PickMyDish',
                  style: title.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Your personal cooking companion that helps you decide what to cook based on your mood, available ingredients, and time constraints.',
            style: text.copyWith(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            'We believe cooking should be fun, easy, and accessible to everyone. Our app connects food lovers and helps them discover new recipes tailored to their preferences.',
            style: text.copyWith(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, Developer developer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Developer Info Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      developer.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Text(
                              developer.name[0],
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Developer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        developer.name,
                        style: title.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        developer.role,
                        style: text.copyWith(
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        developer.description,
                        style: text.copyWith(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contributions Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Contributions:',
                  style: text.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...developer.contributions.map((contribution) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contribution,
                            style: text.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
                
                // Social Links
                if (developer.linkedInUrl != null || developer.githubUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      children: [
                        if (developer.linkedInUrl != null)
                          _buildSocialButton(
                            context,
                            Icons.linked_camera,
                            'LinkedIn',
                            developer.linkedInUrl!,
                          ),
                        if (developer.githubUrl != null) ...[
                          const SizedBox(width: 10),
                          _buildSocialButton(
                            context,
                            Icons.code,
                            'GitHub',
                            developer.githubUrl!,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label, String url) {
    return ElevatedButton.icon(
      onPressed: () => _launchUrl(url),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: text.copyWith(fontSize: 12),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About PickMyDish',
            style: mediumtitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 15),
          
          _buildInfoRow(
            Icons.star,
            'App Version',
            '1.0.0',
          ),
          const SizedBox(height: 10),
          
          _buildInfoRow(
            Icons.update,
            'Last Updated',
            'December 2025',
          ),
          const SizedBox(height: 10),
          
          _buildInfoRow(
            Icons.people,
            'Team Size',
            '2 Developers',
          ),
          const SizedBox(height: 10),
          
          _buildInfoRow(
            Icons.language,
            'Technologies',
            'Flutter, Node.js, MySQL',
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Our Mission',
            style: text.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To make cooking accessible and enjoyable for everyone by providing personalized recipe recommendations and fostering a community of food lovers.',
            style: text.copyWith(fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$title: ',
            style: text.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Text(value, style: text),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  List<Developer> _getDevelopers() {
  return [
    Developer(
      name: 'Kamdeu Yamdjeuson Neil Marshall',
      role: 'Backend & DevOps Engineer',
      description: 'Third-year Software Engineering student at ICT University with a passion for system architecture and cloud infrastructure. Specializes in backend development and DevOps practices.',
      imageAsset: 'assets/developers/kamdeu.jpg',
      linkedInUrl: 'https://www.linkedin.com/in/kamdeu-yamdjeuson-neil-marshall-a70566298/',
      githubUrl: 'https://github.com/Kynmmarshall',
      contributions: [
        'Configured the complete DevOps pipeline using Jenkins for CI/CD',
        'Set up and managed the VPS (Virtual Private Server) infrastructure',
        'Designed and implemented the Node.js backend API architecture',
        'Created and optimized the MySQL database schema and queries',
        'Implemented user authentication and security systems',
        'Configured Nginx reverse proxy for production deployment',
        'Set up SSL certificates for secure HTTPS connections',
        'Worked on Flutter frontend state management using Provider',
      ],
    ),
    Developer(
      name: 'Tuheu Tchoubi Pempem Moussa Fahdil',
      role: 'Frontend & UI/UX Developer',
      description: 'Third-year Software Engineering student at ICT University specializing in user interface design and mobile application development. Focuses on creating intuitive and visually appealing cooking experiences.',
      imageAsset: 'assets/developers/tuheu.png',
      linkedInUrl: 'https://linkedin.com/in/tuheu-tchoubi',
      githubUrl: 'https://github.com/TUHEU',
      contributions: [
        'Designed the complete visual identity and UI/UX of PickMyDish',
        'Implemented all Flutter screens with consistent theming',
        'Created the recipe upload and editing interface',
        'Built the mood-based recipe filtering user interface',
        'Implemented the favorite recipes system with smooth animations',
        'Designed the personalized recipe recommendation flow',
        'Worked on backend API integration for recipe management',
        'Contributed to database schema design for user preferences',
      ],
    ),
  ];
}
}