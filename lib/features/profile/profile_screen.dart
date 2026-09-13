import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/user_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../blocked_users/blocked_users_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final GlobalKey? appearanceKey;
  final GlobalKey? blockedUsersKey;

  const ProfileScreen({super.key, this.appearanceKey, this.blockedUsersKey});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: 'Unable to load profile',
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Glow treatment matches Home's call CTA and the auth screens.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppGradients.darkGlow()
                        : AppGradients.lightFeatured,
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        name: user.name,
                        imageUrl: user.profileImage,
                        radius: 48,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        user.name,
                        style: isDark
                            ? AppTextStyles.heading2OnDark
                            : AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: isDark
                            ? AppTextStyles.bodyMutedOnDark
                            : AppTextStyles.bodyMuted,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.onlineColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: isDark
                                ? AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                  )
                                : AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Appearance',
                          style: AppTextStyles.heading3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ThemeModeSelector(key: appearanceKey),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Privacy', style: AppTextStyles.heading3),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        key: blockedUsersKey,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.lgAll,
                          ),
                          leading: const Icon(Icons.block_outlined),
                          title: const Text('Blocked users'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BlockedUsersScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Account', style: AppTextStyles.heading3),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Logout',
                        isDanger: true,
                        onPressed: () => _logout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// System / Light / Dark segmented picker, backed by [themeModeProvider].
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector({super.key});

  static const _options = [
    (mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto),
    (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode_outlined),
    (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            for (final option in _options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _ThemeOptionTile(
                    label: option.label,
                    icon: option.icon,
                    selected: current == option.mode,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(option.mode),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? scheme.primary : null,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
