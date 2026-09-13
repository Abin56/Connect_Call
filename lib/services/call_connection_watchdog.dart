/// Decides when [CallingService] should stop waiting on ZEGOCLOUD's own
/// "remote user left" room-presence detection and end a stuck call itself.
///
/// ZEGOCLOUD's call widget already ends the call once its local room
/// roster shows no remote users left. The problem is that roster only
/// updates when a "user left" notification actually reaches this device --
/// if that one notification is dropped (a network blip, a race during
/// reconnect), the roster never changes and the local screen is left
/// showing a call that, on the peer's side, is long over.
///
/// [CallingService] samples the peer's real reachability every few
/// seconds (roster membership AND stream quality, so a stale roster alone
/// can't hide a genuinely dead stream -- see the reachability check
/// there) and feeds each reading in here. Pure decision logic with no SDK
/// or Timer dependency, so the grace-period bookkeeping can be unit
/// tested without a real call.
class CallConnectionWatchdog {
  CallConnectionWatchdog({this.graceTimeout = const Duration(seconds: 15)});

  final Duration graceTimeout;

  DateTime? _unreachableSince;
  bool _fired = false;

  /// Feed this a reachability reading on every sample tick. Returns
  /// `true` the moment the peer has been continuously unreachable for at
  /// least [graceTimeout] -- only once per call, until [reset] -- so the
  /// caller knows exactly when to force a local hang-up.
  bool onTick({required bool peerReachable, DateTime? now}) {
    if (peerReachable) {
      _unreachableSince = null;
      return false;
    }
    if (_fired) return false;

    final effectiveNow = now ?? DateTime.now();
    _unreachableSince ??= effectiveNow;
    if (effectiveNow.difference(_unreachableSince!) >= graceTimeout) {
      _fired = true;
      return true;
    }
    return false;
  }

  void reset() {
    _unreachableSince = null;
    _fired = false;
  }
}
