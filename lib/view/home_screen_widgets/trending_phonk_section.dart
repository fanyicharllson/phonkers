import 'package:flutter/material.dart';
import 'package:phonkers/data/service/phonk_service.dart';
import 'package:phonkers/view/widget/trending_phonk_card.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final PhonkService _phonkService = PhonkService();
  List<Phonk> _trendingPhonks = [];
  bool _isLoading = true;
  String _error = '';

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
      });

      final phonks = await _phonkService.getTrendingPhonks(limit: 10);

      if (mounted) {
        setState(() {
          _trendingPhonks = phonks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load trending phonks';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 32),
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: Colors.red[300], fontSize: 14),
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
          onTap: () {
            // Handle phonk tap - play the track
            _handlePhonkTap(phonk);
          },
        );
      },
    );
  }

  void _handlePhonkTap(Phonk phonk) async {

    final response = await AudioPlayerService.playPhonk(phonk);
    print('Play result in handkePhonkTap: $response');

    final result = await AudioPlayerService.playPhonk(phonk);

    if (!mounted) return;

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
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading audio in TPSD...'),
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
          title: Text(
            'No Preview Available',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${phonk.title}\nby ${phonk.artist}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
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
                  // You can add URL launcher here later
                  print('Opening Spotify: ${phonk.spotifyUrl}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening in Spotify...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: Icon(Icons.music_note, color: Colors.green),
                label: Text(
                  'Open in Spotify',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                print('Searching YouTube: ${phonk.youtubeUrl}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening YouTube search...'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              icon: Icon(Icons.video_library, color: Colors.red),
              label: Text(
                'Search YouTube',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }
}
