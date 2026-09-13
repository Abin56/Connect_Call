import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// The signed-in user's own Firestore profile document.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userServiceProvider).watchUser(uid);
});

/// A single user's profile by id, used for things like showing a blocked user's name.
final userByIdProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return ref.watch(userServiceProvider).getUser(userId);
});

/// All contacts (every other registered user) with live presence.
final contactsProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(<UserModel>[]);
  return ref.watch(userServiceProvider).watchContacts(uid);
});

/// Search text entered on the Contacts screen.
class ContactSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final contactSearchQueryProvider =
    NotifierProvider<ContactSearchQueryNotifier, String>(
      ContactSearchQueryNotifier.new,
    );

/// Contacts filtered by [contactSearchQueryProvider], matching on name or
/// email. Just simple client-side filtering -- plenty for this app's
/// scale, and it avoids setting up a whole search index.
///
/// Contacts the signed-in person has blocked stay in the list instead of
/// being removed, so Contacts can show them greyed out with an Unblock
/// button -- see [UserTile]/`ContactsScreen`. Someone who has blocked
/// *me* still shows up in my list too, since I have no way of knowing
/// I've been blocked -- the call itself is what actually gets stopped,
/// in both directions, when someone tries to call.
final filteredContactsProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final contacts = ref.watch(contactsProvider);
  final query = ref.watch(contactSearchQueryProvider).trim().toLowerCase();

  return contacts.whenData((users) {
    if (query.isEmpty) return users;
    return users.where((u) {
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  });
});
