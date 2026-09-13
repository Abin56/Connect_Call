import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/user_model.dart';
import '../../../providers/recent_contacts_provider.dart';
import '../../../providers/user_provider.dart';

/// "Frequently called" row on Home: up to 5 people the user calls most,
/// derived from call history, with a tap-to-call button each.
/// Renders nothing when there's no history yet rather than an empty section.
class RecentContactsSection extends ConsumerWidget {
  final void Function(UserModel user, {required bool isVideoCall}) onCall;

  const RecentContactsSection({super.key, required this.onCall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentContactsProvider);
    final contactsAsync = ref.watch(contactsProvider);

    final recent = recentAsync.value;
    final contactsById = {
      for (final user in contactsAsync.value ?? const <UserModel>[])
        user.id: user,
    };

    if (recent == null || recent.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final contact = recent[index];
          final user = contactsById[contact.userId];
          return _RecentContactCard(
            name: contact.name,
            callCount: contact.callCount,
            profileImage: user?.profileImage,
            onAudioCall: user == null
                ? null
                : () => onCall(user, isVideoCall: false),
            onVideoCall: user == null
                ? null
                : () => onCall(user, isVideoCall: true),
          );
        },
      ),
    );
  }
}

class _RecentContactCard extends StatelessWidget {
  final String name;
  final int callCount;
  final String? profileImage;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;

  const _RecentContactCard({
    required this.name,
    required this.callCount,
    required this.profileImage,
    required this.onAudioCall,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    // Slightly elevated card so "frequently called" stands out a bit
    // without competing with the Home CTA's red-glow treatment.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.elevated : AppColors.softCard,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(name: name, imageUrl: profileImage, radius: 22),
          const SizedBox(height: 4),
          Text(
            name.split(' ').first,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            callCount == 1 ? '1 call' : '$callCount calls',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniCallButton(icon: Icons.call_rounded, onTap: onAudioCall),
              const SizedBox(width: 6),
              _MiniCallButton(icon: Icons.videocam_rounded, onTap: onVideoCall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniCallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final red = Theme.of(context).colorScheme.primary;
    return Material(
      color: disabled ? red.withValues(alpha: 0.35) : red,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: disabled
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }
}
