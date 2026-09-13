import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'user_avatar.dart';

/// A contact row: avatar, name, online/offline status, and call buttons.
/// Presented as a card so it reads clearly in a list of many.
///
/// [isBlocked] mutes the row (avatar/name/status dimmed, call buttons
/// disabled) and swaps the trailing action from a red "Block" icon button
/// ([onBlock]) to a red-outlined "Unblock" button ([onUnblock]), so a
/// contact can be blocked or unblocked from this same list without needing
/// the separate Blocked Users screen.
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onTap;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final bool isBlocked;

  const UserTile({
    super.key,
    required this.user,
    this.onAudioCall,
    this.onVideoCall,
    this.onTap,
    this.onBlock,
    this.onUnblock,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimOpacity = isBlocked ? 0.45 : 1.0;
    final ringColor = Theme.of(context).colorScheme.outline.withValues(
      alpha: 0.5,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final redColor = isDark ? AppColorsDark.red : AppColors.red;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Opacity(
                opacity: dimOpacity,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 1.5),
                  ),
                  child: UserAvatar(
                    name: user.name,
                    imageUrl: user.profileImage,
                    isOnline: user.isOnline && !isBlocked,
                    radius: 25,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Opacity(
                  opacity: dimOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBlocked) ...[
                            Icon(
                              Icons.block_rounded,
                              size: 12,
                              color: redColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Blocked',
                              style: AppTextStyles.caption.copyWith(
                                color: redColor,
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? context.onlineColor
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.isOnline ? 'Online' : 'Offline',
                              style: AppTextStyles.caption.copyWith(
                                color: user.isOnline
                                    ? context.onlineColor
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isBlocked) ...[
                if (onUnblock != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      foregroundColor: redColor,
                      side: BorderSide(color: redColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll,
                      ),
                    ),
                    onPressed: onUnblock,
                    child: const Text('Unblock'),
                  ),
              ] else ...[
                _CallActionButton(
                  icon: Icons.call_outlined,
                  onPressed: onAudioCall,
                ),
                const SizedBox(width: 8),
                _CallActionButton(
                  icon: Icons.videocam_outlined,
                  onPressed: onVideoCall,
                ),
                if (onBlock != null) ...[
                  const SizedBox(width: 8),
                  _BlockActionButton(onPressed: onBlock),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A 40x40 circular icon button, the shared shell for [_CallActionButton]
/// and [_BlockActionButton] -- a soft tinted-background style (for the
/// secondary Block action) or a solid brand-color style (for the primary
/// call actions), each with a faint matching shadow to lift it off the card.
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color iconColor;
  final bool showShadow;

  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.iconColor,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: iconColor, size: 19),
        ),
      ),
    );
  }
}

class _BlockActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BlockActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final redColor = isDark ? AppColorsDark.red : AppColors.red;
    return _CircleActionButton(
      icon: Icons.block_rounded,
      onPressed: onPressed,
      color: redColor.withValues(alpha: 0.12),
      iconColor: redColor,
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CallActionButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final red = Theme.of(context).colorScheme.primary;
    return _CircleActionButton(
      icon: icon,
      onPressed: onPressed,
      color: disabled ? red.withValues(alpha: 0.35) : red,
      iconColor: disabled ? Colors.white.withValues(alpha: 0.6) : Colors.white,
      showShadow: !disabled,
    );
  }
}
