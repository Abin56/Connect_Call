/// ZEGOCLOUD project credentials.
///
/// These are passed in at build/run time via --dart-define so the AppID and
/// AppSign never get hardcoded into source control. See README for the
/// exact `flutter run` command.
///
/// For a production app the AppSign would be exchanged for a short-lived
/// token from a server (ZEGOCLOUD's token server sample), since the sign
/// itself is a long-lived secret. For this interview/demo project we use the
/// AppID + AppSign directly, which is ZEGOCLOUD's documented "quick start"
/// authentication mode.
class ZegoConstants {
  ZegoConstants._();

  static const int appId = int.fromEnvironment('ZEGO_APP_ID');

  static const String appSign = String.fromEnvironment('ZEGO_APP_SIGN');

  static bool get isConfigured => appId != 0 && appSign.isNotEmpty;

  /// Android notification channel used for incoming-call push notifications
  /// delivered via ZEGOCLOUD's offline-push (ZPNs, backed by FCM on Android
  /// and APNs+VoIP on iOS) while the app is backgrounded or terminated. Kept
  /// here alongside the other ZEGOCLOUD wiring since it's part of the same
  /// `ZegoUIKitPrebuiltCallInvitationService` setup.
  static const String notificationChannelId = 'connectcall_calls';
  static const String notificationChannelName = 'Incoming Calls';
}
