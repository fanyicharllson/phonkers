import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendEmailVerification() async {
  try {
    await currentUser?.sendEmailVerification();
  } catch (e) {
    rethrow;
  }
}

  Future<bool> isEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPasword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}

// Extended AuthService with profile management
extension ProfileManagement on AuthService {
  Future<void> updateUserProfile({
    required String username,
    String? profileImageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user found');

    // Update Firebase Auth
    await user.updateDisplayName(username);
    if (profileImageUrl != null) {
      await user.updatePhotoURL(profileImageUrl);
    }
    await user.reload();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'username': username,
      'email': user.email,
      'profileImageUrl': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

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

  Future<void> removeProfileImage() async {
    final user = currentUser;
    if (user == null) throw Exception('No user found');

    // Update Firebase Auth
    await user.updatePhotoURL(null);
    await user.reload();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
