import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/app_alert_dialog.dart';

/// Contextual notification-permission prompt, deliberately separate from
/// [CallPermissionFlow] (mic/camera) -- different permission, different
/// purpose (incoming-call alerts while backgrounded), so it shouldn't be
/// bundled into the same rationale.
///
/// Triggered once, right after calling is set up for this user (see
/// `main.dart`'s auth listener), which is the first moment notifications
/// are actually relevant -- not on first app launch or during login.
class NotificationPermissionFlow {
  const NotificationPermissionFlow();

  static const _askedPrefsKey = 'notification_permission_asked';

  /// Shows the rationale and requests notification permission, but only if
  /// it's undecided and hasn't been offered before -- otherwise returning
  /// users would get re-prompted every time calling re-initializes.
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
