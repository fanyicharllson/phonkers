import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/search_widgets/recent_search_widget.dart';
import 'package:phonkers/view/widget/search_widgets/search_bar_widget.dart';
import 'package:phonkers/view/widget/search_widgets/search_button_widget.dart';
import 'package:phonkers/view/widget/search_widgets/search_result_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phonkers/data/service/youtube_api_service.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/data/model/phonk.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin, NetworkAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  String _error = '';
  bool _isNetworkError = false;

  // Remove complex state tracking variables
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRecentSearches();
    _autoFocusSearch();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _autoFocusSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = List<String>.from(_recentSearches);

      // Remove if already exists (to move to top)
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only last 10 searches
      if (searches.length > 10) {
        searches.removeRange(10, searches.length);
      }

      await prefs.setStringList('recent_searches', searches);
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> performSearch([String? queryOverride]) async {
    final query = queryOverride ?? _searchController.text.trim();
    if (query.isEmpty) return;

    // Update search controller if using override (from recent searches)
    if (queryOverride != null) {
      _searchController.text = query;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _currentQuery = query;
      _error = '';
      _isNetworkError = false;
    });

    HapticFeedback.lightImpact();

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _error = 'No internet connection';
          _isNetworkError = true;
          _isSearching = false;
          _hasSearched = false;
        });
      }
      return;
    }

    try {
      final (artist, title) = _parseSearchQuery(query);

      final results = await YouTubeApiService.smartSearch(
        artist: artist,
        title: title,
        maxResults: 10,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;
        });

        // Save to recent searches
        await _saveRecentSearch(query);

        _showResultsSnackBar(results.length);
      }
    } catch (e) {
      if (mounted) {
        final hasInternet = await hasInternetConnection();
        setState(() {
          _error = hasInternet
              ? 'Failed to load trending phonks'
              : 'No internet connection';
          _isNetworkError = !hasInternet;
          _searchResults = [];
          _isSearching = false;
          _hasSearched = true;
        });

        _showErrorSnackBar(e.toString());
      }
    }
  }

  (String, String) _parseSearchQuery(String query) {
    final parts = query.split(' - ');

    if (parts.length >= 2) {
      return (parts[0].trim(), parts.sublist(1).join(' - ').trim());
    } else {
      final words = query.split(' ');
      if (words.length >= 2) {
        return (words[0], words.sublist(1).join(' '));
      } else {
        return (query, query);
      }
    }
  }

  void _showResultsSnackBar(int resultCount) {
    if (resultCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found $resultCount results',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple.withValues(alpha: 0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Search failed: $error',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> playTrack(Map<String, dynamic> track) async {
    HapticFeedback.mediumImpact();

    final videoId = track['id']?['videoId'] ?? track['id'];
    final title = track['snippet']?['title'] ?? 'Unknown';
    final channelTitle = track['snippet']?['channelTitle'] ?? 'Unknown';

    if (track['isFallback'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Redirecting to YouTube...'),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
        ),
      );
      return;
    }

    try {
      final tempPhonk = Phonk(
        id: videoId,
        title: title,
        artist: channelTitle,
        albumName: 'YouTube Search',
        uploadDate: DateTime.now(),
        duration: 30,
        plays: 0,
        previewUrl: null,
        spotifyUrl: null,
        // imageUrl: track['snippet']?['thumbnails']?['medium']?['url'],
      );

      final result = await AudioPlayerService.playPhonk(tempPhonk);

      if (result == PlayResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Playing: $title')),
                ],
              ),
              backgroundColor: Colors.green.withValues(alpha: 0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (result == PlayResult.noPreview) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No audio preview available for this track'),
              backgroundColor: Colors.orange.withValues(alpha: 0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to play track');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play: ${e.toString()}'),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  void clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _currentQuery = '';
    });
    AudioPlayerService.stop();
  }

  void showQuotaDialog() {
    final quotaInfo = YouTubeApiService.getQuotaInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: const Text('API Usage', style: TextStyle(color: Colors.white)),
        content: Text(
          'Quota used today: ${quotaInfo['used']}/${quotaInfo['limit']}\n'
          'Percentage: ${quotaInfo['percentage']}%',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0F), Color(0xFF1A0B2E), Color(0xFF0A0A0F)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Search Phonk Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                onPressed: showQuotaDialog,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            SearchBarWidget(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSearch: performSearch,
              onClear: clearSearch,
              slideAnimation: _slideAnimation,
              fadeAnimation: _fadeAnimation,
            ),
            const SizedBox(height: 16),
            SearchButtonWidget(
              isSearching: _isSearching,
              onPressed: performSearch,
              fadeAnimation: _fadeAnimation,
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_error.isNotEmpty || _isNetworkError) {
      return buildNoInternetError(onRetry: performSearch, message: _error);
    } else if (_hasSearched) {
      return SearchResultsWidget(
        searchResults: _searchResults,
        hasSearched: _hasSearched,
        currentQuery: _currentQuery,
        onPlayTrack: playTrack,
        fadeAnimation: _fadeAnimation,
        // isTrackCurrentlyPlaying: isTrackCurrentlyPlaying,
      );
    } else if (_recentSearches.isNotEmpty) {
      return RecentSearchesWidget(
        recentSearches: _recentSearches,
        onSearchTap: performSearch,
        onClearAll: _clearRecentSearches,
        fadeAnimation: _fadeAnimation,
      );
    } else {
      return _buildWelcomeState();
    }
  }

  Widget _buildWelcomeState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 80,
                color: Colors.purple.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 20),
              Text(
                'Discover Music',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Search for your favorite phonk tracks\nand play them instantly',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Try: "ICEDMANE - FUNK CRIMINAL"',
                  style: TextStyle(
                    color: Colors.purple.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
