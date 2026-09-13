import 'package:flutter_test/flutter_test.dart';

/// Mirrors the block check that [startGroupCall] runs over every invitee
/// before sending a group invitation:
///
/// ```dart
/// final blockChecks = await Future.wait(
///   invitees.map((peer) => blockService.isBlockedEitherWay(me.uid, peer.id)),
/// );
/// if (blockChecks.any((blocked) => blocked)) { ... }
/// ```
///
/// [BlockService.isBlockedEitherWay] is just a simple Firestore read with
/// nothing worth unit testing on its own, so this test instead checks the
/// rule around it: a group call is blocked if ANY invitee has a blocking
/// relationship with the signed-in user.
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
