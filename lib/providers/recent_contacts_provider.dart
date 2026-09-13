import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_model.dart';
import 'auth_provider.dart';
import 'block_provider.dart';
import 'call_history_provider.dart';

/// One entry in the Frequently Called list: who the other person is, how
/// many calls they've had together, and the most recent call between
/// them (for a "last contacted" hint).
class RecentContact {
  final String userId;
  final String name;
  final int callCount;
  final DateTime lastCallAt;

  const RecentContact({
    required this.userId,
    required this.name,
    required this.callCount,
    required this.lastCallAt,
  });
}

const maxRecentContacts = 5;

/// Works out the top [maxRecentContacts] most-called people from [calls],
/// breaking ties by most recent call, and leaving out anyone in
/// [blockedIds]. Written as a plain function instead of being inlined in
/// the provider below, so it's easy to unit test against a hand-built
/// list of calls without having to fake `authStateProvider`.
List<RecentContact> computeRecentContacts(
  List<CallModel> calls,
  String uid,
  Set<String> blockedIds,
) {
  final byOtherParty = <String, ({String name, int count, DateTime last})>{};
  for (final call in calls) {
    final isOutgoing = call.isOutgoingFor(uid);
    final otherId = isOutgoing ? call.receiverId : call.callerId;
    final otherName = isOutgoing ? call.receiverName : call.callerName;
    if (blockedIds.contains(otherId)) continue;

    final existing = byOtherParty[otherId];
    if (existing == null) {
      byOtherParty[otherId] = (name: otherName, count: 1, last: call.startedAt);
    } else {
      byOtherParty[otherId] = (
        name: existing.name,
        count: existing.count + 1,
        last: call.startedAt.isAfter(existing.last)
            ? call.startedAt
            : existing.last,
      );
    }
  }

  final contacts =
      byOtherParty.entries
          .map(
            (entry) => RecentContact(
              userId: entry.key,
              name: entry.value.name,
              callCount: entry.value.count,
              lastCallAt: entry.value.last,
            ),
          )
          .toList()
        ..sort((a, b) {
          final byCount = b.callCount.compareTo(a.callCount);
          if (byCount != 0) return byCount;
          return b.lastCallAt.compareTo(a.lastCallAt);
        });

  return contacts.take(maxRecentContacts).toList();
}

/// The signed-in user's most-called contacts, worked out entirely from
/// the existing call history stream -- no separate collection or extra
/// Firestore reads needed. Blocked users are left out either way since
/// they can't be called anyway; deleted or unknown users still show up
/// by id (call history itself is untouched), just falling back to
/// "Unknown user" if the profile lookup comes back empty.
final recentContactsProvider = Provider<AsyncValue<List<RecentContact>>>((ref) {
  final history = ref.watch(callHistoryProvider);
  final blockedIds = ref.watch(blockedIdsProvider).value ?? const <String>{};
  final uid = ref.watch(authStateProvider).value?.uid;

  return history.whenData((calls) {
    if (uid == null) return const <RecentContact>[];
    return computeRecentContacts(calls, uid, blockedIds);
  });
});
