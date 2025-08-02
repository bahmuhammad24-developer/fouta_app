import 'package:intl/intl.dart';

/// Utility functions for formatting dates and times in a user‑friendly,
/// relative manner. These helpers convert a [DateTime] into strings like
/// "Just now", "5 mins ago", "Yesterday", or a formatted date. The
/// thresholds are based on common UX guidelines that recommend relative
/// timestamps until about seven days after the event【335098120425566†L238-L260】.
class DateUtilsHelper {
  /// Returns a human‑friendly relative string for the given [date].
  ///
  /// The following rules apply:
  /// * If within 1 minute: "Just now".
  /// * If within an hour: "X mins ago".
  /// * If within 24 hours: "X hours ago".
  /// * If yesterday: "Yesterday".
  /// * If within the last 7 days: weekday name (e.g. "Monday").
  /// * Else: a short date in mm/dd/yyyy format.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
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
    // Older dates: mm/dd/yyyy.
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Formats an absolute date/time for tooltips or accessibility. Returns
  /// a full date and time string like "Jul 31, 2025 5:30 PM".
  static String formatAbsolute(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
}