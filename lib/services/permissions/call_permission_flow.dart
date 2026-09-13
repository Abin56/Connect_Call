import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/call_permissions.dart';
import '../../core/widgets/permission_rationale_dialog.dart';

/// Single reusable gate every call entry point (1-to-1 audio/video, group
/// audio/video) runs through before placing a call. Centralizing this here
/// (rather than duplicating the same show-rationale/request/handle-denial
/// sequence in each of `call_initiator.dart` / `group_call_initiator.dart`)
/// is what makes the "explain, then ask, then continue automatically" UX
/// consistent across every call type instead of drifting per screen.
///
/// Never touches ZEGOCLOUD or Firestore -- purely answers "is it OK to
/// start this call right now", showing whatever branded UI is needed to
/// get there. Callers are expected to bail out (and not place the call) if
/// this returns `false`.
class CallPermissionFlow {
  const CallPermissionFlow();

  /// Guards against a double-tap (or two different call buttons tapped in
  /// quick succession) opening two overlapping rationale/native-permission
  /// dialogs at once. Static rather than per-instance since every call site
  /// constructs its own `const CallPermissionFlow()` but they must all
  /// share one in-flight flow.
  static bool _inFlight = false;

  /// Runs the full contextual flow for a call that needs [needsCamera]
  /// camera access in addition to the microphone it always needs. Returns
  /// `true` only once the required permission(s) are actually granted.
  /// Returns `false` immediately (without showing anything) if a flow is
  /// already in progress from an earlier tap.
  Future<bool> ensure(
    BuildContext context, {
    required bool needsCamera,
  }) async {
    if (_inFlight) return false;
    _inFlight = true;
    try {
      return await _run(context, needsCamera: needsCamera);
    } finally {
      _inFlight = false;
    }
  }

  Future<bool> _run(
    BuildContext context, {
    required bool needsCamera,
  }) async {
    var check = await checkCallPermissions(needsCamera: needsCamera);
    if (check.isGranted) return true;

    // Permanently denied already (e.g. the user denied once before and the
    // OS won't show its own prompt again) -- go straight to the
    // Settings-flow dialog rather than a rationale for a prompt that won't
    // appear.
    if (!context.mounted) return false;
    if (check.isPermanentlyDenied) {
      return _handlePermanentlyDenied(context, check);
    }

    final kind = _promptKindFor(check);
    final continued = await showPermissionRationaleDialog(context, kind: kind);
    if (!continued) return false;

    if (!context.mounted) return false;
    check = await requestCallPermissions(needsCamera: needsCamera);
    if (check.isGranted) return true;

    if (!context.mounted) return false;
    if (check.isPermanentlyDenied) {
      return _handlePermanentlyDenied(context, check);
    }

    await showPermissionDeniedDialog(
      context,
      kind: _promptKindFor(check),
      permanentlyDenied: false,
    );
    return false;
  }

  Future<bool> _handlePermanentlyDenied(
    BuildContext context,
    CallPermissionCheck check,
  ) async {
    final openSettings = await showPermissionDeniedDialog(
      context,
      kind: _promptKindFor(check),
      permanentlyDenied: true,
    );
    if (openSettings) {
      await openAppSettings();
    }
    // Whether or not Settings was opened, the caller must re-check after
    // this returns -- returning `true` here would start a call before the
    // permission is actually granted.
    return false;
  }

  PermissionPromptKind _promptKindFor(CallPermissionCheck check) {
    if (check.needsCamera) {
      final missingCameraOnly =
          check.isMissingCamera && !check.isMissingMicrophone;
      final missingMicOnly =
          check.isMissingMicrophone && !check.isMissingCamera;
      if (missingCameraOnly) return PermissionPromptKind.camera;
      if (missingMicOnly) return PermissionPromptKind.microphone;
      return PermissionPromptKind.both;
    }
    return PermissionPromptKind.microphone;
  }
}
