import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// The look of a [CallControlButton].
enum CallControlVariant {
  /// The default, off/inactive look.
  neutral,

  /// A neutral control that's toggled on (like speaker enabled) — brand color.
  active,

  /// A destructive action, like ending or declining a call.
  danger,

  /// An accept action (answering a call) — brand color, bigger by convention.
  accept,
}

/// A round icon button used on call screens for things like mute,
/// speaker, camera, switch camera, accept, decline, and end call.
/// Can optionally show a text label underneath, like most call UIs do.
class CallControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final CallControlVariant variant;
  final double size;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.variant = CallControlVariant.neutral,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background;
    final Color foreground;
    switch (variant) {
      case CallControlVariant.neutral:
        background = isDark ? AppColorsDark.surfaceMuted : Colors.white24;
        foreground = Colors.white;
      case CallControlVariant.active:
        background = Theme.of(context).colorScheme.primary;
        foreground = Colors.white;
      case CallControlVariant.danger:
        background = isDark ? AppColorsDark.error : AppColors.error;
        foreground = Colors.white;
      case CallControlVariant.accept:
        background = Theme.of(context).colorScheme.primary;
        foreground = Colors.white;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: foreground, size: size * 0.42),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ],
    );
  }
}

/// A rounded pill that groups call controls together at the bottom of a
/// call screen, like the video-call control dock.
class CallControlDock extends StatelessWidget {
  final List<Widget> children;

  const CallControlDock({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: AppRadius.xxlAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}
