import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/theme_service.dart';

final themeServiceProvider = Provider<ThemeService>((ref) => ThemeService());

/// The app's active [ThemeMode] (System/Light/Dark). Loaded from local
/// storage on startup, and saved back whenever the user changes it in
/// Settings. Defaults to [ThemeMode.system] while the stored value is
/// loading, and again if nothing was ever saved.
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() {
    return ref.read(themeServiceProvider).loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(themeServiceProvider).saveThemeMode(mode);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
