import 'package:flutter/material.dart';

class FeaturedPhonkControls extends StatelessWidget {
  final bool isCurrentlyPlaying;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final VoidCallback onFavorite;

  const FeaturedPhonkControls({
    super.key,
    required this.isCurrentlyPlaying,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlay,
    required this.onStop,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildPlayButton(), _buildSecondaryControls()],
    );
  }

  Widget _buildPlayButton() {
    if (isCurrentlyPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          ElevatedButton.icon(
            onPressed: isLoading ? null : onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoading ? Colors.grey : Colors.white,
              foregroundColor: isLoading ? Colors.white54 : Colors.purple[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: isLoading ? 0 : 2,
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 20),
            label: Text(
              isLoading
                  ? "Loading..."
                  : isPlaying
                  ? "Pause"
                  : "Resume",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 8),

          // Stop Button
          if (!isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: onStop,
                icon: const Icon(Icons.stop, color: Colors.white, size: 20),
                tooltip: 'Stop',
              ),
            ),
        ],
      );
    }

    // Initial Play Button
    return ElevatedButton.icon(
      onPressed: onPlay,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.purple[700],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 2,
      ),
      icon: const Icon(Icons.play_arrow, size: 20),
      label: const Text(
        "Play Now",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Favorite Button
        IconButton(
          onPressed: onFavorite,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
          ),
          tooltip: 'Add to Favorites',
        ),

        // Volume/Equalizer indicator when playing
        if (isCurrentlyPlaying && isPlaying && !isLoading) ...[
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.equalizer, color: Colors.white, size: 20),
          ),
        ],
      ],
    );
  }
}
