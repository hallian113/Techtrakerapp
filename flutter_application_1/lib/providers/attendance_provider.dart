import 'package:flutter/material.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/time_service.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tracking_app/models/tech_hours_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TimeService _timeService = TimeService();

  List<AttendanceModel> _attendanceHistory = [];
  AttendanceModel? _currentSession;
  bool _isPunchedIn = false;
  bool _isLoading = false;
  String? _currentSessionId;
  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  AttendanceModel? get currentSession => _currentSession;
  bool get isPunchedIn => _isPunchedIn;
  bool get isLoading => _isLoading;
  String? get currentSessionId => _currentSessionId;
  // ✅ Punch In
  Future<bool> punchIn({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationName,
    required String address,
    String? note,
    String? customerName,
  }) async {
    _setLoading(true);
    try {
      if (_isPunchedIn) {
        Fluttertoast.showToast(msg: 'Already punched in!');
        _setLoading(false);
        return false;
      }

      // ✅ Get trusted time (prevents fake time)
      DateTime trustedTime = await _timeService.getTrustedTime();

      final String newSessionId =
          DateTime.now().millisecondsSinceEpoch.toString();
      AttendanceModel attendance = AttendanceModel(
        id: newSessionId,
        userId: userId,
        userName: userName,
        punchType: AppConstants.punchIn,
        timestamp: trustedTime,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        address: address,
        isSynced: false,
        note: note,
        sessionId: newSessionId,
        customerName: customerName,
      );

      // Save to local database
      await _databaseService.saveAttendance(attendance);

      // Save to Firestore (if internet available)
      await _databaseService.syncAttendance(attendance);

      _currentSession = attendance;
      _currentSessionId = newSessionId;
      _isPunchedIn = true;
      _attendanceHistory.add(attendance);

      Fluttertoast.showToast(
        msg: '✅ Punched In at ${_timeService.formatTime(trustedTime)}',
        backgroundColor: Colors.green,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefIsPunchedIn, true);
      await prefs.setString(AppConstants.prefSessionId, newSessionId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: 'Punch In failed: $e');
      return false;
    }
  }

  // ✅ Punch Out
  Future<bool> punchOut({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationName,
    required String address,
    String? note,
  }) async {
    _setLoading(true);
    try {
      if (!_isPunchedIn) {
        Fluttertoast.showToast(msg: 'Not punched in yet!');
        _setLoading(false);
        return false;
      }

      // ✅ Get trusted time
      DateTime trustedTime = await _timeService.getTrustedTime();

      AttendanceModel attendance = AttendanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        punchType: AppConstants.punchOut,
        timestamp: trustedTime,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        address: address,
        isSynced: false,
        note: note,
        sessionId: _currentSessionId,
      );

      // Save to local database
      await _databaseService.saveAttendance(attendance);

      // Save to Firestore
      await _databaseService.syncAttendance(attendance);

      _attendanceHistory.add(attendance);
      _isPunchedIn = false;
      _currentSessionId = null;
      _currentSession = null;

      Fluttertoast.showToast(
        msg: '✅ Punched Out at ${_timeService.formatTime(trustedTime)}',
        backgroundColor: Colors.orange,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefIsPunchedIn, false);
      await prefs.remove(AppConstants.prefSessionId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      Fluttertoast.showToast(msg: 'Punch Out failed: $e');
      return false;
    }
  }

  // ✅ Get Attendance History for User
  Future<List<AttendanceModel>> getAttendanceHistory(String userId) async {
    _setLoading(true);
    try {
      List<AttendanceModel> history =
          await _databaseService.getAttendanceByUser(userId);
      _attendanceHistory = history;
      _setLoading(false);
      return history;
    } catch (e) {
      _setLoading(false);
      return [];
    }
  }

  // Get recent attendance for Admin
  Future<List<AttendanceModel>> getAllAttendanceHistory() async {
    _setLoading(true);
    try {
      final List<AttendanceModel> history =
          await _databaseService.getAllAttendance();
      _attendanceHistory = history;
      _setLoading(false);
      return history;
    } catch (e) {
      _setLoading(false);
      return [];
    }
  }

  Future<bool> deleteAttendance(String attendanceId) async {
    try {
      await _databaseService.deleteAttendance(attendanceId);
      _attendanceHistory.removeWhere((record) => record.id == attendanceId);
      notifyListeners();
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Unable to delete attendance record');
      return false;
    }
  }

  // ✅ Get Today's Attendance
  Future<List<AttendanceModel>> getTodayAttendance(String userId) async {
    try {
      return await _databaseService.getTodayAttendance(userId);
    } catch (e) {
      return [];
    }
  }

  // ✅ Clear History
  void clearHistory() {
    _attendanceHistory.clear();
    notifyListeners();
  }

  // ✅ Get Punch Duration
  String? getPunchDuration() {
    if (_currentSession == null) return null;
    Duration duration = DateTime.now().difference(_currentSession!.timestamp);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return '$hours h ${minutes} m';
  }

  // ✅ Restore punch session after app restart/kill (persistent punch-in)
  Future<void> restoreSession(String userId) async {
    try {
      // ✅ Always check Firestore directly — it's the source of truth.
      // Don't gate on local SharedPreferences, since that gets wiped
      // on app uninstall/reinstall even though server data still exists.
      final history = await _databaseService.getAttendanceByUser(userId);
      if (history.isEmpty) return;

      final latest =
          history.first; // getAttendanceByUser is already ordered desc
      if (latest.punchType == AppConstants.punchIn) {
        _currentSession = latest;
        _currentSessionId = latest.sessionId ?? latest.id;
        _isPunchedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.prefIsPunchedIn, true);
        await prefs.setString(AppConstants.prefSessionId, _currentSessionId!);

        notifyListeners();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.prefIsPunchedIn, false);
        await prefs.remove(AppConstants.prefSessionId);
      }
    } catch (e) {
      // Silent fail - user can still manually punch in/out
    }
  }

  // ✅ Get All Attendance for a specific date (Admin)
  Future<List<AttendanceModel>> getAllAttendanceByDate(DateTime date) async {
    _setLoading(true);
    try {
      final records = await _databaseService.getAllAttendanceByDate(date);
      _setLoading(false);
      return records;
    } catch (e) {
      _setLoading(false);
      return [];
    }
  }

  // ✅ Calculate total worked hours per technician (pairs in->out records)
  List<TechHoursSummary> calculateDailyHours(List<AttendanceModel> records) {
    final Map<String, List<AttendanceModel>> byUser = {};
    for (var record in records) {
      byUser.putIfAbsent(record.userId, () => []).add(record);
    }

    final List<TechHoursSummary> summaries = [];

    byUser.forEach((userId, userRecords) {
      userRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      Duration total = Duration.zero;
      DateTime? punchInTime;
      String userName = userRecords.first.userName;

      for (var record in userRecords) {
        if (record.punchType == AppConstants.punchIn) {
          punchInTime = record.timestamp;
        } else if (record.punchType == AppConstants.punchOut &&
            punchInTime != null) {
          total += record.timestamp.difference(punchInTime);
          punchInTime = null;
        }
      }

      // Agar abhi bhi punched in hai (koi matching punch out nahi mila)
      // aur record aaj ka hai, to abhi tak ka time bhi count karo
      if (punchInTime != null) {
        final now = DateTime.now();
        final recordDate = userRecords.first.timestamp;
        final isToday = recordDate.year == now.year &&
            recordDate.month == now.month &&
            recordDate.day == now.day;
        if (isToday) {
          total += now.difference(punchInTime);
        }
      }

      summaries.add(TechHoursSummary(
        userId: userId,
        userName: userName,
        totalDuration: total,
      ));
    });

    summaries.sort((a, b) => b.totalDuration.compareTo(a.totalDuration));
    return summaries;
  }

  // ✅ Get current week range (Monday - Sunday)
  DateTimeRange getCurrentWeekRange() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  // ✅ Get current pay period range (1st-15th, 16th-end of month)
  DateTimeRange getCurrentPayPeriodRange() {
    final now = DateTime.now();
    if (now.day <= 15) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, 16)
          .subtract(const Duration(milliseconds: 1));
      return DateTimeRange(start: start, end: end);
    } else {
      final start = DateTime(now.year, now.month, 16);
      final end = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
      return DateTimeRange(start: start, end: end);
    }
  }

  // ✅ Get total combined hours of ALL techs for a date range (for the ring)
  Future<Duration> getTotalCompanyHoursForRange(DateTimeRange range) async {
    try {
      final records = await _databaseService.getAllAttendanceInRange(
          range.start, range.end);
      final summaries = calculateDailyHours(records);
      Duration total = Duration.zero;
      for (var s in summaries) {
        total += s.totalDuration;
      }
      return total;
    } catch (e) {
      return Duration.zero;
    }
  }

  // ✅ Get per-tech hours summary for a date range (Week / Pay Period)
  Future<List<TechHoursSummary>> calculateHoursForRange(
      DateTimeRange range) async {
    try {
      final records = await _databaseService.getAllAttendanceInRange(
          range.start, range.end);
      return calculateDailyHours(records);
    } catch (e) {
      return [];
    }
  }

  // ✅ Calculate total hours grouped by CUSTOMER (for a date range)
  Future<List<TechHoursSummary>> calculateCustomerHoursForRange(
      DateTimeRange range) async {
    try {
      final records = await _databaseService.getAllAttendanceInRange(
          range.start, range.end);

      final Map<String, List<AttendanceModel>> byUser = {};
      for (var record in records) {
        byUser.putIfAbsent(record.userId, () => []).add(record);
      }

      final Map<String, Duration> byCustomer = {};

      byUser.forEach((userId, userRecords) {
        userRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        DateTime? punchInTime;
        String customerName = 'Other';

        for (var record in userRecords) {
          if (record.punchType == AppConstants.punchIn) {
            punchInTime = record.timestamp;
            customerName =
                (record.customerName == null || record.customerName!.isEmpty)
                    ? 'Other'
                    : record.customerName!;
          } else if (record.punchType == AppConstants.punchOut &&
              punchInTime != null) {
            final duration = record.timestamp.difference(punchInTime);
            byCustomer[customerName] =
                (byCustomer[customerName] ?? Duration.zero) + duration;
            punchInTime = null;
          }
        }
      });

      final List<TechHoursSummary> summaries = byCustomer.entries
          .map((e) => TechHoursSummary(
                userId: e.key,
                userName: e.key,
                totalDuration: e.value,
              ))
          .toList();

      summaries.sort((a, b) => b.totalDuration.compareTo(a.totalDuration));
      return summaries;
    } catch (e) {
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
