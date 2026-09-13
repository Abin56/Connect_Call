import 'package:flutter/material.dart';

/// A primary action button with a built-in loading spinner, so screens
/// don't have to manually disable the button and swap its child at the same time.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final bool isDanger;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final spinnerColor = isDanger
        ? errorColor
        : outlined
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: spinnerColor,
            ),
          )
        : Text(label);

    if (isDanger) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: errorColor,
          side: BorderSide(color: errorColor.withValues(alpha: 0.6)),
        ),
        child: child,
      );
    }

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
