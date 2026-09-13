import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/user_avatar.dart';
import '../../providers/call_history_provider.dart';
import '../../providers/user_provider.dart';
import '../calling/call_initiator.dart';
import '../calling/group_call_select_contacts_screen.dart';
import '../history/widgets/call_history_tile.dart';
import '../profile/profile_screen.dart';
import 'widgets/recent_contacts_section.dart';

/// The landing tab: greets the user, gives a quick way into Contacts,
/// and previews recent calls and contacts. The full lists live on their
/// own tabs.
class HomeTab extends ConsumerWidget {
  final VoidCallback onGoToContacts;
  final GlobalKey? startCallKey;
  final GlobalKey? groupCallKey;
  final GlobalKey? recentContactsKey;

  const HomeTab({
    super.key,
    required this.onGoToContacts,
    this.startCallKey,
    this.groupCallKey,
    this.recentContactsKey,
  });

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final historyAsync = ref.watch(callHistoryProvider);
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: profileAsync.maybeWhen(
          data: (user) => user == null
              ? const SizedBox.shrink()
              : InkWell(
                  borderRadius: AppRadius.smAll,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: user.name,
                        imageUrl: user.profileImage,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_greeting(), style: AppTextStyles.caption),
                            Text(
                              user.name.split(' ').first,
                              style: AppTextStyles.heading3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          orElse: () => const Text('ConnectCall'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(callHistoryProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            InkWell(
              borderRadius: AppRadius.smAll,
              onTap: onGoToContacts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Text('Search people', style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dark mode gets a black/red glow; light mode gets a softer
            // white-to-red tint so it doesn't look like a dark hole.
            Builder(
              key: startCallKey,
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppGradients.darkGlow()
                        : AppGradients.lightFeatured,
                    borderRadius: AppRadius.lgAll,
                    border: isDark
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a call',
                        style: isDark
                            ? AppTextStyles.heading3OnDark
                            : AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reach a contact instantly',
                        style: isDark
                            ? AppTextStyles.bodyMutedOnDark
                            : AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.call_outlined,
                              label: 'Audio Call',
                              onTap: onGoToContacts,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.videocam_outlined,
                              label: 'Video Call',
                              onTap: onGoToContacts,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _GroupCallCta(
              key: groupCallKey,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GroupCallSelectContactsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            RecentContactsSection(
              key: recentContactsKey,
              onCall: (user, {required isVideoCall}) =>
                  startCall(context, ref, user, isVideoCall: isVideoCall),
            ),
            const SizedBox(height: 24),
            SectionHeader(label: 'Recent calls'),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoading(),
              ),
              error: (error, _) => AppError(
                message: 'Unable to load call history',
                onRetry: () => ref.invalidate(callHistoryProvider),
              ),
              data: (calls) {
                if (calls.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      icon: Icons.call_outlined,
                      message: 'No call history yet',
                    ),
                  );
                }
                final recent = calls.take(5).toList();
                return Column(
                  children: [
                    for (final call in recent) ...[
                      CallHistoryTile(call: call),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SectionHeader(
              label: 'Contacts',
              trailing: TextButton(
                onPressed: onGoToContacts,
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 12),
            contactsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppLoading(),
              ),
              error: (error, _) => AppError(
                message: 'Unable to load contacts',
                onRetry: () => ref.invalidate(contactsProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      message: 'No contacts yet',
                    ),
                  );
                }
                final preview = users.take(6).toList();
                return SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: preview.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 18),
                    itemBuilder: (context, index) {
                      final user = preview[index];
                      return SizedBox(
                        width: 68,
                        child: InkWell(
                          borderRadius: AppRadius.smAll,
                          onTap: onGoToContacts,
                          child: Column(
                            children: [
                              UserAvatar(
                                name: user.name,
                                imageUrl: user.profileImage,
                                isOnline: user.isOnline,
                                radius: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.name.split(' ').first,
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A quieter card that sits below the main "Start a call" button on
/// purpose -- group calling gets used less than a direct 1-to-1 call.
class _GroupCallCta extends StatelessWidget {
  final VoidCallback onTap;

  const _GroupCallCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isDark ? AppColorsDark.surface : AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New group call', style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(
                      'Call 3 or more people at once',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // A frosted-glass look so it doesn't clash with the card's own red;
    // the tint flips between white and black to stay visible in both themes.
    final labelColor = isDark ? Colors.white : AppColors.nearBlack;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.04),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.redBright,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
