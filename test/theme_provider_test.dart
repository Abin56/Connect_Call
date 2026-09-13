import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('themeModeProvider starts at system by default', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mode = await container.read(themeModeProvider.future);
    expect(mode, ThemeMode.system);
  });

  test('setThemeMode updates state and persists the choice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider).value, ThemeMode.dark);

    // A fresh container simulates an app restart -- it should load the
    // saved choice instead of defaulting back to system.
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    final reloaded = await restarted.read(themeModeProvider.future);
    expect(reloaded, ThemeMode.dark);
  });
}
