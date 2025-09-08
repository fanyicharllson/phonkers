import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';

class TrendingPhonkListItem extends StatelessWidget {
  final Phonk phonk;
  final int index;
  final bool isCurrentlyPlaying;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const TrendingPhonkListItem({
    super.key,
    required this.phonk,
    required this.index,
    required this.isCurrentlyPlaying,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.onTap,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentlyPlaying
              ? [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.purple.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyPlaying
              ? Colors.purple.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: isCurrentlyPlaying ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildLeading(),
            title: _buildTitle(),
            subtitle: _buildSubtitle(),
            trailing: _buildTrailing(),
            onTap: isCurrentlyPlaying ? null : onTap,
          ),
          
          // Progress indicator for currently playing track
          if (isCurrentlyPlaying && position.inMilliseconds > 0)
            _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildLeading() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrentlyPlaying
                  ? [Colors.purple.shade400, Colors.purple.shade600]
                  : [Colors.grey.shade600, Colors.grey.shade800],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$index',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Overlay for current state
        if (isCurrentlyPlaying) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          if (isLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      phonk.title,
      style: TextStyle(
        color: isCurrentlyPlaying ? Colors.purple.shade200 : Colors.white,
        fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w600,
        fontSize: 15,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                phonk.artist,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentlyPlaying && isPlaying && !isLoading) ...[
              Icon(
                Icons.equalizer,
                color: Colors.purple.shade300,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Playing',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatPlayCount(phonk.plays)} plays',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing() {
    if (isCurrentlyPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              isLoading
                  ? Icons.hourglass_empty
                  : isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
              color: Colors.purple,
              size: 28,
            ),
            onPressed: isLoading ? null : onPlayPause,
          ),
          
          // Stop button
          IconButton(
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.red,
              size: 24,
            ),
            onPressed: onStop,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDuration(phonk.duration), //! Default 30s for previews
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.play_circle_outline,
          color: Colors.white54,
          size: 24,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    const totalDuration = Duration(seconds: 30);
    final progress = totalDuration.inMilliseconds > 0
        ? position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                '0:30',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}