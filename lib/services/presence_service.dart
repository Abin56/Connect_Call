import 'package:flutter/widgets.dart';

import 'user_service.dart';

/// Keeps a signed-in user's Firestore `isOnline` flag in sync with the app's
/// actual foreground/background state, so presence doesn't get stuck
/// "online" after the app is backgrounded, killed, or crashes.
///
/// [AppLifecycleState.detached] fires on a clean app-process teardown but is
/// not guaranteed on a hard kill/crash -- there is no reliable client-side
/// hook for that case. [resumed]/[paused] cover the common backgrounding
/// case, which is what this app's presence indicator mostly needs to be
/// accurate for (contacts screen online/offline sections).
class PresenceService with WidgetsBindingObserver {
  final UserService _userService;

  PresenceService({UserService? userService})
    : _userService = userService ?? UserService();

  String? _userId;
  bool _attached = false;

  void start(String userId) {
    _userId = userId;
    if (!_attached) {
      WidgetsBinding.instance.addObserver(this);
      _attached = true;
    }
    _setOnline(true);
  }

  void stop() {
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
    _userId = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _setOnline(false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _setOnline(bool isOnline) {
    final userId = _userId;
    if (userId == null) return;
    // Best-effort: presence is advisory, never worth surfacing an error for.
    _userService.setOnlineStatus(userId, isOnline).catchError((_) {});
  }
}
