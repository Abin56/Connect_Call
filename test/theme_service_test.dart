import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeService', () {
    test('defaults to system when nothing has been saved', () async {
      final service = ThemeService();
      expect(await service.loadThemeMode(), ThemeMode.system);
    });

    test('persists and reloads light mode', () async {
      final service = ThemeService();
      await service.saveThemeMode(ThemeMode.light);
      expect(await service.loadThemeMode(), ThemeMode.light);
    });

    test('persists and reloads dark mode', () async {
      final service = ThemeService();
      await service.saveThemeMode(ThemeMode.dark);
      expect(await service.loadThemeMode(), ThemeMode.dark);
    });

    test('persists across separate service instances', () async {
      await ThemeService().saveThemeMode(ThemeMode.dark);
      // A fresh instance (e.g. after an app restart) must read the same
      // persisted value rather than any in-memory state on the first one.
      final reloaded = await ThemeService().loadThemeMode();
      expect(reloaded, ThemeMode.dark);
    });

    test('overwriting a saved choice updates what is loaded', () async {
      final service = ThemeService();
      await service.saveThemeMode(ThemeMode.light);
      await service.saveThemeMode(ThemeMode.system);
      expect(await service.loadThemeMode(), ThemeMode.system);
    });
  });
}
