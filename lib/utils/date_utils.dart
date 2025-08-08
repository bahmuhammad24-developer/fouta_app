import 'package:intl/intl.dart';

/// Utility functions for formatting dates and times in a user‑friendly,
/// relative manner. These helpers convert a [DateTime] into strings like
/// "Just now", "5 mins ago", "Yesterday", or longer‑scale values such as
/// "3 weeks ago". The thresholds are based on common UX guidelines that
/// favor relative timestamps over absolute dates.
class DateUtilsHelper {
  /// Returns a human‑friendly relative string for the given [date].
  ///
  /// The following rules apply:
  /// * If within 1 minute: "Just now".
  /// * If within an hour: "X mins ago".
  /// * If within 24 hours: "X hours ago".
  /// * If yesterday: "Yesterday".
  /// * If within the last 7 days: weekday name (e.g. "Monday").
  /// * If within the last 30 days: "X week(s) ago".
  /// * If within the last year: month name (e.g. "June").
  /// * Else: "X year(s) ago".
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Handle future dates by flipping the difference and using "in" phrasing.
    if (difference.isNegative) {
      final futureDiff = date.difference(now);
      if (futureDiff.inMinutes < 1) {
        return 'In a moment';
      }
      if (futureDiff.inMinutes < 60) {
        final mins = futureDiff.inMinutes;
        return 'In ${mins} min${mins == 1 ? '' : 's'}';
      }
      if (futureDiff.inHours < 24) {
        final hours = futureDiff.inHours;
        return 'In ${hours} hour${hours == 1 ? '' : 's'}';
      }
      if (futureDiff.inDays == 1) {
        return 'Tomorrow';
      }
      if (futureDiff.inDays < 7) {
        return DateFormat('EEEE').format(date);
      }
      if (futureDiff.inDays < 30) {
        final weeks = futureDiff.inDays ~/ 7;
        return 'In ${weeks} week${weeks == 1 ? '' : 's'}';
      }
      if (futureDiff.inDays < 365) {
        final months = futureDiff.inDays ~/ 30;
        return 'In ${months} month${months == 1 ? '' : 's'}';
      }
      final years = futureDiff.inDays ~/ 365;
      return 'In ${years} year${years == 1 ? '' : 's'}';
    }

    // Less than 1 minute.
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    // Less than 1 hour.
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins} min${mins == 1 ? '' : 's'} ago';
    }
    // Less than 24 hours.
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours} hour${hours == 1 ? '' : 's'} ago';
    }
    // Yesterday.
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    // Within the last 7 days, show weekday name.
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    }
    // Older dates: express in weeks, month name, or years.
    if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '${weeks} week${weeks == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 365) {
      return DateFormat('MMMM').format(date);
    }
    final years = difference.inDays ~/ 365;
    return '${years} year${years == 1 ? '' : 's'} ago';
  }

  /// Formats an absolute date/time for tooltips or accessibility. Returns
  /// a full date and time string like "Jul 31, 2025 5:30 PM".
  static String formatAbsolute(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
}
