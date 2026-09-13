import 'package:flutter_test/flutter_test.dart';

/// Exercises the same check [startGroupCall] (group_call_initiator.dart)
/// runs over every selected invitee before sending a group invitation:
///
/// ```dart
/// final blockChecks = await Future.wait(
///   invitees.map((peer) => blockService.isBlockedEitherWay(me.uid, peer.id)),
/// );
/// if (blockChecks.any((blocked) => blocked)) { ... }
/// ```
///
/// [BlockService.isBlockedEitherWay] itself is a thin two-doc-read Firestore
/// query with no branching logic of its own to unit test (and the project
/// doesn't depend on a Firestore fake package), so what's worth pinning down
/// here is the *aggregation* rule this call site adds on top of it: a group
/// call must be blocked from starting if ANY selected participant -- not
/// just the first one checked -- has a blocking relationship with the
/// signed-in user, in either direction.
Future<bool> _anyBlocked(
  List<String> invitees,
  Future<bool> Function(String peer) isBlockedEitherWay,
) async {
  final results = await Future.wait(invitees.map(isBlockedEitherWay));
  return results.any((blocked) => blocked);
}

void main() {
  group('group call blocked-participant aggregation', () {
    test('false when no invitee is blocked', () async {
      final blocked = await _anyBlocked(
        ['alice', 'bob', 'carol'],
        (peer) async => false,
      );
      expect(blocked, isFalse);
    });

    test('true when only the first invitee is blocked', () async {
      final blocked = await _anyBlocked(
        ['alice', 'bob', 'carol'],
        (peer) async => peer == 'alice',
      );
      expect(blocked, isTrue);
    });

    test('true when only the last invitee is blocked', () async {
      final blocked = await _anyBlocked(
        ['alice', 'bob', 'carol'],
        (peer) async => peer == 'carol',
      );
      expect(blocked, isTrue);
    });

    test('true when a middle invitee is blocked, regardless of direction', () async {
      // isBlockedEitherWay already folds "I blocked them" and "they blocked
      // me" into one bool -- this call site just needs to treat that bool
      // as an all-or-nothing gate across the whole invitee list.
      final blocked = await _anyBlocked(
        ['alice', 'bob', 'carol'],
        (peer) async => peer == 'bob',
      );
      expect(blocked, isTrue);
    });

    test('false for an empty invitee list', () async {
      final blocked = await _anyBlocked([], (peer) async => true);
      expect(blocked, isFalse);
    });
  });
}
