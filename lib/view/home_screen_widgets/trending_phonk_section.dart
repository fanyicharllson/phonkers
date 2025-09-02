import 'package:flutter/material.dart';
import 'package:phonkers/data/service/phonk_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/trending_phonk_card.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection>
    with NetworkAwareMixin {
  final PhonkService _phonkService = PhonkService();
  List<Phonk> _trendingPhonks = [];
  bool _isLoading = true;
  String _error = '';
  bool _isNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingPhonks();
  }

  Future<void> _loadTrendingPhonks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
        _isNetworkError = false;
      });

      // Check internet connection first
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          setState(() {
            _error = 'No internet connection';
            _isNetworkError = true;
            _isLoading = false;
          });
        }
        return;
      }

      final phonks = await _phonkService.getTrendingPhonks(limit: 10);

      if (mounted) {
        setState(() {
          _trendingPhonks = phonks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network-related error
        final hasInternet = await hasInternetConnection();
        setState(() {
          _error = hasInternet
              ? 'Failed to load trending phonks'
              : 'No internet connection';
          _isNetworkError = !hasInternet;
          _isLoading = false;
        });
      }
      print('Error loading trending phonks: $e');
    }
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
              const Text(
                "🔥🔥Trending Phonks",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to see all trending phonks
                },
                child: Text(
                  "See all",
                  style: TextStyle(
                    color: Colors.purple[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(height: 200, child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_error.isNotEmpty) {
      return _isNetworkError
          ? buildNoInternetError(
              onRetry: _loadTrendingPhonks,
              message: 'Connect to internet to see trending phonks',
            )
          : _buildGenericError();
    }

    if (_trendingPhonks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'No trending phonks found',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadTrendingPhonks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _trendingPhonks.length,
      itemBuilder: (context, index) {
        final phonk = _trendingPhonks[index];
        return TrendingPhonkCard(
          phonk: phonk,
          onTap: () => _handlePhonkTap(phonk),
        );
      },
    );
  }

  Widget _buildGenericError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 32),
          const SizedBox(height: 8),
          Text(
            _error,
            style: TextStyle(color: Colors.red[300], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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

  void _handlePhonkTap(Phonk phonk) async {
    // Check internet connection before trying to play
    final result = await executeWithNetworkCheck(
      action: () async {
        final playResult = await AudioPlayerService.playPhonk(phonk);
        print('Play result in handlePhonkTap: $playResult');
        return playResult;
      },
      onNoInternet: () {
        // Show a different message for audio playback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Text('Internet connection required for audio playback'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    switch (result) {
      case PlayResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing preview: ${phonk.title} by ${phonk.artist}'),
            backgroundColor: Colors.purple,
            action: SnackBarAction(
              label: 'Stop',
              textColor: Colors.white,
              onPressed: () async {
                await AudioPlayerService.stop();
              },
            ),
          ),
        );
        break;

      case PlayResult.loading:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading audio...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
        break;

      case PlayResult.noPreview:
        _showNoPreviewDialog(phonk);
        break;

      case PlayResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing ${phonk.title}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  void _showNoPreviewDialog(Phonk phonk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
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
                'This track doesn\'t have a preview available. You can listen to the full track on:',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            if (phonk.spotifyUrl != null)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  print('Opening Spotify: ${phonk.spotifyUrl}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening in Spotify...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.music_note, color: Colors.green),
                label: const Text(
                  'Open in Spotify',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                print('Searching YouTube: ${phonk.youtubeUrl}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening YouTube search...'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.video_library, color: Colors.red),
              label: const Text(
                'Search YouTube',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }
}
