import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/search_widgets/search_result_item_widget.dart';

class SearchResultsWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!hasSearched) {
      return const SizedBox.shrink();
    }

    if (searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: fadeAnimation,
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
      opacity: fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return SearchResultItemWidget(
                  track: searchResults[index],
                  onPlayTrack: onPlayTrack,
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
              'Results for "$currentQuery"',
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
              '${searchResults.length}',
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
}
