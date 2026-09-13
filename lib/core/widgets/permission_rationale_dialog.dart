import 'package:flutter/material.dart';

import 'app_alert_dialog.dart';

/// What a [PermissionRationaleDialog] is being shown for -- controls icon,
/// copy, and (for [denied]/[permanentlyDenied]) which action the primary
/// button performs. [microphone]/[camera]/[both] are shown *before* the
/// native OS prompt (rationale); [denied]/[permanentlyDenied] are shown
/// *after* the user has already said no once.
enum PermissionPromptKind { microphone, camera, both }

/// Branded, theme-aware replacement for asking the OS for camera/mic
/// permission cold. Built on [AppAlertDialog] (same icon-badge/title/message
/// shape used everywhere else in the app) so it never reads as a second,
/// unrelated permission system -- just this app's own explanation shown a
/// beat before the native dialog.
///
/// Returns `true` if the user tapped the primary action ("Continue" for a
/// rationale, "Open Settings" for a permanently-denied prompt), `false`
/// otherwise (including dismissal).
Future<bool> showPermissionRationaleDialog(
  BuildContext context, {
  required PermissionPromptKind kind,
}) {
  final (icon, title, message) = switch (kind) {
    PermissionPromptKind.microphone => (
        Icons.mic_none_rounded,
        'Microphone access',
        'ConnectCall needs access to your microphone so you can talk during the call. Your microphone is only used while you\'re on a call.',
      ),
    PermissionPromptKind.camera => (
        Icons.videocam_outlined,
        'Camera access',
        'Allow camera access so others can see you during video calls.',
      ),
    PermissionPromptKind.both => (
        Icons.videocam_outlined,
        'Ready for video calls?',
        'Camera and microphone access are needed for video calling. You control these permissions from your device settings.',
      ),
  };

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      icon: icon,
      title: title,
      message: message,
      cancelLabel: 'Not now',
      confirmLabel: 'Continue',
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  ).then((result) => result ?? false);
}

/// Shown after the native prompt has already denied (or permanently
/// denied) the permission -- distinct copy/actions from the pre-prompt
/// rationale above. Returns `true` only if the user chose to open Settings.
Future<bool> showPermissionDeniedDialog(
  BuildContext context, {
  required PermissionPromptKind kind,
  required bool permanentlyDenied,
}) {
  final label = switch (kind) {
    PermissionPromptKind.microphone => 'Microphone',
    PermissionPromptKind.camera => 'Camera',
    PermissionPromptKind.both => 'Camera and microphone',
  };
  final icon = switch (kind) {
    PermissionPromptKind.microphone => Icons.mic_off_rounded,
    PermissionPromptKind.camera => Icons.videocam_off_rounded,
    PermissionPromptKind.both => Icons.videocam_off_rounded,
  };

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      icon: icon,
      title: permanentlyDenied ? 'Permission required' : '$label permission needed',
      message: permanentlyDenied
          ? 'Enable access in Settings to use this feature.'
          : '$label access is required for this call. You can allow it from your device settings.',
      cancelLabel: 'Not now',
      confirmLabel: permanentlyDenied ? 'Open Settings' : null,
      onConfirm: permanentlyDenied
          ? () => Navigator.of(dialogContext).pop(true)
          : null,
    ),
  ).then((result) => result ?? false);
}
