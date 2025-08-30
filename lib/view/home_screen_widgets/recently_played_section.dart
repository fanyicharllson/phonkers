import 'package:flutter/material.dart';

class RecentlyPlayedSection extends StatelessWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recently Played",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "Clear all",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (context, index) {
            return RecentlyPlayedItem(
              title: "Night Drive Phonk ${index + 1}",
              artist: "DarkBeats",
              duration: "3:${20 + index}",
              playedAgo: "${index + 1}h ago",
            );
          },
        ),
      ],
    );
  }
}

// Recently Played Item Widget
class RecentlyPlayedItem extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final String playedAgo;

  const RecentlyPlayedItem({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.playedAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Album art
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.purple[700]!, Colors.purple[500]!],
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      artist,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      " • $playedAgo",
                      style: TextStyle(color: Colors.purple[300], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duration & play button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.play_arrow,
                  color: Colors.purple[300],
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
