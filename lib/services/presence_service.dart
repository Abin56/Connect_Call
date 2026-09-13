import 'package:flutter/widgets.dart';

import 'user_service.dart';

/// Keeps a signed-in user's Firestore `isOnline` flag in sync with whether
/// the app is in the foreground or background, so people don't stay stuck
/// showing "online" after backgrounding or closing the app.
///
/// [AppLifecycleState.detached] isn't guaranteed to fire on a hard kill or
/// crash -- there's no reliable way to catch that from the client.
/// [resumed]/[paused] cover the common case of backgrounding the app,
/// which is what really matters for the online/offline sections on the
/// contacts screen.
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
    // Best effort: presence is just a nice-to-have, not worth erroring over.
    _userService.setOnlineStatus(userId, isOnline).catchError((_) {});
  }
}
