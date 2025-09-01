import 'package:cloud_firestore/cloud_firestore.dart';

class UserFavorite {
  final String userId;
  final String phonkId;
  final DateTime addedAt;

  UserFavorite({
    required this.userId,
    required this.phonkId,
    required this.addedAt,
  });

  factory UserFavorite.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserFavorite(
      userId: data['userId'] ?? '',
      phonkId: data['phonkId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'phonkId': phonkId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
