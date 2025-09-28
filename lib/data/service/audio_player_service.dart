import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/phonk_service.dart';
import 'package:phonkers/data/service/youtube_audio_service.dart';

enum PlayResult { success, noPreview, error, loading }

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Phonk? _currentPhonk;
  static bool _isPlaying = false;
  static bool _isLoading = false;
  static StreamSubscription? _positionSubscription;
  static StreamSubscription? _stateSubscription;
  static bool _isInitiatingPlayback = false; // Add this flag

  // Streams for UI updates
  static final StreamController<Phonk?> _currentPhonkController =
      StreamController<Phonk?>.broadcast();
  static final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  static final StreamController<bool> _isLoadingController =
      StreamController<bool>.broadcast();
  static final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  static Stream<Phonk?> get currentPhonkStream =>
      _currentPhonkController.stream;
  static Stream<bool> get isPlayingStream => _isPlayingController.stream;
  static Stream<bool> get isLoadingStream => _isLoadingController.stream;
  static Stream<Duration> get positionStream => _positionController.stream;

  static Duration get currentPosition =>
      _audioPlayer.state == PlayerState.playing ||
          _audioPlayer.state == PlayerState.paused
      ? Duration
            .zero // Will be updated by the stream
      : Duration.zero;

  // Better approach - add a private variable to track current position
  static Duration _currentPosition = Duration.zero;

  // Add this getter instead
  static Duration get audiocurrentPosition => _currentPosition;

  static Phonk? get currentPhonk => _currentPhonk;
  static bool get isPlaying => _isPlaying;
  static bool get isLoading => _isLoading;
  static bool _stopRequested = false;

  static Future<void> initialize() async {
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _isPlayingController.add(_isPlaying);

      // Better loading state management
      if (state == PlayerState.playing) {
        // Only stop loading when actually playing
        _setLoadingState(false);
        _isInitiatingPlayback = false;
      } else if (state == PlayerState.stopped && !_isInitiatingPlayback) {
        // Only stop loading on stopped if we're not in the middle of initiating playback
        _setLoadingState(false);
        _currentPosition = Duration.zero;
      }
      // Don't change loading state for paused - user might have paused during loading
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Add error handling
    _audioPlayer.onLog.listen((message) {
      debugPrint('AudioPlayer Log: $message');
    });
  }

  static void _setLoadingState(bool loading) {
    _isLoading = loading;
    _isLoadingController.add(loading);
    debugPrint('Loading state changed to: $loading'); // Debug log
  }

  //! Enhanced playPhonk method with YouTube fallback
  static Future<PlayResult> playPhonk(Phonk phonk) async {
    try {
      _stopRequested = false; // Reset at the start
      _isInitiatingPlayback = true;
      _setLoadingState(true);
      _currentPhonk = phonk;
      _currentPhonkController.add(phonk);

      // Try Spotify first
      if (phonk.hasPreview && phonk.previewUrl?.isNotEmpty == true) {
        await _audioPlayer.stop();

        if (_stopRequested) return _handleCancelled();

        await _audioPlayer.play(UrlSource(phonk.previewUrl!));

        if (_stopRequested) return _handleCancelled();

        try {
          await PhonkService().incrementPlayCount(phonk.id);
        } catch (_) {}

        return PlayResult.success;
      }

      // Fallback to YouTube
      final youtubeData = await YouTubeAudioService.searchAndGetAudioUrl(
        phonk.artist,
        phonk.title,
        additionalQuery: 'phonk',
      );

      if (_stopRequested) return _handleCancelled();

      if (youtubeData != null && youtubeData['audioUrl'] != null) {
        await _audioPlayer.stop();

        if (_stopRequested) return _handleCancelled();

        await _audioPlayer.play(UrlSource(youtubeData['audioUrl']));

        if (_stopRequested) return _handleCancelled();

        try {
          await PhonkService().incrementPlayCount(phonk.id);
        } catch (_) {}

        return PlayResult.success;
      }

      return _handleCancelled();
    } catch (e) {
      debugPrint('Error playing phonk: $e');
      return PlayResult.error;
    } finally {
      _isInitiatingPlayback = false;
      _setLoadingState(false);
    }
  }

  //! Play from YouTube directly (for when user selects YouTube option)
  static Future<PlayResult> playFromYouTube(String artist, String title) async {
    try {
      _isInitiatingPlayback = true;
      _setLoadingState(true);

      final youtubeData = await YouTubeAudioService.searchAndGetAudioUrl(
        artist,
        title,
        additionalQuery: 'phonk',
      );

      if (youtubeData != null && youtubeData['audioUrl'] != null) {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(youtubeData['audioUrl']));

        debugPrint('Playing from YouTube: ${youtubeData['title']}');
        return PlayResult.success;
      }

      _isInitiatingPlayback = false;
      _setLoadingState(false);
      return PlayResult.error;
    } catch (e) {
      debugPrint('Error playing from YouTube: $e');
      _isInitiatingPlayback = false;
      _setLoadingState(false);
      return PlayResult.error;
    }
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
  }

  static Future<void> resume() async {
    await _audioPlayer.resume();
  }

  static Future<void> stop() async {
    _stopRequested = true;
    await _audioPlayer.stop();
    _currentPhonk = null;
    _currentPosition = Duration.zero;
    _currentPhonkController.add(null);
    _isInitiatingPlayback = false;
    _setLoadingState(false);
  }

  static Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  static PlayResult _handleCancelled() {
    _currentPhonk = null;
    _currentPhonkController.add(null);
    _isInitiatingPlayback = false;
    _setLoadingState(false);
    return PlayResult.error; // or a custom PlayResult.cancelled
  }

  static void dispose() {
    YouTubeAudioService.dispose();
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _currentPhonkController.close();
    _isPlayingController.close();
    _isLoadingController.close();
    _positionController.close();
  }
}
