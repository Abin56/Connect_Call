import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/block_service.dart';
import 'auth_provider.dart';

final blockServiceProvider = Provider<BlockService>((ref) => BlockService());

/// The signed-in user's own blocked-user ids, live. Used to filter that
/// user out of contacts/search rather than hide them entirely (their call
/// history with a blocked user should stay visible).
final blockedIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<String>{});
  return ref.watch(blockServiceProvider).watchBlockedIds(uid);
});

/// Whether the signed-in user has blocked [otherUserId], for a profile
/// screen's Block/Unblock button.
final isBlockedByMeProvider = StreamProvider.family<bool, String>((
  ref,
  otherUserId,
) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(false);
  return ref.watch(blockServiceProvider).watchIsBlocked(uid, otherUserId);
});
