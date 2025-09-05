import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  static Future<String> createPost({
    required String content,
    String? musicTrackId,
    String? imageUrl,
    String? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user profile data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final postData = {
      'id': '',
      'userId': user.uid,
      'username': userData['username'] ?? user.displayName ?? 'Anonymous',
      'userType': userData['userType'] ?? 'fan',
      'avatar': userData['profileImageUrl'] ?? user.photoURL ?? '',
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'likedBy': [],
      'musicTrack': musicTrackId != null
          ? {
              'id': musicTrackId,
              'title': 'Track Title', // TODO: Get from track service
              'artist': 'Artist Name',
              'duration': '3:24',
            }
          : null,
      'imageUrl': imageUrl,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('posts').add(postData);

    // Update the document with its ID
    await docRef.update({'id': docRef.id});

    return docRef.id;
  }

  // Get posts with pagination
  static Future<List<Map<String, dynamic>>> getPosts({
    String? userType,
    String feedType = 'recent',
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query query = _firestore.collection('posts');

    // Filter by user type if specified
    if (userType != null && userType != 'all') {
      query = query.where('userType', isEqualTo: userType);
    }

    // Order by feed type
    switch (feedType) {
      case 'trending':
        query = query.orderBy('likes', descending: true);
        break;
      case 'artists':
        query = query
            .where('userType', isEqualTo: 'artist')
            .orderBy('timestamp', descending: true);
        break;
      default: // recent
        query = query.orderBy('timestamp', descending: true);
    }

    // Add pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['docRef'] = doc; // Store for pagination

      // Convert timestamp to DateTime if it exists
      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'] as Timestamp;
        data['timestamp'] = timestamp.toDate();
      }

      return data;
    }).toList();
  }

  // Like/Unlike a post
  static Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final data = postDoc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikes = data['likes'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike
        likedBy.remove(user.uid);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': currentLikes - 1,
        });
      } else {
        // Like
        likedBy.add(user.uid);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': currentLikes + 1,
        });
      }
    });
  }

  // Check if user has liked a post
  static Future<bool> hasUserLiked(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final postDoc = await _firestore.collection('posts').doc(postId).get();

    if (!postDoc.exists) return false;

    final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
    return likedBy.contains(user.uid);
  }

  // Add comment to a post
  static Future<String> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user profile data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final commentData = {
      'id': '',
      'postId': postId,
      'userId': user.uid,
      'username': userData['username'] ?? user.displayName ?? 'Anonymous',
      'userType': userData['userType'] ?? 'fan',
      'avatar': userData['profileImageUrl'] ?? user.photoURL ?? '',
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
    };

    // Add comment
    final docRef = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(commentData);

    // Update comment with its ID
    await docRef.update({'id': docRef.id});

    // Update post comment count
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Get comments for a post
  static Future<List<Map<String, dynamic>>> getComments({
    required String postId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['docRef'] = doc;

      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'] as Timestamp;
        data['timestamp'] = timestamp.toDate();
      }

      return data;
    }).toList();
  }

  // Get comments count for a post
  static Stream<int> getCommentsCount(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
