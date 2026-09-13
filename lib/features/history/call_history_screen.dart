import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../models/call_model.dart';
import '../../providers/call_history_provider.dart';
import 'widgets/call_history_tile.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  /// Groups [calls] (already newest-first) under "Today" / "Yesterday" /
  /// a formatted date, preserving order within each group.
  static Map<String, List<CallModel>> _groupByDay(List<CallModel> calls) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<CallModel>>{};
    for (final call in calls) {
      final day = DateTime(
        call.startedAt.year,
        call.startedAt.month,
        call.startedAt.day,
      );
      final String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMMM d').format(day);
      }
      groups.putIfAbsent(label, () => []).add(call);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: historyAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: 'Unable to load call history',
          onRetry: () => ref.invalidate(callHistoryProvider),
        ),
        data: (calls) {
          if (calls.isEmpty) {
            return const EmptyState(
              icon: Icons.call_outlined,
              message: 'No call history yet',
            );
          }
          final groups = _groupByDay(calls);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in groups.entries) ...[
                SectionHeader(label: entry.key),
                const SizedBox(height: 10),
                for (final call in entry.value) ...[
                  CallHistoryTile(call: call),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
