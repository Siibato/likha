import 'package:flutter/material.dart';

/// Utility class for consistent date formatting across desktop pages
class DesktopDateUtils {
  /// Formats date and time in a readable format (e.g., "Jan 15, 2024  3:30 PM")
  static String formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
            ? 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year}  $hour:$minute $period';
  }

  /// Formats date only in a readable format (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Formats date in ISO format (e.g., "2024-01-15")
  static String formatDateIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Formats date and time in ISO format (e.g., "2024-01-15T15:30:00")
  static String formatDateTimeIso(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  /// Formats time only in a readable format (e.g., "3:30 PM")
  static String formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formats date in a compact format for tables (e.g., "01/15 15:30")
  static String formatDateTimeCompact(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formats date in a compact format for tables (e.g., "2024-01-15 15:30")
  static String formatDateTimeTable(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formats date for display in form fields
  static String formatDateForDisplay(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats date and time for API submission
  static String formatForApi(DateTime dateTime) {
    return formatDateTimeIso(dateTime);
  }

  /// Gets a relative time description (e.g., "2 hours ago", "Yesterday")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
      } else {
        return formatDate(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Checks if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Checks if a date is within the last week
  static bool isLastWeek(DateTime date) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return date.isAfter(weekAgo);
  }

  /// Formats date with relative time if recent, otherwise full date
  static String formatWithRelative(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'Today ${formatTime(dateTime)}';
    } else if (isYesterday(dateTime)) {
      return 'Yesterday ${formatTime(dateTime)}';
    } else if (isLastWeek(dateTime)) {
      return getRelativeTime(dateTime);
    } else {
      return formatDate(dateTime);
    }
  }
}

/// Extension methods on DateTime for easy access to formatting
extension DesktopDateUtilsExtension on DateTime {
  /// Format as readable date and time
  String get toDesktopDateTime => DesktopDateUtils.formatDateTime(this);
  
  /// Format as readable date only
  String get toDesktopDate => DesktopDateUtils.formatDate(this);
  
  /// Format as ISO date
  String get toDesktopDateIso => DesktopDateUtils.formatDateIso(this);
  
  /// Format as compact table format
  String get toDesktopTable => DesktopDateUtils.formatDateTimeTable(this);
  
  /// Format as relative time if recent
  String get toDesktopRelative => DesktopDateUtils.formatWithRelative(this);
  
  /// Format for API
  String get toDesktopApi => DesktopDateUtils.formatForApi(this);
}
