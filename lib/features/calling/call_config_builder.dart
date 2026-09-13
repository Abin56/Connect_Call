import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'widgets/network_quality_badge.dart';

/// Builds the call screen config for both caller and callee, and for
/// 1-to-1 or group calls.
///
/// [CallingService] hands this to the invitation service's `requireConfig`
/// callback instead of us pushing a screen ourselves -- the invitation
/// service is in charge of call routing from start to finish.
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

  // Video calls start on speaker; voice calls stay on the earpiece.
  config.useSpeakerWhenJoining = isVideoCall;

  // Screen sharing is turned off on purpose: it hits a bug in the Zego
  // plugin that freezes the call screen once you grant capture permission.
  config.bottomMenuBar.buttons = isVideoCall
      ? const [
          ZegoCallMenuBarButtonName.toggleCameraButton,
          ZegoCallMenuBarButtonName.toggleMicrophoneButton,
          ZegoCallMenuBarButtonName.hangUpButton,
          ZegoCallMenuBarButtonName.switchAudioOutputButton,
          ZegoCallMenuBarButtonName.switchCameraButton,
        ]
      : const [
          ZegoCallMenuBarButtonName.toggleMicrophoneButton,
          ZegoCallMenuBarButtonName.hangUpButton,
          ZegoCallMenuBarButtonName.switchAudioOutputButton,
        ];
  config.bottomMenuBar.maxCount = config.bottomMenuBar.buttons.length;

  // Setting foreground here means it survives minimize/restore, unlike a
  // widget we'd push separately.
  config.foreground = const NetworkQualityBadge();

  return config;
}
