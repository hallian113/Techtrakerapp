import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class Helpers {
  // 🇨🇦 Convert any DateTime to Canadian (Toronto) time for display
  static DateTime _toCanadian(DateTime dateTime) {
    try {
      final toronto = tz.getLocation('America/Toronto');
      return tz.TZDateTime.from(dateTime, toronto);
    } catch (e) {
      return dateTime; // fallback if timezone db isn't ready
    }
  }

  // Format DateTime
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(_toCanadian(dateTime));
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(_toCanadian(dateTime));
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(_toCanadian(dateTime));
  }

  // Get current date string
  static String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(_toCanadian(DateTime.now()));
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
