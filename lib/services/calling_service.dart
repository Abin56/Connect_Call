import 'package:flutter/foundation.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../core/constants/zego_constants.dart';
import '../features/calling/call_config_builder.dart';
import '../models/call_model.dart';
import 'call_service.dart';

/// Owns the ZEGOCLOUD call-invitation service lifecycle and bridges its
/// callbacks to [CallService] Firestore writes.
///
/// The caller owns every status write it can observe directly (accepted,
/// declined, timeout, canceled, missed). The receiver doesn't hold the
/// Firestore doc id, so for the one case both sides can observe -- a call
/// ending after connecting -- it resolves the same doc via `zegoCallId`
/// instead (see [CallService.endConnectedCall]).
///
/// [_resolveCallEnd] is the single place both ends funnel through, guarded
/// by [_terminalWriteIssued] so a dropped connection can't get written
/// twice (once from `ReconnectFailed`, once from the SDK's own `onCallEnd`).
class CallingService {
  final CallService _callService;

  CallingService({required CallService callService})
    : _callService = callService;

  bool _initialized = false;

  /// Firestore doc id for the call this device is currently placing.
  String? _outgoingCallId;
  DateTime? _connectedAt;
  Duration _lastKnownDuration = Duration.zero;

  /// ZEGOCLOUD's own callID for the active call, caller or receiver side.
  /// Lets a receiver resolve the caller's Firestore doc without holding
  /// its id directly.
  String? _currentZegoCallId;

  /// Set once the terminal write for this call has gone out, so a repeat
  /// callback can't write history twice for the same call.
  bool _terminalWriteIssued = false;

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
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoCallAndroidNotificationConfig(
          // Wake and cover the lock screen for incoming calls.
          showOnLockedScreen: true,
          showOnFullScreen: true,
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: ZegoConstants.notificationChannelId,
            channelName: ZegoConstants.notificationChannelName,
          ),
        ),
      ),
      requireConfig: (ZegoCallInvitationData data) {
        if (data.callID.isNotEmpty) {
          _currentZegoCallId = data.callID;
          _terminalWriteIssued = false;
        }
        return buildCallConfig(
          isVideoCall: data.type == ZegoCallInvitationType.videoCall,
          onDurationUpdate: (duration) => _lastKnownDuration = duration,
          // More than one invitee means a group call, on either side.
          isGroupCall: data.invitees.length > 1,
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
    _outgoingCallId = null;
    _currentZegoCallId = null;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
    _terminalWriteIssued = false;
  }

  /// Call this right after [CallService.createCall] so the callbacks below
  /// know which Firestore doc to update.
  void trackOutgoingCall(String callId, {required String zegoCallId}) {
    _outgoingCallId = callId;
    _currentZegoCallId = zegoCallId;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
    _terminalWriteIssued = false;
  }

  void _onOutgoingCallAccepted(String callID, ZegoCallUser callee) {
    final callId = _outgoingCallId;
    if (callId == null) return;
    _connectedAt = DateTime.now();
    _writeCallStatus(
      () => _callService.updateCallStatus(callId, status: CallStatus.connected),
      context: 'onOutgoingCallAccepted',
    );
  }

  void _onOutgoingCallDeclined(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    _endOutgoingAs(CallStatus.rejected);
  }

  void _onOutgoingCallRejectedCauseBusy(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    _endOutgoingAs(CallStatus.rejected);
  }

  void _onOutgoingCallTimeout(
    String callID,
    List<ZegoCallUser> callees,
    bool isVideoCall,
  ) {
    _endOutgoingAs(CallStatus.missed);
  }

  void _onOutgoingCallCanceled() {
    _endOutgoingAs(CallStatus.missed);
  }

  void _endOutgoingAs(CallStatus status) {
    if (_terminalWriteIssued) return;
    final callId = _outgoingCallId;
    if (callId == null) return;
    _terminalWriteIssued = true;
    _outgoingCallId = null;
    _currentZegoCallId = null;
    _writeCallStatus(
      () => _callService.updateCallStatus(
        callId,
        status: status,
        endedAt: DateTime.now(),
      ),
      context: '_endOutgoingAs($status)',
    );
  }

  void _onCallEnd(ZegoCallEndEvent event, VoidCallback defaultAction) {
    _resolveCallEnd(wasConnected: _connectedAt != null);
    defaultAction();
  }

  /// Only a reconnect failure counts as a call outcome -- reconnecting
  /// itself is transient and the SDK handles it on its own.
  void _onRoomStateChanged(ZegoUIKitRoomState state) {
    if (state.reason != ZegoRoomStateChangedReason.ReconnectFailed) return;
    if (_connectedAt == null) return;
    _resolveCallEnd(wasConnected: true, disconnected: true);
  }

  /// Single resolution path for [_onCallEnd] and [_onRoomStateChanged] so
  /// they can't both write a terminal status for the same call.
  void _resolveCallEnd({
    required bool wasConnected,
    bool disconnected = false,
  }) {
    if (_terminalWriteIssued) return;
    _terminalWriteIssued = true;

    final durationInSeconds = _lastKnownDuration.inSeconds;
    final callId = _outgoingCallId;
    final zegoCallId = _currentZegoCallId;

    if (callId != null) {
      // Caller side: we hold the Firestore doc id directly.
      _outgoingCallId = null;
      final status = !wasConnected
          ? CallStatus.failed
          : (disconnected ? CallStatus.disconnected : CallStatus.ended);
      _writeCallStatus(
        () => _callService.updateCallStatus(
          callId,
          status: status,
          endedAt: DateTime.now(),
          durationInSeconds: wasConnected ? durationInSeconds : null,
        ),
        context: '_resolveCallEnd(caller, $status)',
      );
    } else if (wasConnected && zegoCallId != null) {
      // Receiver side: resolve the caller's doc via zegoCallId instead.
      // Only applies once connected -- a receiver never writes "failed".
      final resolve = disconnected
          ? _callService.disconnectConnectedCall
          : _callService.endConnectedCall;
      _writeCallStatus(
        () => resolve(
          zegoCallId,
          endedAt: DateTime.now(),
          durationInSeconds: durationInSeconds,
        ),
        context: '_resolveCallEnd(receiver, disconnected=$disconnected)',
      );
    }

    _currentZegoCallId = null;
    _connectedAt = null;
    _lastKnownDuration = Duration.zero;
  }

  /// Fire-and-forget since these SDK callbacks are synchronous, but errors
  /// are still logged instead of swallowed.
  void _writeCallStatus(Future<void> Function() write, {required String context}) {
    write().catchError((Object error, StackTrace stackTrace) {
      debugPrint('CallingService: call-status write failed ($context): $error\n$stackTrace');
    });
  }
}
