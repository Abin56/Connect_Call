import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/zego_constants.dart';
import '../../services/permissions/call_permission_flow.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/call_history_provider.dart';
import '../../providers/calling_provider.dart';
import '../../providers/connectivity_provider.dart';

/// Places a call to [peer] via ZEGOCLOUD's invitation service and records
/// it in Firestore call history. Shared by every screen that offers a call
/// button (Contacts, Home's Frequently Called) so there is exactly one
/// implementation of "how a call gets started" -- config checks, the
/// offline/permission/blocked gates, and the Firestore write all happen
/// here rather than being copied per screen.
Future<void> startCall(
  BuildContext context,
  WidgetRef ref,
  UserModel peer, {
  required bool isVideoCall,
}) async {
  if (!ZegoConstants.isConfigured) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Calling is not configured.')));
    return;
  }

  final isOnline = ref.read(isOnlineProvider).value ?? true;
  if (!isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No internet connection. Please check your network and try again.',
        ),
      ),
    );
    return;
  }

  final me = ref.read(authStateProvider).value;
  if (me == null) return;

  final blocked = await ref
      .read(blockServiceProvider)
      .isBlockedEitherWay(me.uid, peer.id);
  if (!context.mounted) return;
  if (blocked) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You can\'t call this user.')));
    return;
  }

  final granted = await const CallPermissionFlow().ensure(
    context,
    needsCamera: isVideoCall,
  );
  if (!context.mounted || !granted) return;

  // Generated up front (rather than letting ZEGOCLOUD auto-generate one
  // inside `send()`) so this same ID can be written to Firestore as
  // `zegoCallId` immediately, and is guaranteed to match the `callID` the
  // receiver later reads off `ZegoCallInvitationData` -- letting both sides
  // reliably resolve the same call document.
  final zegoCallId = 'call_${me.uid}_${DateTime.now().millisecondsSinceEpoch}';

  final sent = await ZegoUIKitPrebuiltCallInvitationService().send(
    invitees: [ZegoCallUser(peer.id, peer.name)],
    isVideoCall: isVideoCall,
    callID: zegoCallId,
  );
  if (!sent) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Couldn\'t start the call. Please try again.'),
      ),
    );
    return;
  }

  // The invitation is already on its way to the callee at this point, so a
  // failure here must not be silent: without a Firestore doc id,
  // CallingService has nothing to attach the later accepted/ended callbacks
  // to, and the call would proceed with no history record at all. We can't
  // retract the invitation (no "unsend" in the ZEGOCLOUD API), so on failure
  // we surface it and let the call continue ZEGOCLOUD-side untracked rather
  // than leaving the app in a half-configured state.
  try {
    final callId = await ref
        .read(callServiceProvider)
        .createCall(
          CallModel(
            id: '',
            callerId: me.uid,
            callerName: me.displayName ?? me.email ?? 'Unknown',
            receiverId: peer.id,
            receiverName: peer.name,
            callType: isVideoCall ? CallType.video : CallType.audio,
            status: CallStatus.calling,
            startedAt: DateTime.now(),
            zegoCallId: zegoCallId,
          ),
        );
    ref
        .read(callingServiceProvider)
        .trackOutgoingCall(callId, zegoCallId: zegoCallId);
  } catch (error, stackTrace) {
    debugPrint('startCall: failed to create call history record: $error\n$stackTrace');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Call connected, but we couldn\'t save it to your call history.',
        ),
      ),
    );
  }
}
