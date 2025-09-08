import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/recently_played_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/recent_play_widget/recently_played_item.dart';
import 'dart:async';

import 'package:phonkers/view/widget/toast_util.dart';

class RecentlyPlayedSection extends StatefulWidget {
  const RecentlyPlayedSection({super.key});

  @override
  State<RecentlyPlayedSection> createState() => _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends State<RecentlyPlayedSection>
    with NetworkAwareMixin {
  final RecentlyPlayedService _recentlyPlayedService = RecentlyPlayedService();

  List<RecentlyPlayedTrack> _recentTracks = [];
  bool _isLoading = true;
  String? _error;

  // Audio state management
  late StreamSubscription<Phonk?> _currentPhonkSubscription;
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<bool> _isLoadingSubscription;

  Phonk? _currentPhonk;
  bool _isPlaying = false;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _loadRecentlyPlayed();
  }

  void _initializeStreams() {
    // Listen to audio service to track new plays
    _currentPhonkSubscription = AudioPlayerService.currentPhonkStream.listen((
      phonk,
    ) {
      if (mounted) {
        final previousPhonk = _currentPhonk; // store old value

        setState(() {
          _currentPhonk = phonk;
          debugPrint(
            "1) Current Phonk after setstate: ${_currentPhonk?.title} --debugPrint",
          );
        });

        if (phonk != null &&
            (previousPhonk == null || previousPhonk.id != phonk.id)) {
          debugPrint(
            "3) Adding new phonk to recently played: ${phonk.title} --debugPrint",
          );
          _recentlyPlayedService.addTrack(phonk);
          _loadRecentlyPlayed();
          debugPrint(
            "5) Current Phonk after adding to recently played: ${_currentPhonk?.title} --debugPrint --added",
          );
        } else {
          debugPrint(
            "4) Current Phonk is the same as before: $previousPhonk --debugPrint",
          );
        }
      }
    });

    _isPlayingSubscription = AudioPlayerService.isPlayingStream.listen((
      playing,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    _isLoadingSubscription = AudioPlayerService.isLoadingStream.listen((
      loading,
    ) {
      if (mounted) {
        setState(() {
          _isAudioLoading = loading;
        });
      }
    });

    // Get initial state
    _currentPhonk = AudioPlayerService.currentPhonk;
    _isPlaying = AudioPlayerService.isPlaying;
    _isAudioLoading = AudioPlayerService.isLoading;
    debugPrint(
      "2) Current Phonk after setstate: ${_currentPhonk?.title} --debugPrint",
    );
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tracks = await _recentlyPlayedService.getRecentlyPlayed(limit: 5);

      if (mounted) {
        setState(() {
          _recentTracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load recently played tracks';
          _isLoading = false;
        });
      }
      debugPrint('Error loading recently played: $e');
    }
  }

  Future<void> _clearRecentlyPlayed() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E0A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Clear Recently Played',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to clear all recently played tracks? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await _recentlyPlayedService.clearAll();
      _loadRecentlyPlayed();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recently played history cleared'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _playTrack(RecentlyPlayedTrack recentTrack) async {
    // Convert RecentlyPlayedTrack back to Phonk for playback
    final phonk = Phonk(
      id: recentTrack.trackId,
      title: recentTrack.title,
      artist: recentTrack.artist,
      previewUrl: recentTrack.previewUrl,
      spotifyUrl: recentTrack.spotifyUrl,
      youtubeUrl: recentTrack.youtubeUrl,
      plays: recentTrack.plays,
      duration: recentTrack.duration ?? 0,
      // imageUrl: recentTrack.imageUrl,
    );

    if (mounted) {
      ToastUtil.showToast(
        context,
        "Please give me a sec...",
        background: Colors.deepPurpleAccent,
      );
    }

    final result = await executeWithNetworkCheck(
      action: () async {
        return await AudioPlayerService.playPhonk(phonk);
      },
      onNoInternet: () {
        _showNetworkError();
      },
      showSnackBar: false,
    );

    if (result != null && mounted) {
      _handlePlayResult(result, phonk);
    }
  }

  void _handlePlayResult(PlayResult result, Phonk phonk) {
    switch (result) {
      case PlayResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: ${phonk.title}'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case PlayResult.noPreview:
        _showNoPreviewDialog(phonk);
        break;
      case PlayResult.error:
        _showErrorSnackbar('Error playing ${phonk.title}');
        break;
      case PlayResult.loading:
        // Loading handled by streams
        break;
    }
  }

  void _showNetworkError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Text('Internet connection required for audio playback'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNoPreviewDialog(Phonk phonk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E0A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'No Preview Available',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${phonk.title}\nby ${phonk.artist}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This track doesn\'t have a preview available.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _currentPhonkSubscription.cancel();
    _isPlayingSubscription.cancel();
    _isLoadingSubscription.cancel();
    super.dispose();
  }

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
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Recently Played",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _recentTracks.isEmpty ? null : _clearRecentlyPlayed,
                icon: Icon(
                  Icons.clear_all,
                  size: 16,
                  color: _recentTracks.isEmpty
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                label: Text(
                  "Clear all",
                  style: TextStyle(
                    color: _recentTracks.isEmpty
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadRecentlyPlayed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recentTracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.music_note_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No recently played tracks',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tracks you play will appear here',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _recentTracks.length,
      itemBuilder: (context, index) {
        final track = _recentTracks[index];
        final isCurrentlyPlaying = _currentPhonk?.id == track.trackId;

        return RecentlyPlayedItem(
          track: track,
          isCurrentlyPlaying: isCurrentlyPlaying,
          isPlaying: _isPlaying && isCurrentlyPlaying,
          isLoading: _isAudioLoading && isCurrentlyPlaying,
          onPlay: () => _playTrack(track),
          onPlayPause: () async {
            if (_isPlaying) {
              AudioPlayerService.pause();
            } else {
              AudioPlayerService.resume();
            }
          },
        );
      },
    );
  }
}
