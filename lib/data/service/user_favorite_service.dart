import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phonkers/data/model/phonk.dart';

class UserFavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'user_favorites';

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
          print(
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
        final docId = '${userId}_$phonkId';
        final doc = await _firestore
            .collection(_collectionName)
            .doc(docId)
            .get();
        return doc.exists;
      });
    } catch (e) {
      print('Error checking favorite status after retries: $e');
      return false; // Default to false if we can't determine the status
    }
  }

  // Add to favorites (with retry logic)
  Future<void> addToFavorites(String userId, Phonk phonk) async {
    try {
      await _retryOperation(() async {
        final docId = '${userId}_${phonk.id}';

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

        await _firestore.collection(_collectionName).doc(docId).set(favorite);
      });
    } catch (e) {
      print('Error adding to favorites after retries: $e');
      rethrow; // Re-throw so the UI can show an error message
    }
  }

  // Remove from favorites (with retry logic)
  Future<void> removeFromFavorites(String userId, String phonkId) async {
    try {
      await _retryOperation(() async {
        final docId = '${userId}_$phonkId';
        await _firestore.collection(_collectionName).doc(docId).delete();
      });
    } catch (e) {
      print('Error removing from favorites after retries: $e');
      rethrow;
    }
  }

  // Toggle favorite status (with retry logic)
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
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Get user's favorite phonks (with retry logic)
  Stream<List<Phonk>> getUserFavorites(String userId) async* {
    try {
      yield* _firestore
          .collection(_collectionName)
          .orderBy(FieldPath.documentId)
          .startAt([userId])
          .endAt(['${userId}_\uf8ff'])
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
                      title: phonkData['title'],
                      artist: phonkData['artist'],
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
                    print('Error parsing favorite: $e');
                    return null;
                  }
                })
                .where((phonk) => phonk != null)
                .cast<Phonk>()
                .toList();
          })
          .handleError((error) {
            print('Stream error in getUserFavorites: $error');
          });
    } catch (e) {
      print('Error setting up favorites stream: $e');
      yield []; // Return empty list on error
    }
  }
}
