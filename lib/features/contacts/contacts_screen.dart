import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radius.dart';
import '../../core/widgets/app_alert_dialog.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/user_tile.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/user_provider.dart';
import '../calling/call_initiator.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    UserModel peer,
  ) async {
    final confirmed = await AppAlertDialog.confirm(
      context,
      icon: Icons.block_rounded,
      title: 'Block user?',
      message:
          '${peer.name} won\'t be able to call you, and you won\'t be able to call them. Your existing call history will be kept.',
      confirmLabel: 'Block',
    );
    if (!confirmed) return;

    final me = ref.read(authStateProvider).value;
    if (me == null) return;

    try {
      await ref.read(blockServiceProvider).blockUser(me.uid, peer.id);
    } catch (error, stackTrace) {
      debugPrint('ContactsScreen: failed to block user: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t block this user. Please try again.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${peer.name} has been blocked.')));
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    UserModel peer,
  ) async {
    final me = ref.read(authStateProvider).value;
    if (me == null) return;

    try {
      await ref.read(blockServiceProvider).unblockUser(me.uid, peer.id);
    } catch (error, stackTrace) {
      debugPrint('ContactsScreen: failed to unblock user: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t unblock this user. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredContacts = ref.watch(filteredContactsProvider);
    final blockedIds = ref.watch(blockedIdsProvider).value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                return TextField(
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: Icon(
                      Icons.search,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.smAll,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.smAll,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(contactSearchQueryProvider.notifier)
                      .update(value),
                );
              },
            ),
          ),
        ),
      ),
      body: filteredContacts.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: 'Unable to load contacts',
          onRetry: () => ref.invalidate(contactsProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            final hasSearchQuery = ref
                .watch(contactSearchQueryProvider)
                .trim()
                .isNotEmpty;
            return EmptyState(
              icon: hasSearchQuery ? Icons.search_off : Icons.people_outline,
              message: hasSearchQuery
                  ? 'No results for your search'
                  : 'No contacts yet',
            );
          }

          final active = users.where((u) => !blockedIds.contains(u.id));
          final online = active.where((u) => u.isOnline).toList();
          final offline = active.where((u) => !u.isOnline).toList();
          final blocked = users.where((u) => blockedIds.contains(u.id)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (online.isNotEmpty) ...[
                SectionHeader(label: 'Online (${online.length})'),
                const SizedBox(height: 10),
                for (final user in online) ...[
                  UserTile(
                    user: user,
                    onAudioCall: () =>
                        startCall(context, ref, user, isVideoCall: false),
                    onVideoCall: () =>
                        startCall(context, ref, user, isVideoCall: true),
                    onBlock: () => _confirmBlock(context, ref, user),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
              ],
              if (offline.isNotEmpty) ...[
                const SectionHeader(label: 'Others'),
                const SizedBox(height: 10),
                for (final user in offline) ...[
                  UserTile(
                    user: user,
                    onAudioCall: () =>
                        startCall(context, ref, user, isVideoCall: false),
                    onVideoCall: () =>
                        startCall(context, ref, user, isVideoCall: true),
                    onBlock: () => _confirmBlock(context, ref, user),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
              ],
              if (blocked.isNotEmpty) ...[
                SectionHeader(label: 'Blocked (${blocked.length})'),
                const SizedBox(height: 10),
                for (final user in blocked) ...[
                  UserTile(
                    user: user,
                    isBlocked: true,
                    onUnblock: () => _unblock(context, ref, user),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
