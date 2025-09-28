import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'dart:async';

import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';

class SearchResultItemWidget extends StatefulWidget {
  final Map<String, dynamic> track;
  final Function(Map<String, dynamic>) onPlayTrack;
  final bool isFavorite;
  final bool isFavLoading;
  final void Function() toggleFavorite;

  const SearchResultItemWidget({
    super.key,
    required this.track,
    required this.onPlayTrack,
    required this.isFavLoading,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  State<SearchResultItemWidget> createState() => _SearchResultItemWidgetState();
}

class _SearchResultItemWidgetState extends State<SearchResultItemWidget>
    with NetworkAwareMixin {
  late StreamSubscription<Phonk?> _currentPhonkSubscription;
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<bool> _isLoadingSubscription;
  late StreamSubscription<Duration> _positionSubscription;

  // Local state to maintain playing status
  Phonk? _currentPhonk;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;

  String? _videoId;
  bool _isCurrentlyPlaying = false;

  // Loading timeout management
  Timer? _loadingTimeoutTimer;
  bool _hasShownTimeoutMessage = false;
  static const Duration _loadingTimeoutDuration = Duration(
    seconds: 8,
  ); // Configurable timeout

  @override
  void initState() {
    super.initState();
    _videoId = widget.track['id']?['videoId'] ?? widget.track['id'];
    _initializeStreams();
    _updateCurrentPlayingState();
  }

  void _initializeStreams() {
    // Subscribe to all audio service streams
    _currentPhonkSubscription = AudioPlayerService.currentPhonkStream.listen((
      phonk,
    ) {
      if (mounted) {
        setState(() {
          _currentPhonk = phonk;
          _updateCurrentPlayingState();
        });
      }
    });

    _isPlayingSubscription = AudioPlayerService.isPlayingStream.listen((
      playing,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          // If music starts playing, cancel timeout timer and reset message flag
          if (playing && _isCurrentlyPlaying) {
            _cancelLoadingTimeout();
            _hasShownTimeoutMessage = false;
          }
        });
      }
    });

    _isLoadingSubscription = AudioPlayerService.isLoadingStream.listen((
      loading,
    ) {
      if (mounted) {
        setState(() {
          _isLoading = loading;

          // Handle loading timeout
          if (loading && _isCurrentlyPlaying) {
            _startLoadingTimeout();
          } else {
            _cancelLoadingTimeout();
            _hasShownTimeoutMessage = false;
          }
        });
      }
    });

    _positionSubscription = AudioPlayerService.positionStream.listen((
      position,
    ) {
      if (mounted && _isCurrentlyPlaying) {
        setState(() {
          _position = position;
        });
      }
    });

    // Get initial state
    _currentPhonk = AudioPlayerService.currentPhonk;
    _isPlaying = AudioPlayerService.isPlaying;
    _isLoading = AudioPlayerService.isLoading;
    _position = AudioPlayerService.currentPosition;
    _updateCurrentPlayingState();
  }

  void _startLoadingTimeout() {
    _cancelLoadingTimeout(); // Cancel any existing timer
    _loadingTimeoutTimer = Timer(_loadingTimeoutDuration, () {
      if (mounted &&
          _isLoading &&
          _isCurrentlyPlaying &&
          !_hasShownTimeoutMessage) {
        _hasShownTimeoutMessage = true;
        _showLoadingTimeoutMessage();
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
  }

  void _showLoadingTimeoutMessage() {
    if (!mounted) return;

    // final trackTitle = widget.track['snippet']?['title'] ?? 'Track';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hourglass_top,
                color: Colors.orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Still loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Please wait, we\'re fetching the audio for you',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.orange,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _updateCurrentPlayingState() {
    final wasPlaying = _isCurrentlyPlaying;
    _isCurrentlyPlaying = _currentPhonk?.id == _videoId;

    // If no longer playing this track, cancel timeout and reset flag
    if (wasPlaying && !_isCurrentlyPlaying) {
      _cancelLoadingTimeout();
      _hasShownTimeoutMessage = false;
    }

    // If the playing state changed, trigger a rebuild
    if (wasPlaying != _isCurrentlyPlaying) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didUpdateWidget(SearchResultItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update video ID if track changed
    final newVideoId = widget.track['id']?['videoId'] ?? widget.track['id'];
    if (_videoId != newVideoId) {
      _videoId = newVideoId;
      _cancelLoadingTimeout();
      _hasShownTimeoutMessage = false;
      _updateCurrentPlayingState();
    }
  }

  @override
  void dispose() {
    _cancelLoadingTimeout();
    _currentPhonkSubscription.cancel();
    _isPlayingSubscription.cancel();
    _isLoadingSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snippet = widget.track['snippet'] ?? {};
    final title = snippet['title'] ?? 'Unknown Title';
    final channelTitle = snippet['channelTitle'] ?? 'Unknown Artist';
    final thumbnailUrl =
        snippet['thumbnails']?['medium']?['url'] ??
        snippet['thumbnails']?['default']?['url'];
    final description = snippet['description'] ?? '';

    // Determine loading state for this specific item
    final showLoadingForThis = _isLoading && _isCurrentlyPlaying;

    return _buildListTile(
      title: title,
      channelTitle: channelTitle,
      thumbnailUrl: thumbnailUrl,
      description: description,
      isCurrentlyPlaying: _isCurrentlyPlaying,
      isPlaying: _isPlaying,
      isLoading: showLoadingForThis,
      position: _position,
      context: context,
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
            subtitle: _buildSubtitle(channelTitle, description, isLoading),
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
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            // Add a subtle pulsing effect for extended loading
            if (_hasShownTimeoutMessage)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
          ],
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

  Widget _buildSubtitle(
    String channelTitle,
    String description,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channelTitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Show loading message in subtitle when appropriate
        if (isLoading && _hasShownTimeoutMessage) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.hourglass_top,
                size: 10,
                color: Colors.orange.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Fetching audio...',
                style: TextStyle(
                  color: Colors.orange.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ] else if (description.isNotEmpty) ...[
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
    if (widget.track['isFallback'] == true) {
      return const Icon(Icons.open_in_new, color: Colors.orange, size: 20);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Always show favorite button
        GestureDetector(
          onTap: widget.toggleFavorite,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: widget.isFavLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite ? Colors.red : Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ),
        // Only show controls if currently playing
        if (isCurrentlyPlaying) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Combine play/pause and stop into a single compact row
              GestureDetector(
                onTap: isLoading ? null : () => _handlePlayPause(isPlaying),
                child: Icon(
                  isLoading
                      ? (_hasShownTimeoutMessage
                            ? Icons.hourglass_bottom
                            : Icons.hourglass_empty)
                      : isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: isLoading && _hasShownTimeoutMessage
                      ? Colors.orange
                      : Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _cancelLoadingTimeout();
                  _hasShownTimeoutMessage = false;
                  AudioPlayerService.stop();
                },
                child: const Icon(Icons.stop, color: Colors.red, size: 18),
              ),
            ],
          ),
        ],
      ],
    );
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
              const Text(
                '0:30', // YouTube preview duration
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(
    bool isCurrentlyPlaying,
    bool isPlaying,
    bool isLoading,
  ) async {
    if (isLoading) return;

    if (isCurrentlyPlaying) {
      _handlePlayPause(isPlaying);
    } else {
      // Reset timeout message flag for new track
      _hasShownTimeoutMessage = false;

      // Immediately show loading before service updates
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isCurrentlyPlaying = true;
        });
      }

      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          _showMessage("No internet Connection!");
        }
        return;
      }

      widget.onPlayTrack(widget.track);
    }
  }

  void _handlePlayPause(bool isPlaying) {
    if (isPlaying) {
      AudioPlayerService.pause();
    } else {
      AudioPlayerService.resume();
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isCurrentlyPlaying = false;
      });
    }
    _cancelLoadingTimeout();
    _hasShownTimeoutMessage = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );
  }
}
