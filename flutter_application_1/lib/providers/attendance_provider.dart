import 'package:flutter/material.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/time_service.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TimeService _timeService = TimeService();

  List<AttendanceModel> _attendanceHistory = [];
  AttendanceModel? _currentSession;
  bool _isPunchedIn = false;
  bool _isLoading = false;

  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  AttendanceModel? get currentSession => _currentSession;
  bool get isPunchedIn => _isPunchedIn;
  bool get isLoading => _isLoading;

  // ✅ Punch In
  Future<bool> punchIn({
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
      if (_isPunchedIn) {
        Fluttertoast.showToast(msg: 'Already punched in!');
        _setLoading(false);
        return false;
      }

      // ✅ Get trusted time (prevents fake time)
      DateTime trustedTime = await _timeService.getTrustedTime();

      AttendanceModel attendance = AttendanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      );

      // Save to local database
      await _databaseService.saveAttendance(attendance);

      // Save to Firestore (if internet available)
      await _databaseService.syncAttendance(attendance);

      _currentSession = attendance;
      _isPunchedIn = true;
      _attendanceHistory.add(attendance);

      Fluttertoast.showToast(
        msg: '✅ Punched In at ${_timeService.formatTime(trustedTime)}',
        backgroundColor: Colors.green,
      );

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
      );

      // Save to local database
      await _databaseService.saveAttendance(attendance);

      // Save to Firestore
      await _databaseService.syncAttendance(attendance);

      _attendanceHistory.add(attendance);
      _isPunchedIn = false;
      _currentSession = null;

      Fluttertoast.showToast(
        msg: '✅ Punched Out at ${_timeService.formatTime(trustedTime)}',
        backgroundColor: Colors.orange,
      );

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
