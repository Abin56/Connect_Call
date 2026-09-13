/// ZEGOCLOUD project credentials.
///
/// Heads up: a real production app should swap AppSign for a short-lived
/// token fetched from a server (see ZEGOCLOUD's token server sample),
/// since the sign is a long-lived secret. This project uses AppID +
/// AppSign directly, which is ZEGOCLOUD's "quick start" mode -- fine for
/// getting going, not for shipping.
class ZegoConstants {
  ZegoConstants._();

  static const int appId = 222639987;

  static const String appSign = '8b0ef1e49bee14a906e1f37e60b47e3eb8823eb5593ed0fb1e90cbb7bee2a80b';

  static bool get isConfigured => appId != 0 && appSign.isNotEmpty;

  /// Notification channel for incoming-call push notifications (ZEGOCLOUD's
  /// offline-push, ZPNs) when the app is backgrounded or closed.
  static const String notificationChannelId = 'connectcall_calls';
  static const String notificationChannelName = 'Incoming Calls';
}
