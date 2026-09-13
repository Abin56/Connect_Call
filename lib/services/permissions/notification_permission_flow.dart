import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/app_alert_dialog.dart';

/// Asks for notification permission at the right moment, kept separate
/// from [CallPermissionFlow] (mic/camera) since it's a different
/// permission for a different reason (incoming-call alerts in the
/// background).
///
/// Triggered once, right after calling is set up for this user (see
/// `main.dart`'s auth listener) -- that's the first moment notifications
/// actually matter, not on first launch or during login.
class NotificationPermissionFlow {
  const NotificationPermissionFlow();

  static const _askedPrefsKey = 'notification_permission_asked';

  /// Shows the rationale and asks for notification permission, but only
  /// if it's still undecided and we haven't asked before -- otherwise
  /// returning users would get re-prompted every time calling restarts.
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
