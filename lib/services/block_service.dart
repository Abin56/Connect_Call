import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Firestore reads and writes for blocking users.
///
/// Stored as `users/{userId}/blocked/{blockedUserId}`, a subcollection
/// rather than a top-level `blocked_users` collection -- that way "does A
/// block B" is a single doc read, and Firestore rules can simply restrict
/// writes to `request.auth.uid == userId`.
///
/// Blocking itself only goes one way, but the rule for stopping calls
/// doesn't: [isBlockedEitherWay] checks both directions.
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

  /// Live "did [userId] block [otherUserId]" flag, used for the block/unblock button.
  Stream<bool> watchIsBlocked(String userId, String otherUserId) {
    return _blockedCollection(
      userId,
    ).doc(otherUserId).snapshots().map((doc) => doc.exists);
  }

  /// All user ids [userId] has blocked, used to filter contacts and search.
  Stream<Set<String>> watchBlockedIds(String userId) {
    return _blockedCollection(
      userId,
    ).snapshots().map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
  }

  /// True if either user has blocked the other -- this is the actual
  /// check used to decide if a call is allowed.
  Future<bool> isBlockedEitherWay(String userIdA, String userIdB) async {
    final results = await Future.wait([
      _blockedCollection(userIdA).doc(userIdB).get(),
      _blockedCollection(userIdB).doc(userIdA).get(),
    ]);
    return results.any((doc) => doc.exists);
  }
}
