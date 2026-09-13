import '../models/call_model.dart';

/// One call-status write [CallingService] should perform, decided by
/// [CallOutcomeTracker]. Each event produces exactly one of the two
/// shapes below, matching the caller/receiver split described on
/// [CallOutcomeTracker].
sealed class CallOutcomeWrite {
  const CallOutcomeWrite();
}

/// For the caller: we already have the Firestore doc id, so this just updates it.
class CallerStatusWrite extends CallOutcomeWrite {
  final String callId;
  final CallStatus status;
  final DateTime endedAt;
  final int? durationInSeconds;

  const CallerStatusWrite({
    required this.callId,
    required this.status,
    required this.endedAt,
    this.durationInSeconds,
  });
}

/// For the receiver: we never have the Firestore doc id, so this looks it
/// up using the caller-generated `zegoCallId` instead. Only ever produced
/// once a call has connected -- a receiver never records a "failed" outcome.
class ReceiverResolveWrite extends CallOutcomeWrite {
  final String zegoCallId;
  final bool disconnected;
  final DateTime endedAt;
  final int durationInSeconds;

  const ReceiverResolveWrite({
    required this.zegoCallId,
    required this.disconnected,
    required this.endedAt,
    required this.durationInSeconds,
  });
}

/// A plain state machine that decides what (if any) call-history write
/// should happen for each ZEGOCLOUD invitation/call event.
///
/// Pulled out of [CallingService] as its own piece -- with no dependency
/// on the ZEGOCLOUD SDK or Firestore -- specifically so this branching
/// logic (the trickiest part of the calling feature: caller vs. receiver,
/// who owns which write, and making sure a call never gets written twice)
/// can be unit tested on its own. [CallingService] is the one that turns
/// the [CallOutcomeWrite] this returns into an actual [CallService] call.
///
/// The caller writes every status it can see directly (connected,
/// rejected, missed, failed, ended). The receiver never has the Firestore
/// doc id, so for the one outcome both sides can see -- a call ending
/// after it connected -- it looks up the same doc using `zegoCallId` instead.
class CallOutcomeTracker {
  String? _outgoingCallId;
  String? _currentZegoCallId;
  DateTime? _connectedAt;
  Duration _lastKnownDuration = Duration.zero;
  bool _terminalWriteIssued = false;

  /// Whether a connected call is currently being tracked. Exposed for
  /// [CallingService]'s room-state-changed check.
  bool get isConnected => _connectedAt != null;

  void reset() {
    _outgoingCallId = null;
    _currentZegoCallId = null;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
    _terminalWriteIssued = false;
  }

  /// Call this right after creating the Firestore call doc, so later
  /// callbacks know which one to update.
  void trackOutgoingCall(String callId, {required String zegoCallId}) {
    _outgoingCallId = callId;
    _currentZegoCallId = zegoCallId;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
    _terminalWriteIssued = false;
  }

  /// Call this whenever the SDK asks for call-screen config (for both
  /// caller and receiver, 1-to-1 or group), so the receiver has a
  /// `zegoCallId` to fall back on even though it never calls [trackOutgoingCall].
  void onCallConfigRequired(String zegoCallId) {
    if (zegoCallId.isEmpty) return;
    _currentZegoCallId = zegoCallId;
    _terminalWriteIssued = false;
  }

  void updateDuration(Duration duration) => _lastKnownDuration = duration;

  /// Marks the call as connected without producing a write of its own.
  ///
  /// Idempotent (keeps the earliest timestamp) so it's safe to call from
  /// both the room-level "joined" signal (which fires for caller AND
  /// receiver) and [onOutgoingCallAccepted] (caller-only) without the
  /// second call clobbering the first.
  ///
  /// This is what makes [wasConnected]-gated writes reachable on the
  /// receiver's side at all: the receiver never gets
  /// [onOutgoingCallAccepted] (that's a caller-only invitation event), so
  /// without a room-level signal too, a receiver's device could never
  /// observe its own call as "connected" -- silently disabling the
  /// zegoCallId fallback write in [onCallEnd] for every receiver.
  void markConnected({DateTime? now}) {
    _connectedAt ??= now ?? DateTime.now();
  }

  CallOutcomeWrite? onOutgoingCallAccepted({DateTime? now}) {
    final callId = _outgoingCallId;
    if (callId == null) return null;
    markConnected(now: now);
    return CallerStatusWrite(
      callId: callId,
      status: CallStatus.connected,
      endedAt: _connectedAt!,
    );
  }

  CallOutcomeWrite? onOutgoingCallDeclinedOrBusy({DateTime? now}) =>
      _endOutgoingAs(CallStatus.rejected, now: now);

  CallOutcomeWrite? onOutgoingCallTimeoutOrCanceled({DateTime? now}) =>
      _endOutgoingAs(CallStatus.missed, now: now);

  CallOutcomeWrite? _endOutgoingAs(CallStatus status, {DateTime? now}) {
    if (_terminalWriteIssued) return null;
    final callId = _outgoingCallId;
    if (callId == null) return null;
    _terminalWriteIssued = true;
    _outgoingCallId = null;
    _currentZegoCallId = null;
    return CallerStatusWrite(
      callId: callId,
      status: status,
      endedAt: now ?? DateTime.now(),
    );
  }

  /// Only a failed reconnect counts as a real call outcome -- reconnecting
  /// itself is temporary and the SDK handles it on its own. Returns
  /// `null` (does nothing) unless the call was connected and then failed
  /// to reconnect.
  CallOutcomeWrite? onReconnectFailed({DateTime? now}) {
    if (!isConnected) return null;
    return onCallEnd(wasConnected: true, disconnected: true, now: now);
  }

  /// The one place a call ending gets resolved, whether that's through
  /// the SDK's own `onCallEnd` or a failed reconnect -- guarded by the
  /// same [_terminalWriteIssued] flag so the two can't both produce a
  /// write for the same call.
  CallOutcomeWrite? onCallEnd({
    required bool wasConnected,
    bool disconnected = false,
    DateTime? now,
  }) {
    if (_terminalWriteIssued) return null;
    _terminalWriteIssued = true;

    final endedAt = now ?? DateTime.now();
    final durationInSeconds = _lastKnownDuration.inSeconds;
    final callId = _outgoingCallId;
    final zegoCallId = _currentZegoCallId;

    CallOutcomeWrite? write;
    if (callId != null) {
      _outgoingCallId = null;
      final status = !wasConnected
          ? CallStatus.failed
          : (disconnected ? CallStatus.disconnected : CallStatus.ended);
      write = CallerStatusWrite(
        callId: callId,
        status: status,
        endedAt: endedAt,
        durationInSeconds: wasConnected ? durationInSeconds : null,
      );
    } else if (wasConnected && zegoCallId != null) {
      write = ReceiverResolveWrite(
        zegoCallId: zegoCallId,
        disconnected: disconnected,
        endedAt: endedAt,
        durationInSeconds: durationInSeconds,
      );
    }

    _currentZegoCallId = null;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
    return write;
  }
}
