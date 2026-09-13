import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/call_permissions.dart';
import '../../core/widgets/permission_rationale_dialog.dart';

/// Single reusable gate every call entry point (1-to-1, group, audio/video)
/// runs through before placing a call. Centralized here so the
/// explain-then-ask-then-continue UX stays consistent instead of drifting
/// per screen.
///
/// Never touches ZEGOCLOUD or Firestore -- just answers "is it OK to start
/// this call right now". Callers must bail out if this returns `false`.
class CallPermissionFlow {
  const CallPermissionFlow();

  /// Guards against a double-tap opening two overlapping permission dialogs
  /// at once. Static since every call site constructs its own `const
  /// CallPermissionFlow()` but they must all share one in-flight flow.
  static bool _inFlight = false;

  /// Runs the full flow for a call needing mic, and camera too if
  /// [needsCamera]. Returns `true` only once granted; `false` immediately
  /// if a flow is already in progress from an earlier tap.
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
    // rather than a rationale for a native prompt that won't appear.
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
    // Caller must re-check after this returns -- returning `true` here
    // would start a call before the permission is actually granted.
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
