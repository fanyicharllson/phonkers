import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/toast_util.dart';

class LibraryTrackCard extends StatefulWidget {
  final Phonk phonk;
  final int index;
  final UserFavoritesService favoritesService;
  final String userId;

  const LibraryTrackCard({
    super.key,
    required this.phonk,
    required this.index,
    required this.favoritesService,
    required this.userId,
  });

  @override
  State<LibraryTrackCard> createState() => _LibraryTrackCardState();
}

class _LibraryTrackCardState extends State<LibraryTrackCard>
    with SingleTickerProviderStateMixin, NetworkAwareMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isRemoving = false;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _removeFromFavorites() async {
    if (_isRemoving) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      await executeWithNetworkCheck(
        action: () async {
          await widget.favoritesService.removeFromFavorites(
            widget.userId,
            widget.phonk.id,
          );
        },
        onNoInternet: () {
          if (mounted) {
            setState(() {
              _isRemoving = false;
              _hasInternet = false;
            });
            ToastUtil.showToast(
              context,
              "No Internet Connection!",
              background: Colors.deepPurpleAccent,
            );
          }
        },
        showSnackBar: false,
      );

      setState(() {
        _isRemoving = false;
      });

      // Optional: Show success message
      if (mounted && _hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.phonk.title} removed from favorites',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${widget.phonk.title}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _playTrack() async {
    ToastUtil.showToast(
      context,
      "Wait please...",
      background: Colors.deepPurpleAccent,
      duration: Duration(seconds: 5),
    );

    final result = await executeWithNetworkCheck(
      action: () async {
        return await AudioPlayerService.playPhonk(widget.phonk);
      },
      onNoInternet: () {
        if (mounted) {
          ToastUtil.showToast(
            context,
            "Please connect to the internet and try again!",
            background: Colors.deepPurpleAccent,
            duration: Duration(seconds: 5),
          );
        }
      },
      showSnackBar: false,
    );

    if (result == PlayResult.noPreview && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No preview available for this track'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (result == PlayResult.error && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to play track'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.pink.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _playTrack,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Album Art or Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withValues(alpha: 0.8),
                              Colors.pink.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: widget.phonk.albumArt?.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.phonk.albumArt!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.queue_music_outlined,
                                      color: Colors.white,
                                      size: 30,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),

                      const SizedBox(width: 16),

                      // Track Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.phonk.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.phonk.artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (widget.phonk.duration > 0) ...[
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(widget.phonk.duration),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: widget.phonk.hasPreview
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    widget.phonk.hasPreview
                                        ? 'Preview'
                                        : 'YouTube',
                                    style: TextStyle(
                                      color: widget.phonk.hasPreview
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play/Pause/Loading Button with enhanced functionality
                          StreamBuilder<bool>(
                            stream: AudioPlayerService.isLoadingStream,
                            builder: (context, loadingSnapshot) {
                              final isLoading = loadingSnapshot.data ?? false;

                              return StreamBuilder<Phonk?>(
                                stream: AudioPlayerService.currentPhonkStream,
                                builder: (context, currentPhonkSnapshot) {
                                  final currentPhonk =
                                      currentPhonkSnapshot.data;
                                  final isCurrentTrack =
                                      currentPhonk?.id == widget.phonk.id;

                                  return StreamBuilder<bool>(
                                    stream: AudioPlayerService.isPlayingStream,
                                    builder: (context, playingSnapshot) {
                                      final isPlaying =
                                          playingSnapshot.data ?? false;
                                      final showAsPlaying =
                                          isCurrentTrack && isPlaying;

                                      return Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: showAsPlaying
                                                ? [
                                                    Colors.green.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                    Colors.lightGreen
                                                        .withValues(alpha: 0.8),
                                                  ]
                                                : [
                                                    Colors.purple.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                    Colors.pink.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                  ],
                                          ),
                                          // Add pulsing effect for currently playing track
                                          boxShadow: showAsPlaying
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            onTap: () async {
                                              if (isCurrentTrack && isPlaying) {
                                                // If this track is currently playing, pause it
                                                AudioPlayerService.pause();
                                              } else if (isCurrentTrack &&
                                                  !isPlaying) {
                                                // If this track is current but paused, resume it
                                                AudioPlayerService.resume();
                                              } else {
                                                // If this is a different track, play it
                                                _playTrack();
                                              }
                                            },
                                            child: isLoading && isCurrentTrack
                                                ? const Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Icon(
                                                    showAsPlaying
                                                        ? Icons.pause
                                                        : (isCurrentTrack &&
                                                              !isPlaying)
                                                        ? Icons.play_arrow
                                                        : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                          // Stop Button (only show when this track is currently playing or loading)
                          StreamBuilder<Phonk?>(
                            stream: AudioPlayerService.currentPhonkStream,
                            builder: (context, currentPhonkSnapshot) {
                              final currentPhonk = currentPhonkSnapshot.data;
                              final isCurrentTrack =
                                  currentPhonk?.id == widget.phonk.id;

                              return StreamBuilder<bool>(
                                stream: AudioPlayerService.isPlayingStream,
                                builder: (context, playingSnapshot) {
                                  final isPlaying =
                                      playingSnapshot.data ?? false;

                                  return StreamBuilder<bool>(
                                    stream: AudioPlayerService.isLoadingStream,
                                    builder: (context, loadingSnapshot) {
                                      final isLoading =
                                          loadingSnapshot.data ?? false;

                                      // Show stop button only if this track is current and (playing or loading)
                                      if (isCurrentTrack &&
                                          (isPlaying || isLoading)) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red.withValues(
                                              alpha: 0.2,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () {
                                                AudioPlayerService.stop();
                                              },
                                              child: const Icon(
                                                Icons.stop,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      // If not current or not playing, show spacing to maintain layout
                                      return const SizedBox(width: 4);
                                    },
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 4),

                          // Remove from Favorites Button
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: _isRemoving
                                    ? null
                                    : _removeFromFavorites,
                                child: _isRemoving
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.red,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
