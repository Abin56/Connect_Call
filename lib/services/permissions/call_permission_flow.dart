import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/call_permissions.dart';
import '../../core/widgets/permission_rationale_dialog.dart';

/// One shared check that every call entry point (1-to-1, group,
/// audio/video) runs through before placing a call. Keeping it in one
/// place means the explain-then-ask-then-continue flow stays consistent
/// instead of drifting screen to screen.
///
/// Never touches ZEGOCLOUD or Firestore -- it just answers "is it OK to
/// start this call right now?". Callers must bail out if it returns `false`.
class CallPermissionFlow {
  const CallPermissionFlow();

  /// Stops a double-tap from opening two permission dialogs at once. It's
  /// static because every call site makes its own `const
  /// CallPermissionFlow()`, but they all need to share one in-flight check.
  static bool _inFlight = false;

  /// Runs the full flow for a call that needs mic, and camera too if
  /// [needsCamera]. Returns `true` only once access is granted, or
  /// `false` right away if a flow is already running from an earlier tap.
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

    // Already permanently denied -- go straight to the Settings dialog
    // instead of showing a rationale for a native prompt that won't show up.
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
    // The caller must re-check after this -- returning `true` here would
    // start a call before permission is actually granted.
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
