import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user_model.dart';
import '../../providers/group_call_selection_provider.dart';
import '../../providers/user_provider.dart';
import 'group_call_initiator.dart';

/// Pick 2 or more contacts, then start an audio or video group call.
/// This screen only handles picking people -- [startGroupCall] sends the
/// actual invitation.
class GroupCallSelectContactsScreen extends ConsumerWidget {
  const GroupCallSelectContactsScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref, {
    required bool isVideoCall,
  }) async {
    final selected = ref.read(groupCallSelectionProvider);
    if (selected.length < minGroupCallInvitees) return;

    final sent = await startGroupCall(
      context,
      ref,
      selected,
      isVideoCall: isVideoCall,
    );
    if (sent) {
      ref.read(groupCallSelectionProvider.notifier).clear();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final selected = ref.watch(groupCallSelectionProvider);
    final selectedIds = selected.map((u) => u.id).toSet();
    final canStart = selected.length >= minGroupCallInvitees;

    return Scaffold(
      appBar: AppBar(title: const Text('New group call')),
      body: Column(
        children: [
          if (selected.isNotEmpty) _SelectedStrip(selected: selected),
          Expanded(
            child: contactsAsync.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppError(
                message: 'Unable to load contacts',
                onRetry: () => ref.invalidate(contactsProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    message: 'No contacts yet',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _SelectableContactTile(
                      user: user,
                      selected: selectedIds.contains(user.id),
                      onTap: () => ref
                          .read(groupCallSelectionProvider.notifier)
                          .toggle(user),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canStart
                          ? () => _start(context, ref, isVideoCall: false)
                          : null,
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Audio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canStart
                          ? () => _start(context, ref, isVideoCall: true)
                          : null,
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Video'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedStrip extends ConsumerWidget {
  final List<UserModel> selected;

  const _SelectedStrip({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected.length < minGroupCallInvitees
                ? 'Select at least ${minGroupCallInvitees - selected.length} more'
                : '${selected.length} selected',
            style: AppTextStyles.caption.copyWith(
              color: isDark
                  ? AppColorsDark.textSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selected.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final user = selected[index];
                return _SelectedChip(
                  user: user,
                  onRemove: () => ref
                      .read(groupCallSelectionProvider.notifier)
                      .remove(user.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final UserModel user;
  final VoidCallback onRemove;

  const _SelectedChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(name: user.name, imageUrl: user.profileImage, radius: 24),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user.name.split(' ').first,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _SelectableContactTile extends StatelessWidget {
  final UserModel user;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableContactTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.1)
          : Theme.of(context).cardTheme.color,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                name: user.name,
                imageUrl: user.profileImage,
                isOnline: user.isOnline,
                radius: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  user.name,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selected
                    ? Icon(
                        Icons.check_circle,
                        key: const ValueKey('checked'),
                        color: scheme.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('unchecked'),
                        color: scheme.onSurface.withValues(alpha: 0.3),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
