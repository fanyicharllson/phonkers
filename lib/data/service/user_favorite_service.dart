import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';

class UserFavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _favoritesSubcollection = 'favorites';

  // Helper method for retry logic
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        attempts++;

        if (e.code == 'unavailable' && attempts < maxRetries) {
          debugPrint(
            'Firebase unavailable, retrying in ${delay.inMilliseconds}ms... (attempt $attempts)',
          );
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * 1.5).round(),
          ); // Exponential backoff
          continue;
        }

        // If it's not an 'unavailable' error or we've exceeded retries, rethrow
        rethrow;
      } catch (e) {
        // For non-Firebase exceptions, don't retry
        rethrow;
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Check if phonk is favorited by user (with retry logic)
  Future<bool> isFavorited(String userId, String phonkId) async {
    try {
      return await _retryOperation(() async {
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_favoritesSubcollection)
            .doc(phonkId)
            .get();
        return doc.exists;
      });
    } catch (e) {
      debugPrint('Error checking favorite status after retries: $e');
      return false; // Default to false if we can't determine the status
    }
  }

  // Add to favorites (with retry logic)
  Future<void> addToFavorites(String userId, Phonk phonk) async {
    try {
      await _retryOperation(() async {
        final favorite = {
          'userId': userId,
          'phonkId': phonk.id,
          'addedAt': FieldValue.serverTimestamp(),
          'phonkData': {
            'title': phonk.title,
            'artist': phonk.artist,
            'albumArt': phonk.albumArt,
            'previewUrl': phonk.previewUrl,
            'spotifyUrl': phonk.spotifyUrl,
            'youtubeUrl': phonk.youtubeUrl,
            'duration': phonk.duration,
            'hasPreview': phonk.hasPreview,
            'albumName': phonk.albumName,
          },
        };

        await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_favoritesSubcollection)
            .doc(phonk.id)
            .set(favorite);
      });
    } catch (e) {
      debugPrint('Error adding to favorites after retries: $e');
      rethrow; // Re-throw so the UI can show an error message
    }
  }

  // Remove from favorites (with retry logic)
  Future<void> removeFromFavorites(String userId, String phonkId) async {
    try {
      await _retryOperation(() async {
        await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_favoritesSubcollection)
            .doc(phonkId)
            .delete();
      });
    } catch (e) {
      debugPrint('Error removing from favorites after retries: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(
    String userId,
    String phonkId,
    Phonk phonk,
  ) async {
    try {
      final isFav = await isFavorited(userId, phonkId);

      if (isFav) {
        await removeFromFavorites(userId, phonkId);
        return false;
      } else {
        await addToFavorites(userId, phonk);
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Get user's favorite phonks (with retry logic)
  Stream<List<Phonk>> getUserFavorites(String userId) async* {
    try {
      yield* _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubcollection)
          .orderBy('addedAt', descending: true) // Most recent first
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    final phonkData =
                        data['phonkData'] as Map<String, dynamic>?;

                    if (phonkData == null) {
                      // Handle old format without phonkData
                      return Phonk(
                        id: data['phonkId'] ?? '',
                        title: 'Unknown Title',
                        artist: 'Unknown Artist',
                        albumArt: null,
                        previewUrl: null,
                        spotifyUrl: null,
                        youtubeUrl: null,
                        duration: 0,
                        hasPreview: false,
                        plays: 0,
                        uploadDate: DateTime.now(),
                        isNew: false,
                        genre: 'phonk',
                        source: 'unknown',
                        albumName: null,
                      );
                    }

                    return Phonk(
                      id: data['phonkId'],
                      title: phonkData['title'] ?? 'Unknown Title',
                      artist: phonkData['artist'] ?? 'Unknown Artist',
                      albumArt: phonkData['albumArt'],
                      previewUrl: phonkData['previewUrl'],
                      spotifyUrl: phonkData['spotifyUrl'],
                      youtubeUrl: phonkData['youtubeUrl'],
                      duration: phonkData['duration'] ?? 0,
                      hasPreview: phonkData['hasPreview'] ?? false,
                      plays: 0,
                      uploadDate: DateTime.now(),
                      isNew: false,
                      genre: 'phonk',
                      source: 'spotify',
                      albumName: phonkData['albumName'],
                    );
                  } catch (e) {
                    debugPrint('Error parsing favorite: $e');
                    return null;
                  }
                })
                .where((phonk) => phonk != null)
                .cast<Phonk>()
                .toList();
          })
          .handleError((error) {
            debugPrint('Stream error in getUserFavorites: $error');
          });
    } catch (e) {
      debugPrint('Error setting up favorites stream: $e');
      yield []; // Return empty list on error
    }
  }

  // Get favorites count for a user
  Future<int> getFavoritesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubcollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting favorites count: $e');
      return 0;
    }
  }

  // Get paginated favorites (for large lists)
  Future<List<Phonk>> getPaginatedFavorites(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubcollection)
          .orderBy('addedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final phonkData = data['phonkData'] as Map<String, dynamic>?;

              if (phonkData == null) {
                return null;
              }

              return Phonk(
                id: data['phonkId'],
                title: phonkData['title'] ?? 'Unknown Title',
                artist: phonkData['artist'] ?? 'Unknown Artist',
                albumArt: phonkData['albumArt'],
                previewUrl: phonkData['previewUrl'],
                spotifyUrl: phonkData['spotifyUrl'],
                youtubeUrl: phonkData['youtubeUrl'],
                duration: phonkData['duration'] ?? 0,
                hasPreview: phonkData['hasPreview'] ?? false,
                plays: 0,
                uploadDate: DateTime.now(),
                isNew: false,
                genre: 'phonk',
                source: 'spotify',
                albumName: phonkData['albumName'],
              );
            } catch (e) {
              debugPrint('Error parsing paginated favorite: $e');
              return null;
            }
          })
          .where((phonk) => phonk != null)
          .cast<Phonk>()
          .toList();
    } catch (e) {
      debugPrint('Error getting paginated favorites: $e');
      return [];
    }
  }
}
