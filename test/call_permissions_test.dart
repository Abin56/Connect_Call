import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/core/utils/call_permissions.dart';

void main() {
  group('CallPermissionCheck.isGranted', () {
    test('audio call: granted mic, no camera required -> granted', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.granted,
      );
      expect(check.isGranted, isTrue);
      expect(check.needsCamera, isFalse);
    });

    test('audio call: denied mic -> not granted', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.denied,
      );
      expect(check.isGranted, isFalse);
      expect(check.isPermanentlyDenied, isFalse);
    });

    test('video call: mic + camera granted -> granted', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.granted,
        camera: SinglePermissionState.granted,
      );
      expect(check.isGranted, isTrue);
    });

    test('video call: camera missing only -> not granted, camera flagged', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.granted,
        camera: SinglePermissionState.denied,
      );
      expect(check.isGranted, isFalse);
      expect(check.isMissingCamera, isTrue);
      expect(check.isMissingMicrophone, isFalse);
    });

    test('video call: mic missing only -> not granted, mic flagged', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.denied,
        camera: SinglePermissionState.granted,
      );
      expect(check.isGranted, isFalse);
      expect(check.isMissingMicrophone, isTrue);
      expect(check.isMissingCamera, isFalse);
    });

    test('video call: both missing -> not granted, both flagged', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.denied,
        camera: SinglePermissionState.denied,
      );
      expect(check.isGranted, isFalse);
      expect(check.isMissingMicrophone, isTrue);
      expect(check.isMissingCamera, isTrue);
    });

    test('permanently denied mic -> isPermanentlyDenied true', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.permanentlyDenied,
      );
      expect(check.isPermanentlyDenied, isTrue);
      expect(check.isGranted, isFalse);
    });

    test('permanently denied camera (mic granted) -> isPermanentlyDenied true', () {
      const check = CallPermissionCheck(
        microphone: SinglePermissionState.granted,
        camera: SinglePermissionState.permanentlyDenied,
      );
      expect(check.isPermanentlyDenied, isTrue);
    });
  });
}
