import 'package:flutter/material.dart';
import 'package:phonkers/data/service/recently_played_service.dart';

class RecentlyPlayedItem extends StatelessWidget {
  final RecentlyPlayedTrack track;
  final bool isCurrentlyPlaying;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlay;
  final VoidCallback onPlayPause;

  const RecentlyPlayedItem({
    super.key,
    required this.track,
    required this.isCurrentlyPlaying,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlay,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentlyPlaying
              ? [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying
              ? Colors.purple.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _buildAlbumArt(),
          const SizedBox(width: 12),
          _buildSongInfo(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: isCurrentlyPlaying
                  ? [Colors.purple.shade400, Colors.purple.shade600]
                  : [Colors.purple.shade700, Colors.purple.shade500],
            ),
          ),
          child: track.imageUrl != null && track.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 20,
                      );
                    },
                  ),
                )
              : const Icon(Icons.music_note, color: Colors.white, size: 20),
        ),

        // Overlay for currently playing track
        if (isCurrentlyPlaying) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          Positioned.fill(
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],

        // History indicator
        if (!isCurrentlyPlaying)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildSongInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.title,
            style: TextStyle(
              color: isCurrentlyPlaying ? Colors.purple.shade200 : Colors.white,
              fontSize: 15,
              fontWeight: isCurrentlyPlaying
                  ? FontWeight.bold
                  : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  track.artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                " • ${track.timeAgo}",
                style: TextStyle(
                  color: isCurrentlyPlaying
                      ? Colors.purple.shade300
                      : Colors.purple.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Additional info for currently playing
          if (isCurrentlyPlaying && isPlaying && !isLoading) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.equalizer, color: Colors.purple.shade300, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Colors.purple.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          track.formattedDuration,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),

        if (isCurrentlyPlaying) ...[
          // Play/Pause button for currently playing track
          IconButton(
            onPressed: isLoading ? null : onPlayPause,
            icon: Icon(
              isLoading
                  ? Icons.hourglass_empty
                  : isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: isLoading
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.purple,
              size: 24,
            ),
          ),
        ] else ...[
          // Regular play button
          IconButton(
            onPressed: onPlay,
            icon: Icon(
              Icons.play_arrow,
              color: Colors.purple.shade300,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
