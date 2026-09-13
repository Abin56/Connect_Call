import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// A centered dialog with an icon up top, used everywhere instead of a
/// plain [AlertDialog] so things like block confirmations and permission
/// prompts all look the same.
///
/// It's just a thin wrapper around [AlertDialog], so it still picks up
/// [ThemeData.dialogTheme] instead of being a fully custom widget.
class AppAlertDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  /// Tints the icon and confirm button red, for things like Block.
  final bool destructive;

  const AppAlertDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.cancelLabel = 'Cancel',
    this.confirmLabel,
    this.onConfirm,
    this.destructive = false,
  });

  /// Shows the dialog, resolving to `true` only if the confirm button was tapped.
  static Future<bool> confirm(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    required String confirmLabel,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        icon: icon,
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        destructive: destructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = destructive
        ? AppColors.red
        : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary);

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.smAll,
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ),
            if (confirmLabel != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: destructive ? AppColors.red : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  child: Text(confirmLabel!),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
