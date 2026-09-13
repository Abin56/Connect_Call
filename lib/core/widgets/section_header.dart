import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// A small label introducing a section of a list, like "Online" or
/// "Today", with an optional widget on the trailing side (a count, an action).
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.heading3),
        ?trailing,
      ],
    );
  }
}
