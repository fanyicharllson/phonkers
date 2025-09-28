import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/search_widgets/search_result_item_widget.dart';
import 'package:phonkers/view/widget/toast_util.dart';

class SearchResultsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> searchResults;
  final bool hasSearched;
  final String currentQuery;
  final Function(Map<String, dynamic>) onPlayTrack;
  final Animation<double> fadeAnimation;
  // final bool isTrackCurrentlyPlaying;  // Added field

  const SearchResultsWidget({
    super.key,
    required this.searchResults,
    required this.hasSearched,
    required this.currentQuery,
    required this.onPlayTrack,
    required this.fadeAnimation,
    // required this.isTrackCurrentlyPlaying,  // Added to constructor
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget>
    with NetworkAwareMixin {
  final UserFavoritesService _favoritesService = UserFavoritesService();

  final Map<String, bool> _favoriteStates = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _checkIfFavorited(widget.searchResults);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasSearched) {
      return const SizedBox.shrink();
    }

    if (widget.searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13), // 0.05 * 255 ≈ 13
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withAlpha(26),
          ), // 0.1 * 255 ≈ 26
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.white.withAlpha(153),
            ), // 0.6 * 255 ≈ 153
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withAlpha(204), // 0.8 * 255 ≈ 204
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: widget.searchResults.length,
              itemBuilder: (context, index) {
                final track = widget.searchResults[index];
                final id = track['id']?['videoId'] ?? track['id'];
                return SearchResultItemWidget(
                  track: track,
                  onPlayTrack: widget.onPlayTrack,
                  isFavorite: _favoriteStates[id] ?? false,
                  isFavLoading: _loadingStates[id] ?? false,
                  toggleFavorite: () => _toggleFavorite(track),
                  // isTrackCurrentlyPlaying: isTrackCurrentlyPlaying,  // Pass down here
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.queue_music, color: Colors.purple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Results for "${widget.currentQuery}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(51), // 0.2 * 255 ≈ 51
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.searchResults.length}',
              style: const TextStyle(
                color: Colors.purple,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Map<String, dynamic> track) async {
    final user = FirebaseAuth.instance.currentUser;
    final id = track['id']?['videoId'] ?? track['id'];
    final title = track['snippet']?['title'] ?? 'Unknown';
    final channelTitle = track['snippet']?['channelTitle'] ?? 'Unknown';

    final tempPhonk = Phonk(
      id: id,
      title: title,
      artist: channelTitle,
      albumName: 'YouTube Search',
      uploadDate: DateTime.now(),
      duration: 30,
      plays: 0,
      previewUrl: null,
      spotifyUrl: null,
    );

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
      _loadingStates[id] = true;
    });

    try {
      bool? newState;
      newState = await executeWithNetworkCheck(
        action: () async {
          return await _favoritesService.toggleFavorite(
            user.uid,
            id,
            tempPhonk,
          );
        },
        onNoInternet: () {
          if (mounted) {
            setState(() {
              _favoriteStates[id] = false;
              _loadingStates[id] = false;
            });
          }
          ToastUtil.showToast(
            context,
            "Please check your network connection and try again!",
            background: Colors.deepPurple,
            duration: Duration(seconds: 5),
          );
        },
        showSnackBar: false,
      );

      if (mounted && newState != null) {
        setState(() {
          _favoriteStates[id] = newState!;
          _loadingStates[id] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'Added to favorites ❤️' : 'Removed from favorites',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStates[id] = false;
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

  Future<void> _checkIfFavorited(List<Map<String, dynamic>> phonkList) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      for (var track in phonkList) {
        final id = track['id']?['videoId'] ?? track['id'];
        final isFav = await _favoritesService.isFavorited(user.uid, id);
        if (mounted) {
          setState(() {
            _favoriteStates[id] = isFav;
          });
        }
      }
    }
  }
}
