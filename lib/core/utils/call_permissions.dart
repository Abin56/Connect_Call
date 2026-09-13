import 'package:permission_handler/permission_handler.dart';

/// Collapses [permission_handler]'s finer-grained [PermissionStatus] down to
/// the three outcomes the call-permission flow actually branches on.
enum SinglePermissionState { granted, denied, permanentlyDenied }

/// Combined mic/camera requirement for a call, plus which individual
/// permissions are missing, so the UI can show "Camera access",
/// "Microphone access", or the combined copy instead of always asking for both.
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

/// Reads current mic/camera permission state *without* prompting the OS,
/// so callers can decide whether a native dialog is even needed.
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

/// Fires the native OS permission prompt(s) for whichever of mic/camera
/// aren't already granted. Callers should show a rationale first -- this
/// never shows any UI of its own.
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
