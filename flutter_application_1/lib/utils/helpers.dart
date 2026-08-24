import 'package:intl/intl.dart';

class Helpers {
  // Format DateTime
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Get current date string
  static String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Calculate duration between two times
  static String getDuration(DateTime start, DateTime end) {
    Duration diff = end.difference(start);
    int hours = diff.inHours;
    int minutes = diff.inMinutes.remainder(60);
    return '$hours h ${minutes} m';
  }

  // Validate Email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Truncate String
  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }
}
