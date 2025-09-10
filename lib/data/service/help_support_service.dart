import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpSupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for feedback
  CollectionReference get _feedbackCollection =>
      _firestore.collection('user_feedback');

  // Save user feedback to Firebase
  Future<void> saveFeedback({
    required String feedback,
    String? category,
  }) async {
    try {
      final user = _auth.currentUser;

      await _feedbackCollection.add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'username': user?.displayName,
        'feedback': feedback,
        'category': category ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });
    } catch (e) {
      throw Exception('Failed to save feedback: $e');
    }
  }

  // Get user's feedback history (optional)
  Stream<QuerySnapshot> getUserFeedbackHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _feedbackCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Admin function to get all feedback (optional)
  Stream<QuerySnapshot> getAllFeedback() {
    return _feedbackCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update feedback status (for admin use)
  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
  }) async {
    try {
      await _feedbackCollection.doc(feedbackId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update feedback status: $e');
    }
  }
}
