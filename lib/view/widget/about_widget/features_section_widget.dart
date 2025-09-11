import 'package:flutter/material.dart';

class FeaturesSectionWidget extends StatelessWidget {
  const FeaturesSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.high_quality,
        'title': 'High-Quality Streaming',
        'description': 'Stream phonk music in crystal clear quality',
      },
      {
        'icon': Icons.playlist_add,
        'title': 'Custom Playlists',
        'description': 'Create and manage your own phonk collections',
      },
      {
        'icon': Icons.download,
        'title': 'Offline Listening',
        'description': 'Download tracks for offline enjoyment (Premium)',
      },
      {
        'icon': Icons.explore,
        'title': 'Discover Music',
        'description': 'Find new artists and trending phonk tracks',
      },
      {
        'icon': Icons.share,
        'title': 'Social Sharing',
        'description': 'Share your favorite tracks with friends',
      },
      {
        'icon': Icons.recommend,
        'title': 'Smart Recommendations',
        'description': 'AI-powered music suggestions tailored for you',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Features',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(
                feature['icon'] as IconData,
                feature['title'] as String,
                feature['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(
            icon,
            color: Colors.purple,
            size: 24, // Reduced from 28
          ),
          const SizedBox(height: 8), // Reduced from 12
          Flexible( // Wrapped with Flexible
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // Reduced from 14
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2, // Added max lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          Flexible( // Wrapped with Flexible
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10, // Reduced from 11
                height: 1.2, // Reduced line height
              ),
              maxLines: 3, // Increased max lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}