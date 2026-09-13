import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/models/call_model.dart';
import 'package:sankar_group/providers/recent_contacts_provider.dart';

CallModel _call({
  required String callerId,
  required String callerName,
  required String receiverId,
  required String receiverName,
  required DateTime startedAt,
}) {
  return CallModel(
    id: 'call_${startedAt.microsecondsSinceEpoch}',
    callerId: callerId,
    callerName: callerName,
    receiverId: receiverId,
    receiverName: receiverName,
    callType: CallType.audio,
    status: CallStatus.ended,
    startedAt: startedAt,
  );
}

void main() {
  const me = 'me-uid';

  group('computeRecentContacts', () {
    test('ranks contacts by call count, most-called first', () {
      final calls = [
        _call(
          callerId: me,
          callerName: 'Me',
          receiverId: 'bob',
          receiverName: 'Bob',
          startedAt: DateTime(2026, 1, 1),
        ),
        _call(
          callerId: 'alice',
          callerName: 'Alice',
          receiverId: me,
          receiverName: 'Me',
          startedAt: DateTime(2026, 1, 2),
        ),
        _call(
          callerId: 'alice',
          callerName: 'Alice',
          receiverId: me,
          receiverName: 'Me',
          startedAt: DateTime(2026, 1, 3),
        ),
      ];

      final result = computeRecentContacts(calls, me, const {});

      expect(result.map((c) => c.userId).toList(), ['alice', 'bob']);
      expect(result.first.callCount, 2);
    });

    test('counts both outgoing and incoming calls to the same person', () {
      final calls = [
        _call(
          callerId: me,
          callerName: 'Me',
          receiverId: 'bob',
          receiverName: 'Bob',
          startedAt: DateTime(2026, 1, 1),
        ),
        _call(
          callerId: 'bob',
          callerName: 'Bob',
          receiverId: me,
          receiverName: 'Me',
          startedAt: DateTime(2026, 1, 2),
        ),
      ];

      final result = computeRecentContacts(calls, me, const {});

      expect(result, hasLength(1));
      expect(result.single.callCount, 2);
    });

    test('excludes blocked contacts', () {
      final calls = [
        _call(
          callerId: me,
          callerName: 'Me',
          receiverId: 'bob',
          receiverName: 'Bob',
          startedAt: DateTime(2026, 1, 1),
        ),
        _call(
          callerId: 'alice',
          callerName: 'Alice',
          receiverId: me,
          receiverName: 'Me',
          startedAt: DateTime(2026, 1, 2),
        ),
      ];

      final result = computeRecentContacts(calls, me, {'alice'});

      expect(result.map((c) => c.userId).toList(), ['bob']);
    });

    test('empty call history yields an empty list, not placeholder data', () {
      final result = computeRecentContacts(const [], me, const {});
      expect(result, isEmpty);
    });

    test('caps the list at maxRecentContacts', () {
      final calls = [
        for (var i = 0; i < 8; i++)
          _call(
            callerId: me,
            callerName: 'Me',
            receiverId: 'user$i',
            receiverName: 'User $i',
            startedAt: DateTime(2026, 1, 1 + i),
          ),
      ];

      final result = computeRecentContacts(calls, me, const {});

      expect(result.length, maxRecentContacts);
    });
  });
}
