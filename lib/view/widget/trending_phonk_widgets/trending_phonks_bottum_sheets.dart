import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/phonk_service.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/toast_util.dart';
import 'dart:async';

import 'trending_phonk_list_item.dart';
import 'trending_bottom_sheet_header.dart';

class TrendingPhonksBottomSheet extends StatefulWidget {
  const TrendingPhonksBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TrendingPhonksBottomSheet(),
    );
  }

  @override
  State<TrendingPhonksBottomSheet> createState() =>
      _TrendingPhonksBottomSheetState();
}

class _TrendingPhonksBottomSheetState extends State<TrendingPhonksBottomSheet>
    with NetworkAwareMixin, TickerProviderStateMixin {
  final PhonkService _phonkService = PhonkService();
  final ScrollController _scrollController = ScrollController();

  // Audio state management
  late StreamSubscription<Phonk?> _currentPhonkSubscription;
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<bool> _isLoadingSubscription;
  late StreamSubscription<Duration> _positionSubscription;

  // Data state
  List<Phonk> _trendingPhonks = [];
  bool _isLoading = true;
  String? _error;
  bool _isNetworkError = false;

  // Current audio state
  Phonk? _currentPhonk;
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  Duration _position = Duration.zero;

  // Auto-play functionality
  int _currentPlayingIndex = -1;
  bool _autoPlayEnabled = true;
  Timer? _autoPlayTimer;

  // Animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeStreams();
    _loadTrendingPhonks();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  void _initializeStreams() {
    _currentPhonkSubscription = AudioPlayerService.currentPhonkStream.listen((
      phonk,
    ) {
      if (mounted) {
        setState(() {
          _currentPhonk = phonk;
          _updateCurrentPlayingIndex();
        });
      }
    });

    _isPlayingSubscription = AudioPlayerService.isPlayingStream.listen((
      playing,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          if (playing) {
            _cancelAutoPlayTimer();
          }
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

    _positionSubscription = AudioPlayerService.positionStream.listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _position = position;
        });
        _checkForAutoPlay(position);
      }
    });

    // Get initial state
    _currentPhonk = AudioPlayerService.currentPhonk;
    _isPlaying = AudioPlayerService.isPlaying;
    _isAudioLoading = AudioPlayerService.isLoading;
    _position = AudioPlayerService.audiocurrentPosition;
    _updateCurrentPlayingIndex();
  }

  void _updateCurrentPlayingIndex() {
    if (_currentPhonk != null) {
      _currentPlayingIndex = _trendingPhonks.indexWhere(
        (phonk) => phonk.id == _currentPhonk!.id,
      );
    } else {
      _currentPlayingIndex = -1;
    }
  }

  void _checkForAutoPlay(Duration position) {
    if (!_autoPlayEnabled || !_isPlaying || _currentPlayingIndex == -1) return;

    // Check if we're near the end (28 seconds for 30-second preview)
    if (position.inSeconds >= 28) {
      _startAutoPlayTimer();
    }
  }

  void _startAutoPlayTimer() {
    _cancelAutoPlayTimer();
    _autoPlayTimer = Timer(const Duration(seconds: 1), () {
      _playNext();
    });
  }

  void _cancelAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  Future<void> _playNext() async {
    if (_currentPlayingIndex == -1 ||
        _currentPlayingIndex >= _trendingPhonks.length - 1) {
      return;
    }

    final nextPhonk = _trendingPhonks[_currentPlayingIndex + 1];
    await _playPhonk(nextPhonk);

    // Scroll to show the next playing item
    _scrollToPlayingItem(_currentPlayingIndex + 1);
  }

  void _scrollToPlayingItem(int index) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 80.0, // Approximate item height
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadTrendingPhonks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isNetworkError = false;
      });

      final phonks = await executeWithNetworkCheck(
        action: () async {
          return await _phonkService.getTrendingPhonks(
            limit: 50,
          ); // Get more for better experience
        },
        onNoInternet: () {
          if (mounted) {
            setState(() {
              _error = 'No internet connection';
              _isNetworkError = true;
              _isLoading = false;
            });
          }
        },
        showSnackBar: false,
      );

      if (phonks != null) {
        setState(() {
          _trendingPhonks = phonks;
          _isLoading = false;
          _updateCurrentPlayingIndex();
        });
      }
    } catch (e) {
      if (mounted) {
        final hasInternet = await hasInternetConnection();
        setState(() {
          _error = hasInternet
              ? 'Failed to load trending phonks'
              : 'No internet connection';
          _isNetworkError = !hasInternet;
          _isLoading = false;
        });
      }
      debugPrint('Error loading trending phonks: $e');
    }
  }

  Future<void> _playPhonk(Phonk phonk) async {
    //!=============
    debugPrint("Showing loading now before playing trending phonk...");
    ToastUtil.showToast(
      context,
      'Please wait, why we load ${phonk.title}...',
      background: Colors.deepPurple,
      duration: Duration(seconds: 6),
    );

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
    } else {
      _showErrorSnackbar('Error playing ${phonk.title}');
      _isLoading = false;
      _isAudioLoading = false;
    }
  }

  void _handlePlayResult(PlayResult result, Phonk phonk) {
    switch (result) {
      case PlayResult.success:
        // Success is handled by stream updates
        break;
      case PlayResult.noPreview:
        _showNoPreviewDialog(phonk);
        break;
      case PlayResult.error:
        _showErrorSnackbar('Error playing ${phonk.title}');
        break;
      case PlayResult.loading:
        // Loading is handled by stream updates
        break;
    }
  }

  void _showNetworkError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Internet connection required for audio playback'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadTrendingPhonks(),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
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
              onPressed: () {
                Navigator.pop(context);
                if (_autoPlayEnabled) _playNext();
              },
              child: const Text(
                'Skip to Next',
                style: TextStyle(color: Colors.purple),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cancelAutoPlayTimer();
    _slideController.dispose();
    _scrollController.dispose();
    _currentPhonkSubscription.cancel();
    _isPlayingSubscription.cancel();
    _isLoadingSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            TrendingBottomSheetHeader(
              autoPlayEnabled: _autoPlayEnabled,
              onAutoPlayToggle: (enabled) {
                setState(() {
                  _autoPlayEnabled = enabled;
                });
                if (!enabled) _cancelAutoPlayTimer();
              },
              onClose: () => Navigator.pop(context),
              currentPhonk: _currentPhonk,
              isPlaying: _isPlaying,
              position: _position,
            ),

            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text(
              'Loading trending phonks...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _isNetworkError
          ? buildNoInternetError(
              onRetry: _loadTrendingPhonks,
              message: 'Connect to internet to see trending phonks',
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTrendingPhonks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
    }

    if (_trendingPhonks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No trending phonks found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _trendingPhonks.length,
      itemBuilder: (context, index) {
        final phonk = _trendingPhonks[index];
        final isCurrentlyPlaying = _currentPhonk?.id == phonk.id;

        return TrendingPhonkListItem(
          phonk: phonk,
          index: index + 1,
          isCurrentlyPlaying: isCurrentlyPlaying,
          isPlaying: _isPlaying,
          isLoading: _isAudioLoading && isCurrentlyPlaying,
          position: isCurrentlyPlaying ? _position : Duration.zero,
          onTap: () => _playPhonk(phonk),
          onPlayPause: () async {
            if (_isPlaying) {
              AudioPlayerService.pause();
            } else {
              AudioPlayerService.resume();
            }
          },
          onStop: () => AudioPlayerService.stop(),
        );
      },
    );
  }
}
