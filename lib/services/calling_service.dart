import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../core/constants/zego_constants.dart';
import '../core/routes/navigator_key.dart';
import '../features/calling/call_config_builder.dart';
import 'call_connection_watchdog.dart';
import 'call_outcome_tracker.dart';
import 'call_service.dart';

/// Manages the ZEGOCLOUD call-invitation service and connects its
/// callbacks to [CallService]'s Firestore writes.
///
/// Deciding which status to write for which event -- the trickiest part
/// of this class -- is handled by [CallOutcomeTracker], a plain state
/// machine with no ZEGOCLOUD or Firestore dependency, kept separate so
/// that decision-making logic can be unit tested on its own. This class's
/// job is just the wiring: turn ZEGOCLOUD callbacks into
/// [CallOutcomeTracker] calls, then turn the [CallOutcomeWrite] that
/// comes back into an actual [CallService] write.
class CallingService {
  final CallService _callService;
  final CallOutcomeTracker _tracker;
  final CallConnectionWatchdog _watchdog;

  CallingService({
    required CallService callService,
    CallOutcomeTracker? tracker,
    CallConnectionWatchdog? watchdog,
  }) : _callService = callService,
       _tracker = tracker ?? CallOutcomeTracker(),
       _watchdog = watchdog ?? CallConnectionWatchdog();

  bool _initialized = false;
  bool _isGroupCall = false;
  Timer? _watchdogTimer;
  bool _peerEverJoined = false;
  bool _roomReconnecting = false;

  Future<void> init({required String userId, required String userName}) async {
    if (!ZegoConstants.isConfigured || _initialized) return;

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: ZegoConstants.appId,
      appSign: ZegoConstants.appSign,
      userID: userId,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      config: ZegoCallInvitationConfig(
        missedCall: ZegoCallInvitationMissedCallConfig(
          enabled: true,
          enableDialBack: false,
        ),
      ),
      // Default ringing/connecting to speaker so a video call doesn't
      // start on the earpiece -- buildCallConfig's useSpeakerWhenJoining
      // takes over once the call actually connects.
      uiConfig: ZegoCallInvitationUIConfig(
        inviter: ZegoCallInvitationInviterUIConfig(defaultSpeakerOn: true),
        invitee: ZegoCallInvitationInviteeUIConfig(defaultSpeakerOn: true),
      ),
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoCallAndroidNotificationConfig(
          // Show incoming calls even on a locked screen.
          showOnLockedScreen: true,
          showOnFullScreen: true,
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: ZegoConstants.notificationChannelId,
            channelName: ZegoConstants.notificationChannelName,
          ),
        ),
      ),
      requireConfig: (ZegoCallInvitationData data) {
        _tracker.onCallConfigRequired(data.callID);
        // More than one invitee means it's a group call.
        _isGroupCall = data.invitees.length > 1;
        return buildCallConfig(
          isVideoCall: data.type == ZegoCallInvitationType.videoCall,
          onDurationUpdate: _tracker.updateDuration,
          isGroupCall: _isGroupCall,
        );
      },
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: _onCallEnd,
        room: ZegoCallRoomEvents(onStateChanged: _onRoomStateChanged),
      ),
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onOutgoingCallAccepted: _onOutgoingCallAccepted,
        onOutgoingCallDeclined: _onOutgoingCallDeclined,
        onOutgoingCallRejectedCauseBusy: _onOutgoingCallRejectedCauseBusy,
        onOutgoingCallTimeout: _onOutgoingCallTimeout,
        onOutgoingCallCancelButtonPressed: _onOutgoingCallCanceled,
      ),
    );

    _initialized = true;
  }

  Future<void> uninit() async {
    if (!_initialized) return;
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    _initialized = false;
    _tracker.reset();
    _disarmWatchdog();
  }

  /// Call this right after [CallService.createCall] so the callbacks
  /// below know which Firestore doc to update.
  void trackOutgoingCall(String callId, {required String zegoCallId}) {
    _tracker.trackOutgoingCall(callId, zegoCallId: zegoCallId);
  }

  void _onOutgoingCallAccepted(String callID, ZegoCallUser callee) {
    _apply(_tracker.onOutgoingCallAccepted(), context: 'onOutgoingCallAccepted');
  }

  void _onOutgoingCallDeclined(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    _apply(
      _tracker.onOutgoingCallDeclinedOrBusy(),
      context: 'onOutgoingCallDeclined',
    );
  }

  void _onOutgoingCallRejectedCauseBusy(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    _apply(
      _tracker.onOutgoingCallDeclinedOrBusy(),
      context: 'onOutgoingCallRejectedCauseBusy',
    );
  }

  void _onOutgoingCallTimeout(
    String callID,
    List<ZegoCallUser> callees,
    bool isVideoCall,
  ) {
    _apply(
      _tracker.onOutgoingCallTimeoutOrCanceled(),
      context: 'onOutgoingCallTimeout',
    );
  }

  void _onOutgoingCallCanceled() {
    _apply(
      _tracker.onOutgoingCallTimeoutOrCanceled(),
      context: 'onOutgoingCallCanceled',
    );
  }

  void _onCallEnd(ZegoCallEndEvent event, VoidCallback defaultAction) {
    _disarmWatchdog();
    _apply(
      _tracker.onCallEnd(wasConnected: _tracker.isConnected),
      context: 'onCallEnd',
    );
    defaultAction();
  }

  void _onRoomStateChanged(ZegoUIKitRoomState state) {
    switch (state.reason) {
      case ZegoRoomStateChangedReason.Logined:
        // Fires for the caller AND the receiver once each device has
        // actually joined the call room -- unlike onOutgoingCallAccepted,
        // which is caller-only. Needed so a receiver's device can ever
        // mark itself connected (see CallOutcomeTracker.markConnected).
        _tracker.markConnected();
        _roomReconnecting = false;
        _armWatchdog();
      case ZegoRoomStateChangedReason.Reconnecting:
        // Our own connection is the one having trouble here, not the
        // peer's -- pause the watchdog for it so a blip on this device
        // can't read as "the peer went quiet".
        _roomReconnecting = true;
      case ZegoRoomStateChangedReason.Reconnected:
        _roomReconnecting = false;
      case ZegoRoomStateChangedReason.ReconnectFailed:
        // Only a failed reconnect counts as a real call outcome -- a
        // normal reconnect attempt is temporary and the SDK handles it on
        // its own.
        _disarmWatchdog();
        _apply(_tracker.onReconnectFailed(), context: 'onRoomStateChanged');
      default:
        break;
    }
  }

  /// Fallback for when ZEGOCLOUD's own "remote user left" detection misses
  /// the peer actually leaving (see [CallConnectionWatchdog]). Only runs
  /// for 1-to-1 calls -- one participant leaving a group call is normal
  /// and shouldn't end the call for everyone else.
  ///
  /// Skips arming a second timer if one is already running, since
  /// `Logined` can fire more than once for the same call (e.g. a
  /// reconnect re-login).
  void _armWatchdog() {
    if (_isGroupCall || _watchdogTimer != null) return;
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_watchdog.onTick(peerReachable: _samplePeerReachable())) {
        _forceEndStuckCall();
      }
    });
  }

  void _disarmWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _watchdog.reset();
    _peerEverJoined = false;
    _roomReconnecting = false;
  }

  /// Whether this tick counts as evidence the peer is gone. Three cases
  /// are deliberately read as "reachable" (i.e. don't count against the
  /// grace timer) even though we can't confirm the peer is actually there,
  /// because none of them are proof the peer left:
  ///
  /// - Our own room connection is mid-reconnect ([_roomReconnecting]) --
  ///   that's trouble on this device, not theirs.
  /// - The peer hasn't been observed in the room yet ([_peerEverJoined]) --
  ///   early in a call, before the other side has joined, the roster is
  ///   empty and stream quality reads its unset default for reasons that
  ///   have nothing to do with them leaving.
  /// - Their stream quality is merely `Unknown` rather than the SDK's own
  ///   `Die` ("failed") level -- `Unknown` is also what an unset quality
  ///   reading defaults to, so treating it the same as `Die` would flag a
  ///   stream that just hasn't reported in yet, not one that's dead.
  ///
  /// Only an empty roster, or a peer stream the SDK itself has already
  /// marked `Die`, counts as unreachable.
  bool _samplePeerReachable() {
    if (_roomReconnecting) return true;

    final remoteUsers = ZegoUIKit().getRemoteUsers();
    if (remoteUsers.isNotEmpty) _peerEverJoined = true;
    if (!_peerEverJoined) return true;
    if (remoteUsers.isEmpty) return false;

    final level = ZegoUIKit()
        .getAudioVideoQualityNotifier(remoteUsers.first.id)
        .value
        .level;
    return level != ZegoStreamQualityLevel.Die;
  }

  /// The peer has been unreachable for the watchdog's whole grace period --
  /// hang up locally exactly like the user pressing the hang-up button
  /// would, so it goes through the same [_onCallEnd] path (closes the UI,
  /// writes the same call-history status) instead of duplicating that logic.
  void _forceEndStuckCall() {
    _disarmWatchdog();
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ZegoUIKitPrebuiltCallController().hangUp(
      context,
      showConfirmation: false,
      reason: ZegoCallEndReason.abandoned,
    );
  }

  void _apply(CallOutcomeWrite? write, {required String context}) {
    switch (write) {
      case null:
        return;
      case CallerStatusWrite w:
        _writeCallStatus(
          () => _callService.updateCallStatus(
            w.callId,
            status: w.status,
            endedAt: w.endedAt,
            durationInSeconds: w.durationInSeconds,
          ),
          context: context,
        );
      case ReceiverResolveWrite w:
        final resolve = w.disconnected
            ? _callService.disconnectConnectedCall
            : _callService.endConnectedCall;
        _writeCallStatus(
          () => resolve(
            w.zegoCallId,
            endedAt: w.endedAt,
            durationInSeconds: w.durationInSeconds,
          ),
          context: context,
        );
    }
  }

  /// Fire-and-forget because these SDK callbacks are synchronous, but we
  /// still log errors instead of silently dropping them.
  void _writeCallStatus(Future<void> Function() write, {required String context}) {
    write().catchError((Object error, StackTrace stackTrace) {
      debugPrint('CallingService: call-status write failed ($context): $error\n$stackTrace');
    });
  }
}
