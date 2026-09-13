import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// A full-space loading spinner, used for the loading state on async screens.
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: AppTextStyles.bodyMuted),
          ],
        ],
      ),
    );
  }
}
