import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/user_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/user_provider.dart';

/// Lists everyone the signed-in user has blocked, each with an Unblock
/// action. Reached from Profile > Privacy > Blocked users.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String blockedUserId,
  ) async {
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    try {
      await ref.read(blockServiceProvider).unblockUser(me.uid, blockedUserId);
    } catch (error, stackTrace) {
      debugPrint(
        'BlockedUsersScreen: failed to unblock user: $error\n$stackTrace',
      );
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
    final blockedIdsAsync = ref.watch(blockedIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: blockedIdsAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: 'Unable to load blocked users',
          onRetry: () => ref.invalidate(blockedIdsProvider),
        ),
        data: (blockedIds) {
          if (blockedIds.isEmpty) {
            return const EmptyState(
              icon: Icons.block_outlined,
              message: 'You haven\'t blocked anyone',
            );
          }

          final ids = blockedIds.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ids.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _BlockedUserTile(
                userId: ids[index],
                onUnblock: () => _unblock(context, ref, ids[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends ConsumerWidget {
  final String userId;
  final VoidCallback onUnblock;

  const _BlockedUserTile({required this.userId, required this.onUnblock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (user) {
        // The blocked account may have since been deleted -- show the id
        // rather than hiding the row, since Unblock should still work.
        final name = user?.name ?? 'Unknown user';
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                UserAvatar(
                  name: name,
                  imageUrl: user?.profileImage,
                  radius: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  onPressed: onUnblock,
                  child: const Text('Unblock'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
