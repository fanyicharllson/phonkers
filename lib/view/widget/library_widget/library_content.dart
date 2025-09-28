import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/library_widget/library_list.dart';
import 'package:phonkers/view/widget/library_widget/library_loading_state.dart';

class LibraryContent extends StatefulWidget {
  final String userId;
  final UserFavoritesService favoritesService;

  const LibraryContent({
    super.key,
    required this.userId,
    required this.favoritesService,
  });

  @override
  State<LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<LibraryContent> {
  // Key to force rebuild of StreamBuilder
  int _rebuildKey = 0;

  void _triggerRetry() {
    setState(() {
      _rebuildKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Phonk>>(
      key: ValueKey(_rebuildKey), // Force rebuild when key changes
      stream: widget.favoritesService.getUserFavorites(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LibraryLoadingState();
        }

        if (snapshot.hasError) {
          return LibraryErrorState(
            error: snapshot.error.toString(),
            onRetry: _triggerRetry, // Now this actually works
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return const LibraryEmptyState();
        }

        return LibraryList(
          favorites: favorites,
          favoritesService: widget.favoritesService,
          userId: widget.userId,
        );
      },
    );
  }
}
