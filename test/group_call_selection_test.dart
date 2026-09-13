import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/models/user_model.dart';
import 'package:sankar_group/providers/group_call_selection_provider.dart';

UserModel _user(String id, String name) =>
    UserModel(id: id, name: name, email: '$id@example.com');

void main() {
  group('groupCallSelectionProvider', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(groupCallSelectionProvider), isEmpty);
    });

    test('toggle adds a user not yet selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(groupCallSelectionProvider.notifier)
          .toggle(_user('alice', 'Alice'));

      expect(
        container.read(groupCallSelectionProvider).map((u) => u.id),
        ['alice'],
      );
    });

    test('toggle removes a user already selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(groupCallSelectionProvider.notifier);
      final alice = _user('alice', 'Alice');

      notifier.toggle(alice);
      notifier.toggle(alice);

      expect(container.read(groupCallSelectionProvider), isEmpty);
    });

    test('remove drops a user by id regardless of toggle history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(groupCallSelectionProvider.notifier);

      notifier.toggle(_user('alice', 'Alice'));
      notifier.toggle(_user('bob', 'Bob'));
      notifier.remove('alice');

      expect(
        container.read(groupCallSelectionProvider).map((u) => u.id),
        ['bob'],
      );
    });

    test('clear empties the selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(groupCallSelectionProvider.notifier);

      notifier.toggle(_user('alice', 'Alice'));
      notifier.toggle(_user('bob', 'Bob'));
      notifier.clear();

      expect(container.read(groupCallSelectionProvider), isEmpty);
    });

    test('minGroupCallInvitees requires at least 2 invitees', () {
      // A 3-person call is the initiator + 2 invitees, so the UI gate
      // (selected.length >= minGroupCallInvitees) must require 2, not 1.
      expect(minGroupCallInvitees, 2);
    });
  });
}
