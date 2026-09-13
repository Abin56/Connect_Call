import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/features/contacts/contacts_screen.dart';
import 'package:sankar_group/models/user_model.dart';
import 'package:sankar_group/providers/block_provider.dart';
import 'package:sankar_group/providers/user_provider.dart';

void main() {
  testWidgets('shows "No contacts yet" when there are no contacts at all', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactsProvider.overrideWith((ref) => Stream.value(<UserModel>[])),
          blockedIdsProvider.overrideWith((ref) => Stream.value(<String>{})),
        ],
        child: const MaterialApp(home: ContactsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('No contacts yet'), findsOneWidget);
    expect(find.text('No results for your search'), findsNothing);
  });

  testWidgets(
    'shows "No results for your search" when a search matches nobody',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsProvider.overrideWith(
              (ref) => Stream.value([
                UserModel(id: 'a', name: 'Alice', email: 'a@example.com'),
              ]),
            ),
            blockedIdsProvider.overrideWith((ref) => Stream.value(<String>{})),
          ],
          child: const MaterialApp(home: ContactsScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pump();

      expect(find.text('No results for your search'), findsOneWidget);
      expect(find.text('No contacts yet'), findsNothing);
    },
  );
}
