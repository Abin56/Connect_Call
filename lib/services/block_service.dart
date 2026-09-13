import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Firestore operations for user blocking.
///
/// Stored as `users/{userId}/blocked/{blockedUserId}`, a subcollection
/// rather than a top-level `blocked_users` collection -- keeps "does A
/// block B" a single doc read, and lets Firestore rules restrict writes to
/// `request.auth.uid == userId`.
///
/// Blocking is one-directional data, but the call-prevention rule isn't:
/// [isBlockedEitherWay] checks both directions.
class BlockService {
  final FirebaseFirestore _firestore;

  BlockService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('blocked');

  Future<void> blockUser(String userId, String blockedUserId) {
    return _blockedCollection(
      userId,
    ).doc(blockedUserId).set({'blockedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser(String userId, String blockedUserId) {
    return _blockedCollection(userId).doc(blockedUserId).delete();
  }

  /// Live "did [userId] block [otherUserId]" flag, for the block/unblock button.
  Stream<bool> watchIsBlocked(String userId, String otherUserId) {
    return _blockedCollection(
      userId,
    ).doc(otherUserId).snapshots().map((doc) => doc.exists);
  }

  /// All user ids [userId] has blocked, for filtering contacts/search.
  Stream<Set<String>> watchBlockedIds(String userId) {
    return _blockedCollection(
      userId,
    ).snapshots().map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
  }

  /// True if either user has blocked the other -- the actual call-gating check.
  Future<bool> isBlockedEitherWay(String userIdA, String userIdB) async {
    final results = await Future.wait([
      _blockedCollection(userIdA).doc(userIdB).get(),
      _blockedCollection(userIdB).doc(userIdA).get(),
    ]);
    return results.any((doc) => doc.exists);
  }
}
