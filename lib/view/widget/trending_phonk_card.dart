// widgets/trending_phonk_card.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/phonk_play_button.dart';
import 'package:phonkers/view/widget/playback_options_bottom_sheet.dart';
import 'package:phonkers/view/widget/streaming_indicator.dart'
    show StreamingIndicators;

class TrendingPhonkCard extends StatefulWidget {
  final Phonk phonk;
  final VoidCallback? onTap;

  const TrendingPhonkCard({super.key, required this.phonk, this.onTap});

  @override
  State<TrendingPhonkCard> createState() => _TrendingPhonkCardState();
}

class _TrendingPhonkCardState extends State<TrendingPhonkCard> {
  final UserFavoritesService _favoritesService = UserFavoritesService();
  bool _isFavorited = false;
  bool _isLoadingFav = false;
  Timer? _loadingMessageTimer;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  @override
  void dispose() {
    _loadingMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkIfFavorited() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isFav = await _favoritesService.isFavorited(
        user.uid,
        widget.phonk.id,
      );
      if (mounted) {
        setState(() {
          _isFavorited = isFav;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlbumArt(),
              const SizedBox(height: 12),
              _buildTrackInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 160,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Album Art Image
          _buildAlbumArtImage(),

          // Overlay gradient
          _buildOverlayGradient(),

          // Top badges and favorite button
          _buildTopRow(),

          // Play button (center)
          _buildCenterPlayButton(),

          // Duration badge (bottom left)
          _buildDurationBadge(),
        ],
      ),
    );
  }

  Widget _buildAlbumArtImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: widget.phonk.albumArt != null
          ? CachedNetworkImage(
              imageUrl: widget.phonk.albumArt!,
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[800]!, Colors.purple[600]!],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, size: 40, color: Colors.white70),
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // NEW badge
          if (widget.phonk.isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "NEW",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          // Favorite button
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: _isLoadingFav
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: Colors.white,
                ),
              )
            : Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : Colors.white,
                size: 16,
              ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Positioned.fill(
      child: Center(
        child: PhonkPlayButton(
          phonk: widget.phonk,
          onTap: _handlePlay,
          onLongPress: _handleStop,
        ),
      ),
    );
  }

  Widget _buildDurationBadge() {
    if (widget.phonk.duration <= 0) return const SizedBox.shrink();

    return Positioned(
      bottom: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.phonk.formattedDuration,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with streaming indicators
        Row(
          children: [
            Expanded(
              child: Text(
                widget.phonk.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            StreamingIndicators(phonk: widget.phonk),
          ],
        ),

        const SizedBox(height: 4),

        // Artist
        Text(
          widget.phonk.artist,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Play count
        Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 14,
              color: Colors.purple[300],
            ),
            const SizedBox(width: 4),
            Text(
              "${widget.phonk.formattedPlays} plays",
              style: TextStyle(
                color: Colors.purple[300],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePlay() async {
    try {
      print("phonk to be played ${widget.phonk}");

      // Check if this phonk is currently playing
      final currentPhonk = AudioPlayerService.currentPhonk;
      final isPlaying = AudioPlayerService.isPlaying;
      final isCurrentPhonk = currentPhonk?.id == widget.phonk.id;

      if (isCurrentPhonk && isPlaying) {
        // If this phonk is currently playing, pause it
        await AudioPlayerService.pause();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paused: ${widget.phonk.title}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      } else if (isCurrentPhonk && !isPlaying) {
        // If this phonk is paused, resume it
        await AudioPlayerService.resume();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resumed: ${widget.phonk.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      // Start delayed loading message timer
      _loadingMessageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && AudioPlayerService.isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Please wait... This may take a few seconds',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.blue[700],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      // If it's a different phonk or no phonk is loaded, play this one
      final result = await AudioPlayerService.playPhonk(widget.phonk);

      // Cancel the loading message timer since we have a result
      _loadingMessageTimer?.cancel();

      if (!mounted) return;

      switch (result) {
        case PlayResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing: ${widget.phonk.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
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
                  Text('Loading audio...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
          break;

        case PlayResult.noPreview:
          PlaybackOptionsBottomSheet.show(context, widget.phonk);
          break;

        case PlayResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing ${widget.phonk.title}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          break;
      }
    } catch (e) {
      // Cancel timer on error
      _loadingMessageTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleStop() async {
    try {
      await AudioPlayerService.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stopped playback'),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add favorites'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingFav = true;
    });

    try {
      final newState = await _favoritesService.toggleFavorite(
        user.uid,
        widget.phonk.id,
        widget.phonk,
      );

      if (mounted) {
        setState(() {
          _isFavorited = newState;
          _isLoadingFav = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'Added to favorites ❤️' : 'Removed from favorites',
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFav = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
