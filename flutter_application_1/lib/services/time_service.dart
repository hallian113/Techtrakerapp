// ignore_for_file: unused_import

import 'package:flutter/foundation.dart' show kIsWeb;

class TimeService {
  // ✅ Get Trusted Time (Uses device time for now)
  Future<DateTime> getTrustedTime() async {
    // Web ya Mobile dono par device time use karein
    return DateTime.now();
  }

  // ✅ Format Time
  String formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $ampm';
  }

  // ✅ Format Date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ✅ Format Full DateTime
  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  // ✅ Get Duration Between Two Times
  String getDuration(DateTime start, DateTime end) {
    Duration diff = end.difference(start);
    int hours = diff.inHours;
    int minutes = diff.inMinutes.remainder(60);
    return '$hours h ${minutes}m';
  }

  // ✅ Check if Time is Today
  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // ✅ Get Start of Day
  DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ✅ Get End of Day
  DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
