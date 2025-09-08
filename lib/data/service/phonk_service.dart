import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/spotify_api_service.dart';
import 'package:phonkers/data/service/youtube_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhonkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'user_favorites';
  final String _playsCollectionName = 'track_plays';

  // Get trending phonks from Spotify
  Future<List<Phonk>> getTrendingPhonks({int limit = 10}) async {
    try {
      List<Phonk> allPhonks = [];

      // 1. Load recent searches
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = prefs.getStringList('recent_searches') ?? [];

      debugPrint("Recent search: $recentSearches --debugPrint");

      // 2. Build queries
      final queries = recentSearches.isNotEmpty
          ? recentSearches.take(3).map((q) => "$q phonk").toList()
          : ["phonk trending", "drift phonk", "dark phonk", "phonk", "funk"];

      // 3. Use YouTube as the primary source
      for (String query in queries) {
        final youtubeResults = await YouTubeApiService.searchVideos(
          query: query,
          maxResults: 8,
        );

        debugPrint(
          "YouTube results for '$query': ${youtubeResults.map((v) => v['snippet']?['title']).toList()}",
        );

        for (final video in youtubeResults) {
          if (video['id']?['videoId'] != null) {
            allPhonks.add(Phonk.fromYouTube(video));
          }
        }

        if (allPhonks.length >= limit) break;
      }

      // 4. Deduplicate (by title/artist)
      final seen = <String>{};
      allPhonks = allPhonks.where((p) {
        final key = "${p.title}-${p.artist}".toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();

      // 5. Shuffle
      allPhonks.shuffle();
      debugPrint(
        "Trending phonks (YouTube-first): ${allPhonks.map((p) => p.title).toList()} --debugPrint",
      );
      return allPhonks.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching YouTube trending phonks: $e');
      return [];
    }
  }

  // Get new/recent phonks from Spotify
  Future<List<Phonk>> getNewPhonks({int limit = 10}) async {
    try {
      final spotifyTracks = await SpotifyApiService.searchPhonkTracks(
        query: 'phonk new',
        limit: limit,
      );

      return spotifyTracks
          .map((track) => Phonk.fromSpotify(track))
          .where((phonk) => phonk.hasPreview)
          .toList();
    } catch (e) {
      debugPrint('Error fetching new phonks: $e');
      return [];
    }
  }

  // Search phonks on Spotify
  Future<List<Phonk>> searchPhonks(String query) async {
    try {
      final spotifyTracks = await SpotifyApiService.searchPhonkTracks(
        query: '$query phonk',
        limit: 20,
      );

      return spotifyTracks.map((track) => Phonk.fromSpotify(track)).toList();
    } catch (e) {
      debugPrint('Error searching phonks: $e');
      return [];
    }
  }

  // Get phonk by Spotify ID
  Future<Phonk?> getPhonkById(String spotifyId) async {
    try {
      final trackData = await SpotifyApiService.getTrackDetails(spotifyId);
      if (trackData != null) {
        return Phonk.fromSpotify(trackData);
      }
    } catch (e) {
      debugPrint('Error getting phonk by ID: $e');
    }
    return null;
  }

  // Save phonk to user favorites
  Future<void> addToFavorites(String userId, Phonk phonk) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('tracks')
          .doc(phonk.id)
          .set(phonk.toFirestore());
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String phonkId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('tracks')
          .doc(phonkId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
    }
  }

  // Get user's favorite phonks
  Stream<List<Phonk>> getUserFavorites(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .collection('tracks')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Phonk.fromFirestore(doc)).toList(),
        );
  }

  // Check if phonk is in favorites
  Future<bool> isFavorite(String userId, String phonkId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .collection('tracks')
          .doc(phonkId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  // Update play count (store in Firebase for tracking)
  Future<void> incrementPlayCount(String phonkId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated, skipping play count increment');
        return;
      }

      final docRef = _firestore
          .collection(_playsCollectionName)
          .doc('${user.uid}_$phonkId');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final currentCount = snapshot.data()?['count'] ?? 0;
          transaction.update(docRef, {
            'count': currentCount + 1,
            'lastPlayed': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'userId': user.uid,
            'phonkId': phonkId,
            'count': 1,
            'firstPlayed': FieldValue.serverTimestamp(),
            'lastPlayed': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error incrementing play count (non-critical): $e');
      // Don't throw the error - this is non-critical functionality
    }
  }

  // Get phonks by different categories
  // Future<List<Phonk>> getPhonksByCategory(
  //   String category, {
  //   int limit = 10,
  // }) async {
  //   try {
  //     String query;
  //     switch (category.toLowerCase()) {
  //       case 'drift':
  //         query = 'drift phonk';
  //         break;
  //       case 'dark':
  //         query = 'dark phonk';
  //         break;
  //       case 'house':
  //         query = 'house phonk';
  //         break;
  //       case 'aggressive':
  //         query = 'aggressive phonk';
  //         break;
  //       default:
  //         query = 'phonk $category';
  //     }

  //     final spotifyTracks = await SpotifyApiService.searchPhonkTracks(
  //       query: query,
  //       limit: limit,
  //     );

  //     return spotifyTracks
  //         .map((track) => Phonk.fromSpotify(track))
  //         .where((phonk) => phonk.hasPreview)
  //         .toList();
  //   } catch (e) {
  //     debugPrint('Error fetching phonks by category: $e');
  //     return [];
  //   }
  // }

  // Get random phonks for discover section
  // Future<List<Phonk>> getRandomPhonks({int limit = 5}) async {
  //   try {
  //     final queries = [
  //       'phonk mix',
  //       'drift phonk',
  //       'dark phonk',
  //       'phonk beats',
  //       'brazilian phonk',
  //     ];

  //     final randomQuery = queries[DateTime.now().millisecond % queries.length];

  //     final spotifyTracks = await SpotifyApiService.searchPhonkTracks(
  //       query: randomQuery,
  //       limit: limit,
  //     );

  //     final phonks = spotifyTracks
  //         .map((track) => Phonk.fromSpotify(track))
  //         .where((phonk) => phonk.hasPreview)
  //         .toList();

  //     phonks.shuffle();
  //     return phonks.take(limit).toList();
  //   } catch (e) {
  //     debugPrint('Error fetching random phonks: $e');
  //     return [];
  //   }
  // }
}
