import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'widgets/network_quality_badge.dart';

/// Builds the [ZegoUIKitPrebuiltCallConfig] used for the live call screen,
/// for both caller/callee and 1-to-1/group calls.
///
/// Referenced from the invitation service's `requireConfig` callback in
/// [CallingService] rather than pushed as a screen directly -- the
/// invitation service owns call routing end to end.
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

  // Screen sharing only makes sense for video calls, so append it to
  // whichever button list the group/1-to-1 factory above already set up.
  if (isVideoCall) {
    config.bottomMenuBar.buttons = [
      ...config.bottomMenuBar.buttons,
      ZegoCallMenuBarButtonName.toggleScreenSharingButton,
    ];
  }

  // config.foreground survives minimize/restore, unlike a widget pushed
  // separately.
  config.foreground = const NetworkQualityBadge();

  return config;
}
