import 'package:flutter/material.dart';

class RecentSearchesWidget extends StatelessWidget {
  final List<String> recentSearches;
  final void Function(String) onSearchTap;
  final VoidCallback onClearAll;
  final Animation<double> fadeAnimation;

  const RecentSearchesWidget({
    super.key,
    required this.recentSearches,
    required this.onSearchTap,
    required this.onClearAll,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13), // ~0.05 opacity
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(26)), // ~0.1 opacity
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  return _buildSearchItem(context, recentSearches[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.history, color: Colors.purple, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Recent Searches',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(
            foregroundColor: Colors.purple.withAlpha(200),
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Clear All',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchItem(BuildContext context, String query) {
    return InkWell(
      onTap: () => onSearchTap(query),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withAlpha(20), // subtle purple background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.purple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16),
          ],
        ),
      ),
    );
  }
}
