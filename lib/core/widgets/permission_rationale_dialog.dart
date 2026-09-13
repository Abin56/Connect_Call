import 'package:flutter/material.dart';

import 'app_alert_dialog.dart';

/// What the permission dialog is being shown for -- decides its icon and text.
enum PermissionPromptKind { microphone, camera, both }

/// Explains why we need camera/mic access before the OS asks cold. Built
/// on [AppAlertDialog] so it feels like part of the app, not some
/// unrelated system popup.
///
/// Returns `true` if the user tapped "Continue", `false` otherwise
/// (including if they just dismissed it).
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

/// Shown after the native prompt already got denied -- different text and
/// actions from the rationale dialog above. Returns `true` only if the
/// user chose to open Settings.
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
