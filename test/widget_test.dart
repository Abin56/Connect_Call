// Basic smoke test: the splash screen renders its branding while waiting
// on the auth state stream. A full app pump isn't used here since that
// requires Firebase.initializeApp, which isn't available in the test
// environment.

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

    // Let the intro animation and its post-settle delay finish so no
    // timers are left pending when the test tears down. There's no
    // Firebase-backed auth state in this test, so navigation never
    // fires -- just enough time needs to pass for the splash's own
    // internal timers to complete.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
