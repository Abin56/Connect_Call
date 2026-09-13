import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Firestore reads and writes for user profiles, the contacts list, and presence.
class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Stream<UserModel?> watchUser(String userId) {
    return _users
        .doc(userId)
        .snapshots()
        .map(
          (doc) => doc.exists ? UserModel.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// All other users, ordered by name. [currentUserId] is filtered out
  /// on the client since the contact list is small enough that we don't
  /// need pagination.
  Stream<List<UserModel>> watchContacts(String currentUserId) {
    return _users
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> setOnlineStatus(String userId, bool isOnline) {
    return _users.doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(
    String userId, {
    String? name,
    String? profileImage,
  }) {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profileImage != null) updates['profileImage'] = profileImage;
    if (updates.isEmpty) return Future.value();
    return _users.doc(userId).update(updates);
  }
}
