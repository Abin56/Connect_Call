import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

/// Selected-contacts state for the "New Group Call" flow (Select Contacts
/// screen). Kept as its own small provider rather than folded into
/// [contactSearchQueryProvider]/[filteredContactsProvider] so 1-to-1 contact
/// search/browsing is untouched by group-call selection.
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

/// Minimum invitees required to start a group call (the initiator makes a
/// third participant, so 2 invitees = a 3-person call).
const minGroupCallInvitees = 2;
