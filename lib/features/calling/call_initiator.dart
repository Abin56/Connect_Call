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
/// it in Firestore call history.
///
/// Shared by every screen with a call button (Contacts, Home's Frequently
/// Called) so the offline/permission/blocked gates and history write only
/// live in one place.
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

  // Generated up front instead of letting ZEGOCLOUD auto-generate one, so
  // it can be written to Firestore as `zegoCallId` immediately and the
  // receiver can resolve the same doc via `ZegoCallInvitationData.callID`.
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

  // The invitation is already sent at this point, and there's no "unsend"
  // in the ZEGOCLOUD API. If the Firestore write fails, CallingService has
  // no doc id to attach later status updates to, so we surface the error
  // and let the call continue untracked rather than block the user.
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
