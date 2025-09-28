import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/data/service/user_favorite_service.dart';
import 'package:phonkers/view/widget/library_widget/library_content.dart';
import 'package:phonkers/view/widget/library_widget/library_header.dart';
import 'package:phonkers/view/widget/library_widget/library_login_prompt.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  final UserFavoritesService _favoritesService = UserFavoritesService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0F),
            Color(0xFF1A0B2E),
            Color(0xFF2D1B4D),
            Color(0xFF1A0B2E),
            Color(0xFF0A0A0F),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const LibraryHeader(),
            Expanded(
              child: _currentUser == null
                  ? const LibraryLoginPrompt()
                  : LibraryContent(
                      userId: _currentUser.uid,
                      favoritesService: _favoritesService,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
