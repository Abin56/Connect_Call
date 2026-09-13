import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// "02:35" for calls under an hour, "1:02:35" for longer ones.
  static String duration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) return '$hours:$mm:$ss';
    return '$mm:$ss';
  }

  /// "Today, 11:45 AM" / "Yesterday, 6:20 PM" / "Jan 4, 6:20 PM".
  static String callTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final time = DateFormat('h:mm a').format(dateTime);

    if (date == today) return 'Today, $time';
    if (date == yesterday) return 'Yesterday, $time';
    return '${DateFormat('MMM d').format(dateTime)}, $time';
  }
}
