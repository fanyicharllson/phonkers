import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/featured_widget/featured_phonk_controls.dart';
import 'package:phonkers/view/widget/featured_widget/featured_phonk_info.dart';
import 'package:phonkers/view/widget/toast_util.dart';
import 'package:phonkers/view/widget/wave_painter.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/phonk_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'dart:async';
import 'dart:math';

class FeaturedPhonkCard extends StatefulWidget {
  const FeaturedPhonkCard({super.key});

  @override
  State<FeaturedPhonkCard> createState() => _FeaturedPhonkCardState();
}

class _FeaturedPhonkCardState extends State<FeaturedPhonkCard>
    with NetworkAwareMixin, TickerProviderStateMixin {
  final PhonkService _phonkService = PhonkService();

  // Audio state management
  late StreamSubscription<Phonk?> _currentPhonkSubscription;
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<bool> _isLoadingSubscription;
  late StreamSubscription<Duration> _positionSubscription;

  // Featured phonk data
  Phonk? _featuredPhonk;
  bool _isLoadingPhonk = true;
  String? _error;

  // Current audio state
  bool _isCurrentlyPlaying = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;

  // Animation controller for visual effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Timeout state
  bool _hasShownTimeoutMessage = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeStreams();
    _loadFeaturedPhonk();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _initializeStreams() {
    _currentPhonkSubscription = AudioPlayerService.currentPhonkStream.listen((
      phonk,
    ) {
      if (mounted) {
        setState(() {
          _updateCurrentPlayingState(phonk);
        });
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
          _isLoading = loading;
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
    _updateCurrentPlayingState(AudioPlayerService.currentPhonk);
    _isPlaying = AudioPlayerService.isPlaying;
    _isLoading = AudioPlayerService.isLoading;
    _position = AudioPlayerService.audiocurrentPosition;
  }

  void _updateCurrentPlayingState(Phonk? currentPhonk) {
    _isCurrentlyPlaying =
        _featuredPhonk != null &&
        currentPhonk != null &&
        currentPhonk.id == _featuredPhonk!.id;
  }

  Future<void> _loadFeaturedPhonk() async {
    setState(() {
      _isLoadingPhonk = true;
      _error = null;
      _hasShownTimeoutMessage = false;
    });

    // Cancel previous timeout if any
    _timeoutTimer?.cancel();

    // Start timeout timer (5s)
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isLoadingPhonk && !_hasShownTimeoutMessage) {
        _hasShownTimeoutMessage = true;
        _showMessage("Still loading... please wait a moment", isSuccess: true);
      }
    });

    await executeWithNetworkCheck(
      action: () async {
        if (mounted) {
          _showMessage("Loading trending phonks...", isSuccess: true);
        }

        // Fetch trending phonks
        final trendingPhonks = await _phonkService.getTrendingPhonks(limit: 20);

        if (trendingPhonks.isNotEmpty) {
          final random = Random();
          final randomPhonk =
              trendingPhonks[random.nextInt(trendingPhonks.length)];

          if (mounted) {
            setState(() {
              _featuredPhonk = randomPhonk;
              _isLoadingPhonk = false;
              _updateCurrentPlayingState(AudioPlayerService.currentPhonk);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _error = 'No featured phonks available';
              _isLoadingPhonk = false;
            });
          }
        }
      },
      onNoInternet: () {
        setState(() {
          _error = 'No internet connection';
          _isLoadingPhonk = false;
        });
      },
      useToast: false,
    );

    // Cancel timeout after completion
    _timeoutTimer?.cancel();
  }

  Future<void> _handlePlayFeatured() async {
    if (_featuredPhonk == null) return;
    ToastUtil.showToast(
      context,
      "Please wait...",
      background: Colors.deepPurple,
    );
    await executeWithNetworkCheck(
      action: () async {
        if (_isCurrentlyPlaying) {
          if (_isPlaying) {
            AudioPlayerService.pause();
          } else {
            AudioPlayerService.resume();
          }
        } else {
          final result = await AudioPlayerService.playPhonk(_featuredPhonk!);
          _handlePlayResult(result);
        }
      },
      onNoInternet: () {
        _showMessage('Internet connection required for audio playback');
      },
    );
  }

  void _handlePlayResult(PlayResult result) {
    if (!mounted) return;

    switch (result) {
      case PlayResult.success:
        _showMessage('Playing: ${_featuredPhonk!.title}', isSuccess: true);
        break;
      case PlayResult.noPreview:
        _showNoPreviewDialog();
        break;
      case PlayResult.error:
        _showMessage('Error playing track');
        break;
      case PlayResult.loading:
        // Loading state handled by streams
        break;
    }
  }

  void _showNoPreviewDialog() {
    if (_featuredPhonk == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E0A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                '${_featuredPhonk!.title}\nby ${_featuredPhonk!.artist}',
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

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _currentPhonkSubscription.cancel();
    _isPlayingSubscription.cancel();
    _isLoadingSubscription.cancel();
    _positionSubscription.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isCurrentlyPlaying && _isPlaying
                ? _pulseAnimation.value
                : 1.0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isCurrentlyPlaying
                      ? [
                          const Color(0xFF8B5CF6),
                          const Color(0xFFA855F7),
                          const Color(0xFF7C3AED),
                          Colors.purple.shade800,
                        ]
                      : [
                          const Color(0xFF8B5CF6),
                          const Color(0xFFA855F7),
                          const Color(0xFF7C3AED),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isCurrentlyPlaying && _isPlaying
                        ? Colors.purple
                        : Colors.purple.withValues(alpha: 0.3)),
                    blurRadius: _isCurrentlyPlaying && _isPlaying ? 30 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(painter: WavePainter()),
                    ),
                  ),

                  // Progress indicator
                  if (_isCurrentlyPlaying && _position.inMilliseconds > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: LinearProgressIndicator(
                          value: _position.inMilliseconds / (30 * 1000),
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingPhonk) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Loading featured phonk...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFeaturedPhonk,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple[700],
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_featuredPhonk == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Featured badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isCurrentlyPlaying && _isPlaying
                      ? "🎵 Now Playing"
                      : "🔥 Featured Today",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Track info
          FeaturedPhonkInfo(
            phonk: _featuredPhonk!,
            isCurrentlyPlaying: _isCurrentlyPlaying,
          ),

          // Controls
          FeaturedPhonkControls(
            isCurrentlyPlaying: _isCurrentlyPlaying,
            isPlaying: _isPlaying,
            isLoading: _isLoading,
            onPlay: _handlePlayFeatured,
            onStop: () {
              AudioPlayerService.stop();
            },
            onFavorite: () =>
                _showMessage('Added to favorites!', isSuccess: true),
          ),
        ],
      ),
    );
  }
}
