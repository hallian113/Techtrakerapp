// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/services/time_service.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/utils/constants.dart';

class AttendanceService {
  final DatabaseService _databaseService = DatabaseService();
  final TimeService _timeService = TimeService();

  // ✅ Punch In
  Future<AttendanceModel?> punchIn({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationName,
    required String address,
    String? note,
  }) async {
    try {
      // Get trusted time (prevents fake time)
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

      await _databaseService.saveAttendance(attendance);
      return attendance;
    } catch (e) {
      throw Exception('Punch In failed: $e');
    }
  }

  // ✅ Punch Out
  Future<AttendanceModel?> punchOut({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationName,
    required String address,
    String? note,
  }) async {
    try {
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

      await _databaseService.saveAttendance(attendance);
      return attendance;
    } catch (e) {
      throw Exception('Punch Out failed: $e');
    }
  }

  // ✅ Get Attendance History
  Future<List<AttendanceModel>> getAttendanceHistory(String userId) async {
    try {
      return await _databaseService.getAttendanceByUser(userId);
    } catch (e) {
      throw Exception('Failed to get attendance history: $e');
    }
  }

  // ✅ Get Today's Attendance
  Future<List<AttendanceModel>> getTodayAttendance(String userId) async {
    try {
      return await _databaseService.getTodayAttendance(userId);
    } catch (e) {
      throw Exception('Failed to get today attendance: $e');
    }
  }

  // ✅ Get Attendance by Date
  Future<List<AttendanceModel>> getAttendanceByDate(
      String userId, DateTime date) async {
    try {
      return await _databaseService.getAttendanceByDate(userId, date);
    } catch (e) {
      throw Exception('Failed to get attendance by date: $e');
    }
  }

  // ✅ Check if User is Punched In Today
  Future<bool> isPunchedInToday(String userId) async {
    try {
      List<AttendanceModel> todayAttendance = await getTodayAttendance(userId);

      // Check if there's a punch in without a punch out
      bool hasPunchIn =
          todayAttendance.any((att) => att.punchType == AppConstants.punchIn);
      bool hasPunchOut =
          todayAttendance.any((att) => att.punchType == AppConstants.punchOut);

      return hasPunchIn && !hasPunchOut;
    } catch (e) {
      return false;
    }
  }

  // ✅ Get Working Hours for a Day
  Future<String> getWorkingHours(String userId, DateTime date) async {
    try {
      List<AttendanceModel> records = await getAttendanceByDate(userId, date);

      AttendanceModel? punchInRecord;
      AttendanceModel? punchOutRecord;

      for (var record in records) {
        if (record.punchType == AppConstants.punchIn) {
          punchInRecord = record;
        } else if (record.punchType == AppConstants.punchOut) {
          punchOutRecord = record;
        }
      }

      if (punchInRecord == null || punchOutRecord == null) {
        return 'N/A';
      }

      Duration duration =
          punchOutRecord.timestamp.difference(punchInRecord.timestamp);
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);

      return '$hours h ${minutes} m';
    } catch (e) {
      return 'N/A';
    }
  }
}
