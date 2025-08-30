import 'package:flutter/material.dart';

class DiscoverSection extends StatelessWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Discover New Artists",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 6,
            itemBuilder: (context, index) {
              return DiscoverArtistCard(
                name: "Artist ${index + 1}",
                followers: "${(index + 1) * 25}K",
              );
            },
          ),
        ),
      ],
    );
  }
}

// Discover Artist Card Widget
class DiscoverArtistCard extends StatelessWidget {
  final String name;
  final String followers;

  const DiscoverArtistCard({
    super.key,
    required this.name,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.purple[400]!],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),

          const SizedBox(height: 8),

          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          Text(
            "$followers followers",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
