import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/features/calling/call_config_builder.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

void main() {
  group('buildCallConfig screen sharing', () {
    // Screen sharing is turned off: it hits a bug in the Zego plugin
    // that freezes the call screen.
    test('video calls do not get the screen-sharing button', () {
      final config = buildCallConfig(
        isVideoCall: true,
        onDurationUpdate: (_) {},
      );

      expect(
        config.bottomMenuBar.buttons,
        isNot(contains(ZegoCallMenuBarButtonName.toggleScreenSharingButton)),
      );
    });

    test('audio calls do not get the screen-sharing button', () {
      final config = buildCallConfig(
        isVideoCall: false,
        onDurationUpdate: (_) {},
      );

      expect(
        config.bottomMenuBar.buttons,
        isNot(contains(ZegoCallMenuBarButtonName.toggleScreenSharingButton)),
      );
    });

    test('group video calls also do not get the screen-sharing button', () {
      final config = buildCallConfig(
        isVideoCall: true,
        isGroupCall: true,
        onDurationUpdate: (_) {},
      );

      expect(
        config.bottomMenuBar.buttons,
        isNot(contains(ZegoCallMenuBarButtonName.toggleScreenSharingButton)),
      );
    });
  });

  group('buildCallConfig group vs 1-to-1 (Bonus 7)', () {
    test('defaults to the 1-to-1 layout', () {
      final oneOnOne = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
      final config = buildCallConfig(
        isVideoCall: true,
        onDurationUpdate: (_) {},
      );

      expect(
        config.layout.runtimeType,
        oneOnOne.layout.runtimeType,
      );
    });

    test('isGroupCall selects the group layout', () {
      final group = ZegoUIKitPrebuiltCallConfig.groupVideoCall();
      final config = buildCallConfig(
        isVideoCall: true,
        isGroupCall: true,
        onDurationUpdate: (_) {},
      );

      expect(config.layout.runtimeType, group.layout.runtimeType);
      expect(config.topMenuBar.isVisible, isTrue);
    });

    test('duration display and callback are always wired', () {
      var updated = false;
      final config = buildCallConfig(
        isVideoCall: true,
        isGroupCall: true,
        onDurationUpdate: (_) => updated = true,
      );

      expect(config.duration.isVisible, isTrue);
      config.duration.onDurationUpdate?.call(Duration.zero);
      expect(updated, isTrue);
    });
  });
}
