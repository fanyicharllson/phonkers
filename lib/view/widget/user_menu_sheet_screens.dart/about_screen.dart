import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        foregroundColor: Colors.white,
        title: const Text('About Phonkers'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // App Logo Placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                size: 60,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 20),

            // App Name and Version
            const Text(
              'Phonkers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // Description
            const Text(
              'The ultimate destination for phonk music lovers. Discover, stream, and enjoy the best phonk tracks from around the world.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Features
            _buildInfoSection(
              context: context,
              title: 'Features',
              items: [
                'Stream high-quality phonk music',
                'Create and manage playlists',
                'Offline listening for premium users',
                'Discover new artists and tracks',
                'Social sharing and recommendations',
              ],
            ),

            const SizedBox(height: 30),

            // Legal Information
            _buildInfoSection(
              context: context,
              title: 'Legal',
              items: [
                'Privacy Policy',
                'Terms of Service',
                'Licenses',
                'Copyright Information',
              ],
              isClickable: true,
            ),

            const SizedBox(height: 30),

            // Developer Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Developer',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Made with ❤️ for phonk music enthusiasts',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildSocialButton(Icons.web, () {}),
                      const SizedBox(width: 15),
                      _buildSocialButton(Icons.email, () {}),
                      const SizedBox(width: 15),
                      _buildSocialButton(Icons.share, () {}),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Copyright
            Text(
              '© ${DateTime.now().year} Phonkers. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required List<String> items,
    bool isClickable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.purple,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: isClickable
                ? InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$item coming soon!')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      const Icon(Icons.check, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
