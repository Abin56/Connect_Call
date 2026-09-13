import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/app_alert_dialog.dart';

/// Contextual notification-permission prompt, deliberately separate from
/// [CallPermissionFlow] (mic/camera) -- this is a different permission for
/// a different purpose (seeing incoming-call alerts while ConnectCall is
/// backgrounded) and must never be bundled into the same rationale as
/// camera/microphone access.
///
/// Triggered once, right after calling is set up for this user (see
/// `main.dart`'s auth listener, right after `CallingService.init()`), which
/// is the first moment notifications are actually relevant -- not on first
/// app launch and not mixed into login/registration.
class NotificationPermissionFlow {
  const NotificationPermissionFlow();

  static const _askedPrefsKey = 'notification_permission_asked';

  /// Shows the branded rationale and requests notification permission if
  /// it hasn't been decided yet, and hasn't already been offered once
  /// before (so returning users aren't re-prompted every time calling
  /// re-initializes, e.g. on every app resume). No-ops entirely if the
  /// permission is already granted, or already permanently denied (in
  /// which case re-prompting would just be ignored by the OS anyway --
  /// the user can still enable it from Settings on their own).
  Future<void> maybeRequest(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted || status.isPermanentlyDenied || status.isRestricted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedPrefsKey) ?? false) return;
    await prefs.setBool(_askedPrefsKey, true);

    if (!context.mounted) return;
    final continued = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        icon: Icons.notifications_none_rounded,
        title: 'Stay available for incoming calls',
        message:
            'Allow notifications so you can see incoming call alerts when ConnectCall is in the background.',
        cancelLabel: 'Not now',
        confirmLabel: 'Continue',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (continued != true) return;

    await Permission.notification.request();
  }
}
