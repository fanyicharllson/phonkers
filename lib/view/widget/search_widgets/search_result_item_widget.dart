import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';

class SearchResultItemWidget extends StatelessWidget {
  final Map<String, dynamic> track;
  final Function(Map<String, dynamic>) onPlayTrack;

  const SearchResultItemWidget({
    super.key,
    required this.track,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    final snippet = track['snippet'] ?? {};
    final title = snippet['title'] ?? 'Unknown Title';
    final channelTitle = snippet['channelTitle'] ?? 'Unknown Artist';
    final thumbnailUrl =
        snippet['thumbnails']?['medium']?['url'] ??
        snippet['thumbnails']?['default']?['url'];
    final description = snippet['description'] ?? '';
    final videoId = track['id']?['videoId'] ?? track['id'];

    return StreamBuilder<Phonk?>(
      stream: AudioPlayerService.currentPhonkStream,
      builder: (context, currentPhonkSnapshot) {
        final currentPhonk = currentPhonkSnapshot.data;
        final isCurrentlyPlaying = currentPhonk?.id == videoId;

        return StreamBuilder<bool>(
          stream: AudioPlayerService.isPlayingStream,
          builder: (context, playingSnapshot) {
            final isPlaying = playingSnapshot.data ?? false;

            return StreamBuilder<bool>(
              stream: AudioPlayerService.isLoadingStream,
              builder: (context, loadingSnapshot) {
                final isLoading = loadingSnapshot.data ?? false;
                final showLoadingForThis = isLoading && isCurrentlyPlaying;

                return StreamBuilder<Duration>(
                  stream: AudioPlayerService.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;

                    return _buildListTile(
                      title: title,
                      channelTitle: channelTitle,
                      thumbnailUrl: thumbnailUrl,
                      description: description,
                      isCurrentlyPlaying: isCurrentlyPlaying,
                      isPlaying: isPlaying,
                      isLoading: showLoadingForThis,
                      position: position,
                      context: context,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListTile({
    required String title,
    required String channelTitle,
    required String? thumbnailUrl,
    required String description,
    required bool isCurrentlyPlaying,
    required bool isPlaying,
    required bool isLoading,
    required Duration position,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentlyPlaying
              ? [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentlyPlaying
              ? Colors.purple.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildThumbnail(
              thumbnailUrl,
              isLoading,
              isCurrentlyPlaying,
              isPlaying,
            ),
            title: _buildTitle(title, isCurrentlyPlaying),
            subtitle: _buildSubtitle(channelTitle, description),
            trailing: _buildTrailingControls(
              isCurrentlyPlaying,
              isPlaying,
              isLoading,
            ),
            onTap: () => _handleTap(isCurrentlyPlaying, isPlaying, isLoading),
          ),
          if (isCurrentlyPlaying) _buildProgressIndicator(position),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    String? thumbnailUrl,
    bool isLoading,
    bool isCurrentlyPlaying,
    bool isPlaying,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: thumbnailUrl != null
              ? Image.network(
                  thumbnailUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultThumbnail();
                  },
                )
              : _buildDefaultThumbnail(),
        ),
        if (isLoading) _buildLoadingOverlay(),
        if (isCurrentlyPlaying && isPlaying && !isLoading)
          _buildPlayingOverlay(),
        if (isCurrentlyPlaying && !isPlaying && !isLoading)
          _buildPausedOverlay(),
      ],
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlayingOverlay() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.pause, color: Colors.white, size: 24),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
    );
  }

  Widget _buildTitle(String title, bool isCurrentlyPlaying) {
    return Text(
      title,
      style: TextStyle(
        color: isCurrentlyPlaying ? Colors.purple : Colors.white,
        fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w600,
        fontSize: 14,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(String channelTitle, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channelTitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingControls(
    bool isCurrentlyPlaying,
    bool isPlaying,
    bool isLoading,
  ) {
    if (track['isFallback'] == true) {
      return const Icon(Icons.open_in_new, color: Colors.orange, size: 20);
    }

    if (isCurrentlyPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            onPressed: isLoading ? null : () => _handlePlayPause(isPlaying),
          ),
          IconButton(
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.red,
              size: 24,
            ),
            onPressed: () => AudioPlayerService.stop(),
          ),
        ],
      );
    }

    return Icon(Icons.play_circle_filled, color: Colors.white70, size: 28);
  }

  Widget _buildProgressIndicator(Duration position) {
    // Assume 30-second preview for YouTube tracks
    const totalDuration = Duration(seconds: 30);
    final progress = totalDuration.inMilliseconds > 0
        ? position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const Spacer(),
              Text(
                '0:30', // YouTube preview duration
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  void _handleTap(bool isCurrentlyPlaying, bool isPlaying, bool isLoading) {
    if (isLoading) return; // Don't allow interactions while loading

    if (isCurrentlyPlaying) {
      _handlePlayPause(isPlaying);
    } else {
      onPlayTrack(track);
    }
  }

  void _handlePlayPause(bool isPlaying) {
    if (isPlaying) {
      AudioPlayerService.pause();
    } else {
      AudioPlayerService.resume();
    }
  }
}
