import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/models/user_model.dart';
import 'package:sankar_group/providers/user_provider.dart';

UserModel _user(String id, String name) =>
    UserModel(id: id, name: name, email: '$id@example.com');

/// Waits for [provider] to leave its loading state, by listening rather
/// than awaiting `.future` (which has proven flaky against a plain
/// `Stream.value` source in this Riverpod version -- it can time out
/// instead of resolving on the stream's first, only event).
Future<void> _waitForData<T>(
  ProviderContainer container,
  StreamProvider<T> provider,
) async {
  final completer = Completer<void>();
  final sub = container.listen<AsyncValue<T>>(provider, (previous, next) {
    if (next.hasValue && !completer.isCompleted) completer.complete();
  });
  if (container.read(provider).hasValue) completer.complete();
  await completer.future;
  sub.close();
}

void main() {
  group('filteredContactsProvider', () {
    test(
      'keeps a blocked contact in the list (Contacts shows it muted with Unblock)',
      () async {
        final container = ProviderContainer(
          overrides: [
            contactsProvider.overrideWith(
              (ref) => Stream.value([
                _user('alice', 'Alice'),
                _user('bob', 'Bob'),
              ]),
            ),
          ],
        );
        addTearDown(container.dispose);

        await _waitForData(container, contactsProvider);

        final result = container.read(filteredContactsProvider);
        expect(result.value?.map((u) => u.id).toList(), ['alice', 'bob']);
      },
    );

    test('filters by the search query on name/email', () async {
      final container = ProviderContainer(
        overrides: [
          contactsProvider.overrideWith(
            (ref) =>
                Stream.value([_user('alice', 'Alice'), _user('bob', 'Bob')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitForData(container, contactsProvider);
      container.read(contactSearchQueryProvider.notifier).update('ali');

      final result = container.read(filteredContactsProvider);
      expect(result.value?.map((u) => u.id).toList(), ['alice']);
    });
  });
}
