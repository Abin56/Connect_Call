import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/zego_constants.dart';
import '../../services/permissions/call_permission_flow.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/connectivity_provider.dart';

/// Places a group call to [invitees] via the same ZEGOCLOUD invitation
/// service [startCall] (see call_initiator.dart) uses for 1-to-1 calls --
/// there is only ever one invitation service/call architecture in this app.
/// Kept as a separate entry point (rather than folded into [startCall])
/// because group calls are deliberately NOT written to the `calls` Firestore
/// history collection, which is shaped for exactly one caller + one
/// receiver; reusing the same function for both would mean branching its
/// history-recording behavior on invitee count, which is more confusing
/// than two small, single-purpose functions.
///
/// Returns true if the invitation was sent.
Future<bool> startGroupCall(
  BuildContext context,
  WidgetRef ref,
  List<UserModel> invitees, {
  required bool isVideoCall,
}) async {
  if (!ZegoConstants.isConfigured) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Calling is not configured.')));
    return false;
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
    return false;
  }

  final me = ref.read(authStateProvider).value;
  if (me == null) return false;

  // Every selected participant must be checked -- a blocked contact must
  // not slip into a group call just because the 1-to-1 gate in
  // [call_initiator.dart] never ran for them. Reuses [BlockService] rather
  // than any new check, per the same bidirectional block rule the rest of
  // the app follows.
  final blockService = ref.read(blockServiceProvider);
  final blockChecks = await Future.wait(
    invitees.map((peer) => blockService.isBlockedEitherWay(me.uid, peer.id)),
  );
  if (!context.mounted) return false;
  if (blockChecks.any((blocked) => blocked)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Some selected users are blocked.')),
    );
    return false;
  }

  final granted = await const CallPermissionFlow().ensure(
    context,
    needsCamera: isVideoCall,
  );
  if (!context.mounted || !granted) return false;

  final sent = await ZegoUIKitPrebuiltCallInvitationService().send(
    invitees: [for (final peer in invitees) ZegoCallUser(peer.id, peer.name)],
    isVideoCall: isVideoCall,
  );
  if (!sent) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Couldn\'t start the group call. Please try again.'),
      ),
    );
    return false;
  }

  return true;
}
