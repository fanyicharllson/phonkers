import 'package:flutter/material.dart';
import 'post_card.dart';

class CommunityFeed extends StatefulWidget {
  final String userType;
  final String feedType;

  const CommunityFeed({
    super.key,
    required this.userType,
    required this.feedType,
  });

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CommunityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userType != widget.userType) {
      _loadPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Replace with Firebase call
      await Future.delayed(const Duration(milliseconds: 800));

      final newPosts = _generateMockPosts();
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(newPosts);
          _isLoading = false;
          _hasMore = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Replace with Firebase pagination
      await Future.delayed(const Duration(milliseconds: 500));

      final newPosts = _generateMockPosts();
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _isLoading = false;
          if (_posts.length > 30) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _generateMockPosts() {
    final userTypes = ['artist', 'producer', 'fan', 'dj', 'collector'];

    return List.generate(8, (index) {
      final randomIndex = DateTime.now().millisecond % userTypes.length;
      final userType = userTypes[randomIndex];

      return {
        'id': '${DateTime.now().millisecondsSinceEpoch}_$index',
        'userId': 'user_${index + 1}',
        'username': _getMockUsername(userType, index),
        'userType': userType,
        'avatar': 'https://i.pravatar.cc/150?img=${(index % 50) + 1}',
        'content': _getMockContent(userType),
        'timestamp': DateTime.now().subtract(Duration(minutes: index * 15)),
        'likes': (index * 8) + 3,
        'comments': (index * 2) + 1,
        'shares': index + 1,
        'musicTrack': index % 3 == 0
            ? {
                'title': 'Dark Phonk Beat ${index + 1}',
                'artist': 'PhonkMaster',
                'duration': '${2 + (index % 3)}:${20 + (index * 7 % 40)}',
                'waveform': List.generate(15, (i) => (i % 4) * 0.25 + 0.2),
              }
            : null,
        'hasImage': index % 5 == 0,
      };
    });
  }

  String _getMockUsername(String userType, int index) {
    final usernames = {
      'artist': ['PhonkKing', 'DarkBeats', 'ShadowMusic', 'PhonkVibes'],
      'producer': ['BeatMaker', 'StudioPro', 'SoundWave', 'MixMaster'],
      'dj': ['DJ_Phonk', 'SpinMaster', 'NightVibes', 'ClubKing'],
      'collector': ['VinylHunter', 'MusicLover', 'RareTracks', 'SoundSeeker'],
      'fan': ['PhonkFan', 'MusicAddict', 'BeatLover', 'SoundFreak'],
    };

    final names = usernames[userType] ?? usernames['fan']!;
    return '${names[index % names.length]}${index + 1}';
  }

  String _getMockContent(String userType) {
    final contents = {
      'artist': [
        'Just dropped my latest dark phonk track! 🔥',
        'Working on some new beats tonight 🎵',
        'Thanks for all the support! 🙏',
        'New music video coming soon 🎬',
      ],
      'producer': [
        'Experimenting with new 808 patterns 🥁',
        'Found some crazy vocal samples today',
        'This beat is hitting different 💀',
        'Studio session was incredible tonight',
      ],
      'dj': [
        'Tonight\'s set is going to be FIRE 🔥',
        'Love the energy at phonk events!',
        'Underground scene is alive and well',
        'Mixing some exclusive tracks tonight',
      ],
      'collector': [
        'Found rare phonk vinyl today!',
        'My collection just hit 500 tracks 🎯',
        'Sharing some hidden gems',
        'Digital vs vinyl - what\'s your choice?',
      ],
      'fan': [
        'This track gives me chills 🖤',
        'Phonk music is life!',
        'Can\'t stop this playlist',
        'Discovered amazing new artist today',
      ],
    };

    final userContents = contents[userType] ?? contents['fan']!;
    final randomIndex = DateTime.now().microsecond % userContents.length;
    return userContents[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _posts.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9F7AEA)),
          ),
        ),
      );
    }

    if (_posts.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      backgroundColor: const Color(0xFF1A0B2E),
      color: const Color(0xFF9F7AEA),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _posts.length + (_isLoading && _posts.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF9F7AEA),
                    ),
                  ),
                ),
              ),
            );
          }

          final post = _posts[index];
          return PostCard(post: post);
        },
      ),
    );
  }
}
