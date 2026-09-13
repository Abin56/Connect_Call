import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether a given user has completed (or skipped) the Home
/// feature tour, so it only ever shows once per user. Keyed per-uid so
/// state doesn't leak between accounts on a shared device.
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
