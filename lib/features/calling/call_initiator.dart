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

/// Places a call to [peer] through ZEGOCLOUD's invitation service and
/// saves it to Firestore call history.
///
/// Shared by every screen with a call button (Contacts, Home's Frequently
/// Called) so the offline check, permission check, block check, and
/// history write all live in exactly one place.
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

  // We generate this ourselves instead of letting ZEGOCLOUD auto-generate
  // one, so we can save it to Firestore as `zegoCallId` right away, and
  // the receiver can look up the same doc via `ZegoCallInvitationData.callID`.
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

  // The invitation has already gone out, and there's no "unsend" in the
  // ZEGOCLOUD API. If this Firestore write fails, CallingService won't
  // have a doc id to attach later status updates to -- so we just warn
  // the user and let the call carry on untracked instead of blocking them.
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
