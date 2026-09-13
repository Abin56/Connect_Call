import 'package:permission_handler/permission_handler.dart';

/// Simplifies permission_handler's more detailed [PermissionStatus] down
/// to the three outcomes the call-permission flow actually cares about.
enum SinglePermissionState { granted, denied, permanentlyDenied }

/// The mic/camera permissions a call needs, plus which ones are missing,
/// so the UI can ask for just "Camera access", just "Microphone access",
/// or both instead of always asking for everything.
class CallPermissionCheck {
  final SinglePermissionState microphone;
  final SinglePermissionState? camera;

  const CallPermissionCheck({required this.microphone, this.camera});

  bool get needsCamera => camera != null;

  bool get isGranted =>
      microphone == SinglePermissionState.granted &&
      (camera == null || camera == SinglePermissionState.granted);

  bool get isPermanentlyDenied =>
      microphone == SinglePermissionState.permanentlyDenied ||
      camera == SinglePermissionState.permanentlyDenied;

  bool get needsMicrophone => microphone != SinglePermissionState.granted;
  bool get isMissingCamera => camera == SinglePermissionState.denied;
  bool get isMissingMicrophone =>
      microphone == SinglePermissionState.denied;
}

SinglePermissionState _toState(PermissionStatus status) {
  if (status.isGranted) return SinglePermissionState.granted;
  if (status.isPermanentlyDenied || status.isRestricted) {
    return SinglePermissionState.permanentlyDenied;
  }
  return SinglePermissionState.denied;
}

/// Checks the current mic/camera permission state without prompting the
/// OS, so callers can decide if a native dialog is even needed.
Future<CallPermissionCheck> checkCallPermissions({
  required bool needsCamera,
}) async {
  final micStatus = await Permission.microphone.status;
  final camStatus = needsCamera ? await Permission.camera.status : null;
  return CallPermissionCheck(
    microphone: _toState(micStatus),
    camera: camStatus == null ? null : _toState(camStatus),
  );
}

/// Triggers the native OS prompt for whichever of mic/camera isn't
/// already granted. Callers should show their own rationale first -- this
/// function never shows any UI itself.
Future<CallPermissionCheck> requestCallPermissions({
  required bool needsCamera,
}) async {
  final statuses = await [
    Permission.microphone,
    if (needsCamera) Permission.camera,
  ].request();

  return CallPermissionCheck(
    microphone: _toState(statuses[Permission.microphone]!),
    camera: needsCamera ? _toState(statuses[Permission.camera]!) : null,
  );
}
