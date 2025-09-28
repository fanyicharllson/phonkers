import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/library_widget/library_track_card.dart';

class LibraryList extends StatelessWidget {
  final List<Phonk> favorites;
  final UserFavoritesService favoritesService;
  final String userId;

  const LibraryList({
    super.key,
    required this.favorites,
    required this.favoritesService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LibraryStats(count: favorites.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return LibraryTrackCard(
                phonk: favorites[index],
                index: index,
                favoritesService: favoritesService,
                userId: userId,
              );
            },
          ),
        ),
      ],
    );
  }
}

class LibraryStats extends StatelessWidget {
  final int count;

  const LibraryStats({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.pink.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.queue_music,
            color: Colors.purpleAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count ${count == 1 ? 'Track' : 'Tracks'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'In your library',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.purple.withValues(alpha: 0.2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.pinkAccent,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Favorites',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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