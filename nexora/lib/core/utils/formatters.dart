import 'package:intl/intl.dart';

/// Formatting helpers used across the app.
abstract final class Formatters {
  /// Relative time: "now", "5m", "2h", "3d", "2w", "4mo", "1y".
  static String timeAgo(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(dateTime);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  /// Compact counts: 1234 -> "1.2K", 2300000 -> "2.3M".
  static String compactCount(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) {
      final v = count / 1000;
      return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}K';
    }
    final v = count / 1000000;
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}M';
  }

  /// Readable date: "12 Mar 2026".
  static String readableDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }
}
