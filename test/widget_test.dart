// A smoke test: checks the splash screen shows its branding while it
// waits on auth state. Doesn't pump a full app since that needs
// Firebase.initializeApp, which isn't available in tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sankar_group/features/splash/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SplashScreen())),
    );

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    expect(
      richTexts.map((w) => w.text.toPlainText()),
      contains('SANKAR GROUP'),
    );
    expect(find.text('CONNECTCALL'), findsOneWidget);

    // Let the intro animation and its settle delay finish so no timers
    // are still pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
