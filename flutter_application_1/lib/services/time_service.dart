// ignore_for_file: unused_import

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/timezone.dart' as tz;

class TimeService {
  // 🇨🇦 Convert any DateTime to Canadian (Toronto) time for display
  DateTime _toCanadian(DateTime dateTime) {
    try {
      final toronto = tz.getLocation('America/Toronto');
      return tz.TZDateTime.from(dateTime, toronto);
    } catch (e) {
      return dateTime;
    }
  }

  // ✅ Get Trusted Time (device time — this stays as-is, it's the actual
  // instant recorded; only DISPLAY is converted to Canadian time)
  Future<DateTime> getTrustedTime() async {
    return DateTime.now();
  }

  // ✅ Format Time
  String formatTime(DateTime time) {
    final t = _toCanadian(time);
    int hour = t.hour;
    int minute = t.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $ampm';
  }

  // ✅ Format Date
  String formatDate(DateTime date) {
    final d = _toCanadian(date);
    return '${d.day}/${d.month}/${d.year}';
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

  // ✅ Check if Time is Today (compares in Canadian calendar day)
  bool isToday(DateTime date) {
    final d = _toCanadian(date);
    final now = _toCanadian(DateTime.now());
    return d.year == now.year && d.month == now.month && d.day == now.day;
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
