import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save or update user data in Firestore
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Prepare the data to save
      final dataToSave = {
        ...userData,
        'userId': user.uid,
        'email': user.email,
        'username': user.displayName ?? 'Anonymous',
        'profileImageUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore using the user's UID as document ID
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(dataToSave, SetOptions(merge: true));

      debugPrint('User data saved successfully');
    } catch (e) {
      debugPrint('Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Update specific user field
  static Future<void> updateUserField(String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user field: $e');
      throw Exception('Failed to update user field: $e');
    }
  }

  /// Check if user profile is complete
  static Future<bool> isProfileComplete() async {
    final userData = await getUserData();

    if (userData == null) return false;

    // Check if required fields are present
    return userData.containsKey('musicPreference') &&
        userData.containsKey('userType');
  }

  /// Get user type (with fallback to 'fan' if not set)
  static Future<String> getUserType() async {
    final userData = await getUserData();
    return userData?['userType'] ?? 'fan';
  }

  /// Get music preference
  static Future<String?> getMusicPreference() async {
    final userData = await getUserData();
    return userData?['musicPreference'];
  }


  //delete use data
  static Future<void> deleteUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();

      // Delete user document
      final userDocRef = _firestore.collection('users').doc(user.uid);
      batch.delete(userDocRef);

      // Delete user's posts (if any)
      final userPosts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in userPosts.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's likes/interactions (if you track them separately)
      final userLikes = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in userLikes.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's comments (if you have a separate comments collection)
      final userComments = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in userComments.docs) {
        batch.delete(doc.reference);
      }

      // Execute all deletions as a batch
      await batch.commit();

      print('User data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Delete only user profile data (lighter version)
  static Future<void> deleteUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      print('User profile deleted successfully');
    } catch (e) {
      print('Error deleting user profile: $e');
      throw Exception('Failed to delete user profile: $e');
    }
  }

  /// Clean up user references in posts (anonymize instead of delete)
  static Future<void> anonymizeUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();

      // Delete user document
      final userDocRef = _firestore.collection('users').doc(user.uid);
      batch.delete(userDocRef);

      // Anonymize user's posts instead of deleting them
      final userPosts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in userPosts.docs) {
        batch.update(doc.reference, {
          'username': 'Deleted User',
          'avatar': '',
          'userType': 'fan',
          'userId': 'deleted_user',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('User data anonymized successfully');
    } catch (e) {
      print('Error anonymizing user data: $e');
      throw Exception('Failed to anonymize user data: $e');
    }
  }
}
