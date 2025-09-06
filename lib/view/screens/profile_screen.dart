import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';
import 'package:phonkers/view/widget/profile_screen_widget/favorite_songs_widget.dart';
import 'package:phonkers/view/widget/profile_screen_widget/profile_header_widget.dart';
import 'package:phonkers/view/widget/profile_screen_widget/profile_info_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<String> favoriteSongs = [];
  bool isLoading = true;
  String userType = 'fan';
  String? musicPreference;

  late AnimationController _profileAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _profileFadeAnimation;
  late Animation<Offset> _profileSlideAnimation;
  late Animation<double> _listFadeAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserProfile();
  }

  void _setupAnimations() {
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _profileFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _profileSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _profileAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    try {
      final profile = await authService.value.getUserProfile();

      if (profile != null) {
        setState(() {
          userProfile = profile;
          userType = profile['userType'] as String? ?? 'fan';
          musicPreference = profile['musicPreference'] as String?;
          favoriteSongs = List<String>.from(profile['favoriteSongs'] ?? []);
        });

        _profileAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          _listAnimationController.forward();
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addFavoriteSong() async {
    final TextEditingController songController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.purple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Add Favorite Song',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: songController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Song name',
              labelStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final song = songController.text.trim();
              if (song.isNotEmpty) {
                Navigator.pop(context, song);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        favoriteSongs.add(result);
      });
      await _saveFavoriteSongs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Added "$result" to favorites',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _saveFavoriteSongs() async {
    final user = authService.value.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'favoriteSongs': favoriteSongs,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving favorite songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save favorite songs')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profileImageUrl = userProfile?['profileImageUrl'] as String?;
    final username = userProfile?['username'] as String? ?? '';
    final email = userProfile?['email'] as String? ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0F),
            Color(0xFF1A0B2E),
            Color(0xFF2D1B47),
            Color(0xFF0A0A0F),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.purple,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProfileHeaderWidget(
                      profileFadeAnimation: _profileFadeAnimation,
                      profileSlideAnimation: _profileSlideAnimation,
                    ),

                    const SizedBox(height: 32),

                    ProfileInfoWidget(
                      profileImageUrl: profileImageUrl,
                      username: username,
                      email: email,
                      userType: userType,
                      musicPreference: musicPreference,
                      profileFadeAnimation: _profileFadeAnimation,
                      profileSlideAnimation: _profileSlideAnimation,
                    ),

                    const SizedBox(height: 32),

                    FavoriteSongsWidget(
                      favoriteSongs: favoriteSongs,
                      listFadeAnimation: _listFadeAnimation,
                      onAddSong: _addFavoriteSong,
                      onRemoveSong: (index) async {
                        setState(() {
                          favoriteSongs.removeAt(index);
                        });
                        await _saveFavoriteSongs();
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
