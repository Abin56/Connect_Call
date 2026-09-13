import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/services/call_connection_watchdog.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12, 0, 0);

  group('CallConnectionWatchdog', () {
    test('does not fire while the peer stays reachable', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      expect(
        watchdog.onTick(peerReachable: true, now: t0),
        isFalse,
      );
      expect(
        watchdog.onTick(peerReachable: true, now: t0.add(const Duration(seconds: 30))),
        isFalse,
      );
    });

    test('does not fire before the grace period has elapsed', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      expect(watchdog.onTick(peerReachable: false, now: t0), isFalse);
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 3)),
        ),
        isFalse,
      );
    });

    test('fires once the peer has been unreachable for the whole grace period', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      expect(watchdog.onTick(peerReachable: false, now: t0), isFalse);
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 6)),
        ),
        isTrue,
      );
    });

    test('only fires once per unreachable streak', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      watchdog.onTick(peerReachable: false, now: t0);
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 6)),
        ),
        isTrue,
      );
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 12)),
        ),
        isFalse,
      );
    });

    test('a reachable reading resets the grace-period clock', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      watchdog.onTick(peerReachable: false, now: t0);
      // Peer comes back (a brief reconnect blip) before the timeout.
      watchdog.onTick(
        peerReachable: true,
        now: t0.add(const Duration(seconds: 4)),
      );
      // Unreachable again -- the clock should have restarted, not carried
      // over from the first drop.
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 9)),
        ),
        isFalse,
      );
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 15)),
        ),
        isTrue,
      );
    });

    test('reset lets the watchdog fire again for a new call', () {
      final watchdog = CallConnectionWatchdog(
        graceTimeout: const Duration(seconds: 6),
      );

      watchdog.onTick(peerReachable: false, now: t0);
      watchdog.onTick(
        peerReachable: false,
        now: t0.add(const Duration(seconds: 6)),
      );
      watchdog.reset();

      expect(watchdog.onTick(peerReachable: false, now: t0), isFalse);
      expect(
        watchdog.onTick(
          peerReachable: false,
          now: t0.add(const Duration(seconds: 6)),
        ),
        isTrue,
      );
    });
  });
}
