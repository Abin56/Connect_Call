import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

/// Tracks who's selected in the "New Group Call" flow (the Select
/// Contacts screen). Kept as its own small provider instead of folded
/// into [contactSearchQueryProvider]/[filteredContactsProvider], so
/// group-call selection doesn't touch normal 1-to-1 contact search/browsing.
class GroupCallSelectionNotifier extends Notifier<List<UserModel>> {
  @override
  List<UserModel> build() => const [];

  void toggle(UserModel user) {
    final alreadySelected = state.any((u) => u.id == user.id);
    state = alreadySelected
        ? state.where((u) => u.id != user.id).toList()
        : [...state, user];
  }

  void remove(String userId) {
    state = state.where((u) => u.id != userId).toList();
  }

  void clear() => state = const [];
}

final groupCallSelectionProvider =
    NotifierProvider<GroupCallSelectionNotifier, List<UserModel>>(
      GroupCallSelectionNotifier.new,
    );

/// The minimum number of invitees to start a group call. The initiator
/// counts as a participant too, so 2 invitees means a 3-person call.
const minGroupCallInvitees = 2;
