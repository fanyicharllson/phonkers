import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';

class TrendingBottomSheetHeader extends StatelessWidget {
  final bool autoPlayEnabled;
  final Function(bool) onAutoPlayToggle;
  final VoidCallback onClose;
  final Phonk? currentPhonk;
  final bool isPlaying;
  final Duration position;

  const TrendingBottomSheetHeader({
    super.key,
    required this.autoPlayEnabled,
    required this.onAutoPlayToggle,
    required this.onClose,
    this.currentPhonk,
    required this.isPlaying,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: Colors.purple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Header content
          Row(
            children: [
              // Fire icon and title
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.red.shade500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trending Phonks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Top phonk tracks right now',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Auto-play toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.skip_next,
                      color: autoPlayEnabled ? Colors.purple : Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: autoPlayEnabled,
                      onChanged: onAutoPlayToggle,
                      activeThumbColor: Colors.purple,
                      inactiveThumbColor: Colors.white54,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Close button
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white70),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),

          // Now playing info (if any)
          if (currentPhonk != null) ...[
            const SizedBox(height: 16),
            _buildNowPlayingInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildNowPlayingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Play status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Colors.purple.shade200,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentPhonk!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentPhonk!.artist,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Progress info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of 0:30',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
