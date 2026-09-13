// Checks that error states use the shared AppError widget with a working
// retry button, instead of just a plain error Text.
//
// Doesn't pump a full ProfileScreen/HomeTab since both need
// Firebase.initializeApp, which isn't available in tests (see
// widget_test.dart). Tests AppError and the provider-level retry directly instead.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/core/widgets/app_error.dart';
import 'package:sankar_group/models/call_model.dart';
import 'package:sankar_group/providers/call_history_provider.dart';

void main() {
  testWidgets('AppError shows a Retry button only when onRetry is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppError(message: 'Unable to load profile'),
      ),
    );
    expect(find.text('Unable to load profile'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('AppError Retry button invokes onRetry when tapped', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppError(
          message: 'Unable to load call history',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  test('callHistoryProvider error is observable and invalidate() re-runs it', () async {
    var callCount = 0;
    final container = ProviderContainer(
      overrides: [
        callHistoryProvider.overrideWith((ref) {
          callCount++;
          if (callCount == 1) {
            return Stream<List<CallModel>>.error('boom');
          }
          return Stream.value(<CallModel>[]);
        }),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(callHistoryProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().hasError, isTrue);

    // Mimics AppError's onRetry: () => ref.invalidate(callHistoryProvider).
    container.invalidate(callHistoryProvider);
    await Future<void>.delayed(Duration.zero);

    expect(sub.read().value, isEmpty);
    expect(callCount, 2);
  });
}
