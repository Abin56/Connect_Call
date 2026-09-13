/// ZEGOCLOUD project credentials.
///
/// Passed in at build/run time via --dart-define so AppID/AppSign never get
/// hardcoded into source control. See README for the `flutter run` command.
///
/// A production app should exchange AppSign for a short-lived token from a
/// server (ZEGOCLOUD's token server sample) instead, since the sign itself
/// is a long-lived secret. This demo uses AppID + AppSign directly, which is
/// ZEGOCLOUD's "quick start" mode.
class ZegoConstants {
  ZegoConstants._();

  static const int appId = int.fromEnvironment('ZEGO_APP_ID');

  static const String appSign = String.fromEnvironment('ZEGO_APP_SIGN');

  static bool get isConfigured => appId != 0 && appSign.isNotEmpty;

  /// Notification channel for incoming-call push (ZEGOCLOUD's offline-push,
  /// ZPNs) while the app is backgrounded or terminated.
  static const String notificationChannelId = 'connectcall_calls';
  static const String notificationChannelName = 'Incoming Calls';
}
