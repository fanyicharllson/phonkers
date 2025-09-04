// profile_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phonkers/cloudinary/cloudinary_service.dart';

class ProfileService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data();
      }

      // Fallback to Firebase Auth data
      return {
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'profileImageUrl': user.photoURL,
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile with optional image upload
  static Future<void> updateUserProfile({
    required String username,
    File? imageFile,
    String? existingImageUrl,
    bool removeImage = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user found');

    String? finalImageUrl = existingImageUrl;

    try {
      // Handle image operations
      if (removeImage) {
        finalImageUrl = null;
      } else if (imageFile != null) {
        // Upload new image
        finalImageUrl = await CloudinaryService.uploadImage(imageFile);
        if (finalImageUrl == null) {
          throw Exception('Image upload failed');
        }
      }

      // Update Firebase Auth
      await user.updateDisplayName(username.trim());
      await user.updatePhotoURL(finalImageUrl);
      await user.reload();

      // Update Firestore
      final userData = {
        'username': username.trim(),
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (finalImageUrl != null) {
        userData['profileImageUrl'] = finalImageUrl;
      } else {
        // Remove the field if image is removed
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': FieldValue.delete(),
        });
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Remove profile image
  static Future<void> removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user found');

    try {
      // Update Firebase Auth
      await user.updatePhotoURL(null);
      await user.reload();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing profile image: $e');
      rethrow;
    }
  }
}
