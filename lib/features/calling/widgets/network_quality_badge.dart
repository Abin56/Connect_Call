import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/network_quality.dart';

/// Small network-quality pill shown during a call, driven by ZEGOCLOUD's
/// own per-stream quality notifier instead of a separate network test.
/// Purely informational -- never interrupts the call.
///
/// Passed as [ZegoUIKitPrebuiltCallConfig.foreground] from [buildCallConfig]
/// so it survives call minimize/restore.
class NetworkQualityBadge extends StatelessWidget {
  const NetworkQualityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Offset to clear ZEGOCLOUD's own top menu bar (~96px tall by default)
    // instead of sitting under its title text.
    return Positioned(
      top: MediaQuery.of(context).padding.top + 104,
      left: 12,
      child: ValueListenableBuilder<ZegoUIKitPublishStreamQuality>(
        valueListenable: ZegoUIKit().getAudioVideoQualityNotifier(null),
        builder: (context, quality, _) {
          final level = quality.level.toNetworkQuality();
          return _Pill(level: level);
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final NetworkQuality level;

  const _Pill({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: level.color),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
