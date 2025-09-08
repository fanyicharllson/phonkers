import 'package:flutter/material.dart';

class DiscoverSection extends StatelessWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Text(
                "Discover New Artists",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 120, // increased to avoid bottom overflow
          child: Stack(
            children: [
              // Blurred artist cards in background
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return DiscoverArtistCard(
                    name: "Artist ${index + 1}",
                    followers: "${(index + 1) * 25}K",
                    isBlurred: true,
                  );
                },
              ),

              // Coming soon overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withValues(alpha: 0.4),
                          Colors.purpleAccent.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.rocket_launch,
                          color: Colors.purpleAccent,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Coming Soon!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover amazing new artists',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DiscoverArtistCard extends StatelessWidget {
  final String name;
  final String followers;
  final bool isBlurred;

  const DiscoverArtistCard({
    super.key,
    required this.name,
    required this.followers,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBlurred ? 0.3 : 1.0,
      child: Container(
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
                  colors: isBlurred
                      ? [Colors.grey.shade600, Colors.grey.shade800]
                      : [Colors.deepPurple.shade600, Colors.purpleAccent],
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),

            const SizedBox(height: 8),

            Text(
              name,
              style: TextStyle(
                color: isBlurred
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white,
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
                color: isBlurred
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
