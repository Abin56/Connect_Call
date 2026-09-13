import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/zego_constants.dart';
import '../../services/permissions/call_permission_flow.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/connectivity_provider.dart';

/// Places a group call to [invitees] using the same ZEGOCLOUD invitation
/// service that [startCall] uses for 1-to-1 calls.
///
/// Kept separate from [startCall] because group calls are deliberately
/// not written to the `calls` history collection, which is built for one
/// caller and one receiver -- branching that logic inside [startCall]
/// would be messier than just having two small functions.
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

  // Every invitee needs its own check here -- the 1-to-1 block check in
  // call_initiator.dart doesn't run for a group call.
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
