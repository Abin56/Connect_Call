import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/call_model.dart';
import '../../../providers/auth_provider.dart';

class CallHistoryTile extends ConsumerWidget {
  final CallModel call;

  const CallHistoryTile({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final isOutgoing = uid != null && call.isOutgoingFor(uid);
    final otherPartyName = isOutgoing ? call.receiverName : call.callerName;
    final isMissed =
        call.status == CallStatus.missed ||
        call.status == CallStatus.rejected ||
        call.status == CallStatus.failed ||
        call.status == CallStatus.disconnected;
    final isVideo = call.callType == CallType.video;
    final errorColor = Theme.of(context).colorScheme.error;
    final secondary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final tertiary = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.4);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMissed
                    ? errorColor.withValues(alpha: 0.14)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(
                isMissed
                    ? _statusIcon(call.status)
                    : (isVideo ? Icons.videocam_rounded : Icons.call_rounded),
                color: isMissed
                    ? errorColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName,
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isOutgoing ? Icons.call_made : Icons.call_received,
                        size: 14,
                        color: isMissed ? errorColor : tertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          Formatters.callTimestamp(call.startedAt),
                          style: AppTextStyles.caption.copyWith(
                            color: isMissed ? errorColor : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isMissed
                  ? _statusLabel(call.status)
                  : Formatters.duration(call.durationInSeconds),
              style: AppTextStyles.caption.copyWith(
                color: isMissed ? errorColor : secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.missed:
        return Icons.call_missed_rounded;
      case CallStatus.rejected:
        return Icons.block_rounded;
      case CallStatus.failed:
        return Icons.error_outline_rounded;
      case CallStatus.disconnected:
        return Icons.wifi_off_rounded;
      default:
        return Icons.call_rounded;
    }
  }

  String _statusLabel(CallStatus status) {
    switch (status) {
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.rejected:
        return 'Declined';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.disconnected:
        return 'Disconnected';
      default:
        return '';
    }
  }
}
