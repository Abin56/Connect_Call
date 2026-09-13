import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'widgets/network_quality_badge.dart';

/// Builds the [ZegoUIKitPrebuiltCallConfig] used for the live call screen,
/// for both caller and callee, and for both 1-to-1 and group calls (see
/// [isGroupCall]). Referenced from the invitation service's `requireConfig`
/// callback in [CallingService] rather than pushed as a screen directly --
/// the invitation service owns call routing end to end.
ZegoUIKitPrebuiltCallConfig buildCallConfig({
  required bool isVideoCall,
  required void Function(Duration duration) onDurationUpdate,
  bool isGroupCall = false,
}) {
  final config = isGroupCall
      ? (isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
            : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
      : (isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());

  config.duration.isVisible = true;
  config.duration.onDurationUpdate = onDurationUpdate;

  // Screen sharing (Bonus 8) is a built-in bottom-menu-bar button
  // (ZegoCallMenuBarButtonName.toggleScreenSharingButton) rather than a
  // custom media pipeline -- only meaningful for video calls, so it's
  // appended to whichever button list the group/1-to-1 factory above
  // already set up.
  if (isVideoCall) {
    config.bottomMenuBar.buttons = [
      ...config.bottomMenuBar.buttons,
      ZegoCallMenuBarButtonName.toggleScreenSharingButton,
    ];
  }

  // config.foreground sits in the same Stack as the rest of the call UI and
  // survives minimize/restore, unlike a widget pushed separately -- see
  // NetworkQualityBadge for why this reads ZEGOCLOUD's own quality notifier
  // instead of running a custom network test.
  config.foreground = const NetworkQualityBadge();

  return config;
}
