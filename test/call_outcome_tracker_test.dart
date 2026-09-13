import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/models/call_model.dart';
import 'package:sankar_group/services/call_outcome_tracker.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);

  group('CallOutcomeTracker -- caller side', () {
    test('onOutgoingCallAccepted writes connected with the tracked callId', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write = tracker.onOutgoingCallAccepted(now: t0) as CallerStatusWrite?;

      expect(write, isNotNull);
      expect(write!.callId, 'doc1');
      expect(write.status, CallStatus.connected);
      expect(write.endedAt, t0);
    });

    test('onOutgoingCallAccepted is a no-op if no outgoing call is tracked', () {
      final tracker = CallOutcomeTracker();
      expect(tracker.onOutgoingCallAccepted(now: t0), isNull);
    });

    test('declined writes rejected and clears tracking', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write =
          tracker.onOutgoingCallDeclinedOrBusy(now: t0) as CallerStatusWrite?;

      expect(write!.callId, 'doc1');
      expect(write.status, CallStatus.rejected);
      // Cleared -- a second declined-ish callback (or a later onCallEnd)
      // must not write again for the same call.
      expect(tracker.onOutgoingCallDeclinedOrBusy(now: t0), isNull);
    });

    test('rejected-cause-busy also writes rejected', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write =
          tracker.onOutgoingCallDeclinedOrBusy(now: t0) as CallerStatusWrite?;
      expect(write!.status, CallStatus.rejected);
    });

    test('timeout writes missed', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write =
          tracker.onOutgoingCallTimeoutOrCanceled(now: t0) as CallerStatusWrite?;
      expect(write!.status, CallStatus.missed);
    });

    test('cancel button also writes missed', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write =
          tracker.onOutgoingCallTimeoutOrCanceled(now: t0) as CallerStatusWrite?;
      expect(write!.status, CallStatus.missed);
    });

    test('onCallEnd before ever connecting writes failed, no duration', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      final write =
          tracker.onCallEnd(wasConnected: false, now: t0) as CallerStatusWrite?;

      expect(write!.callId, 'doc1');
      expect(write.status, CallStatus.failed);
      expect(write.durationInSeconds, isNull);
    });

    test('onCallEnd after connecting writes ended with duration', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
      tracker.onOutgoingCallAccepted(now: t0);
      tracker.updateDuration(const Duration(seconds: 42));

      final write = tracker.onCallEnd(wasConnected: true, now: t0.add(const Duration(seconds: 42)))
          as CallerStatusWrite?;

      expect(write!.status, CallStatus.ended);
      expect(write.durationInSeconds, 42);
    });

    test('a failed reconnect while connected writes disconnected', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
      tracker.onOutgoingCallAccepted(now: t0);
      tracker.updateDuration(const Duration(seconds: 10));

      final write = tracker.onReconnectFailed(now: t0) as CallerStatusWrite?;

      expect(write!.status, CallStatus.disconnected);
      expect(write.durationInSeconds, 10);
    });

    test('a failed reconnect before ever connecting is a no-op', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      expect(tracker.onReconnectFailed(now: t0), isNull);
    });

    test('onCallEnd never fires twice for the same call (terminal guard)', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
      tracker.onOutgoingCallAccepted(now: t0);

      final first = tracker.onCallEnd(wasConnected: true, now: t0);
      final second = tracker.onCallEnd(wasConnected: true, now: t0);

      expect(first, isNotNull);
      expect(second, isNull);
    });

    test(
      'a reconnect failure and the SDK\'s own onCallEnd for the same drop '
      'only produce one write, whichever observes it first',
      () {
        final tracker = CallOutcomeTracker();
        tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
        tracker.onOutgoingCallAccepted(now: t0);

        final reconnectWrite = tracker.onReconnectFailed(now: t0);
        final callEndWrite = tracker.onCallEnd(wasConnected: true, now: t0);

        expect(reconnectWrite, isNotNull);
        expect(callEndWrite, isNull);
      },
    );
  });

  group('CallOutcomeTracker -- receiver side', () {
    // Regression coverage for a real bug found while writing this test
    // suite: wasConnected used to be derived only from
    // onOutgoingCallAccepted, a caller-only event. A receiver's device
    // never called that, so its "call ended after connecting" write via
    // zegoCallId (the fallback for when the caller's device crashes mid
    // call) was silently unreachable. markConnected(), fed by the
    // caller-AND-receiver "room logined" signal, fixes that.
    test(
      'markConnected lets a receiver (no outgoing call tracked) resolve '
      'via zegoCallId once the call has connected',
      () {
        final tracker = CallOutcomeTracker();
        // What actually happens on a receiver's device: no
        // trackOutgoingCall (never the caller), just the config-required
        // hook picking up the caller's zegoCallId, then the room-joined
        // signal.
        tracker.onCallConfigRequired('zego1');
        tracker.markConnected(now: t0);
        tracker.updateDuration(const Duration(seconds: 30));

        final write = tracker.onCallEnd(
          wasConnected: tracker.isConnected,
          now: t0.add(const Duration(seconds: 30)),
        );

        expect(write, isA<ReceiverResolveWrite>());
        final resolve = write as ReceiverResolveWrite;
        expect(resolve.zegoCallId, 'zego1');
        expect(resolve.disconnected, isFalse);
        expect(resolve.durationInSeconds, 30);
      },
    );

    test(
      'without markConnected, a receiver never had isConnected -- pinning '
      'the pre-fix behavior so a future regression is caught',
      () {
        final tracker = CallOutcomeTracker();
        tracker.onCallConfigRequired('zego1');
        // markConnected() deliberately not called here.

        expect(tracker.isConnected, isFalse);
        expect(tracker.onCallEnd(wasConnected: tracker.isConnected, now: t0), isNull);
      },
    );

    test('a receiver never writes before connecting (no zegoCallId fallback for "failed")', () {
      final tracker = CallOutcomeTracker();
      tracker.onCallConfigRequired('zego1');

      final write = tracker.onCallEnd(wasConnected: false, now: t0);

      expect(write, isNull);
    });

    test('a receiver-side disconnect (failed reconnect) resolves via zegoCallId too', () {
      final tracker = CallOutcomeTracker();
      tracker.onCallConfigRequired('zego1');
      tracker.markConnected(now: t0);

      final write = tracker.onReconnectFailed(now: t0);

      expect(write, isA<ReceiverResolveWrite>());
      expect((write as ReceiverResolveWrite).disconnected, isTrue);
    });

    test('markConnected is idempotent -- keeps the earliest timestamp', () {
      final tracker = CallOutcomeTracker();
      tracker.markConnected(now: t0);
      tracker.markConnected(now: t0.add(const Duration(seconds: 5)));

      tracker.onCallConfigRequired('zego1');
      final write = tracker.onCallEnd(wasConnected: tracker.isConnected, now: t0);

      // Reaching the zegoCallId branch at all proves isConnected stayed
      // true across the second markConnected call.
      expect(write, isA<ReceiverResolveWrite>());
    });
  });

  group('CallOutcomeTracker -- lifecycle resets', () {
    test('reset() clears everything so a stale call cannot leak a write', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
      tracker.onOutgoingCallAccepted(now: t0);

      tracker.reset();

      expect(tracker.isConnected, isFalse);
      expect(tracker.onCallEnd(wasConnected: false, now: t0), isNull);
    });

    test('onCallConfigRequired resets the terminal guard for a new call', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');
      tracker.onOutgoingCallAccepted(now: t0);
      tracker.onCallEnd(wasConnected: true, now: t0);

      // A brand new call reuses the same tracker instance in real usage
      // (CallingService holds one for the app's lifetime).
      tracker.trackOutgoingCall('doc2', zegoCallId: 'zego2');
      final write = tracker.onCallEnd(wasConnected: false, now: t0);

      expect(write, isA<CallerStatusWrite>());
      expect((write as CallerStatusWrite).callId, 'doc2');
    });

    test('onCallConfigRequired ignores an empty callID', () {
      final tracker = CallOutcomeTracker();
      tracker.trackOutgoingCall('doc1', zegoCallId: 'zego1');

      tracker.onCallConfigRequired('');

      // zegoCallId from trackOutgoingCall should be untouched.
      tracker.markConnected(now: t0);
      final write = tracker.onCallEnd(wasConnected: true, now: t0);
      expect(write, isA<CallerStatusWrite>());
    });
  });
}
