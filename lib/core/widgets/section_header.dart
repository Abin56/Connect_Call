import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Small label used to introduce a grouped section of a list (e.g. "Online",
/// "Today"), with an optional trailing widget (a count, an action).
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
