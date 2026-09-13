import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether a user has finished (or skipped) the Home feature
/// tour, so it only shows once per person. Keyed by user id so accounts
/// don't share tour progress on the same device.
class TourService {
  static const _prefsKeyPrefix = 'home_tour_completed_';

  Future<bool> hasCompletedTour(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsKeyPrefix$uid') ?? false;
  }

  Future<void> markTourCompleted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsKeyPrefix$uid', true);
  }
}

/// A shared gate that other first-run prompts (like the notification
/// permission dialog) wait on, so they never show up on top of the Home
/// tour's coach-marks.
///
/// [markPending] runs as soon as we know Home is about to appear (right
/// when calling finishes starting up in `main.dart`), before [HomeScreen]
/// has even decided whether a tour is needed -- otherwise a prompt could
/// sneak in ahead of that decision. [HomeScreen] then either calls
/// [resolvePending] right away (tour already done) or [start]s the tour
/// and calls [finish] once the user finishes or skips it. Everything else
/// just waits on [whenIdle].
class TourGate {
  TourGate._();

  static Completer<void>? _active;

  static void markPending() => _active ??= Completer<void>();

  static void resolvePending() {
    if (_active != null && !_active!.isCompleted) finish();
  }

  static void start() => _active ??= Completer<void>();

  static void finish() {
    _active?.complete();
    _active = null;
  }

  static Future<void> whenIdle() => _active?.future ?? Future.value();
}
