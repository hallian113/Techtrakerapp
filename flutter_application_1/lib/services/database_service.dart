import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracking_app/models/attendance_model.dart';
import 'package:tracking_app/models/location_model.dart';
import 'package:tracking_app/models/user_model.dart';
import 'package:tracking_app/utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER METHODS ====================

  // ✅ Save User
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  // ✅ Get User
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // ✅ Get All Users (for Admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // ✅ Get All Tech Users
  Future<List<UserModel>> getTechUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleTech)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tech users: $e');
    }
  }

  // ✅ Deactivate a user (soft-delete, keeps records intact)
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to remove user: $e');
    }
  }
  // ==================== ATTENDANCE METHODS ====================

  // ✅ Save Attendance
  Future<void> saveAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection(AppConstants.attendanceCollection)
          .doc(attendance.id)
          .set(attendance.toJson());
    } catch (e) {
      throw Exception('Failed to save attendance: $e');
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    await _firestore
        .collection(AppConstants.attendanceCollection)
        .doc(attendanceId)
        .delete();
  }

  // ✅ Get Attendance by User
  Future<List<AttendanceModel>> getAttendanceByUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance: $e');
    }
  }

  // ✅ Get Today's Attendance
  Future<List<AttendanceModel>> getTodayAttendance(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get today attendance: $e');
    }
  }

  // ✅ Get Attendance by Date
  Future<List<AttendanceModel>> getAttendanceByDate(
      String userId, DateTime date) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance by date: $e');
    }
  }

  // ✅ Get All Attendance (for Admin)
  Future<List<AttendanceModel>> getAllAttendance() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all attendance: $e');
    }
  }

  // ✅ Get All Attendance by Date (for Admin - all techs on a specific date)
  Future<List<AttendanceModel>> getAllAttendanceByDate(DateTime date) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance by date: $e');
    }
  }

  // ✅ Get All Attendance in a Date Range (for Admin - Week / Pay Period totals)
  Future<List<AttendanceModel>> getAllAttendanceInRange(
      DateTime start, DateTime end) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.attendanceCollection)
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance in range: $e');
    }
  }

  // ✅ Get Locations for a specific punch session (for map journey view)
  Future<List<LocationModel>> getLocationsBySession(String sessionId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return LocationModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get session locations: $e');
    }
  }
  // ==================== LOCATION METHODS ====================

  // ✅ Save Location
  Future<void> saveLocation(LocationModel location) async {
    try {
      await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(location.id)
          .set(location.toJson());
    } catch (e) {
      // Silent fail - will retry later
    }
  }

  // ✅ Get Locations by User
  Future<List<LocationModel>> getLocationsByUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        return LocationModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get locations: $e');
    }
  }

  // ✅ Get Locations by Date
  Future<List<LocationModel>> getLocationsByDate(
      String userId, DateTime date) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return LocationModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get locations by date: $e');
    }
  }

  Future<List<LocationModel>> getLocationsForDay(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final locations = snapshot.docs
          .map((doc) => LocationModel.fromJson(
                doc.data(),
                doc.id,
              ))
          .where((location) =>
              !location.timestamp.isBefore(startOfDay) &&
              location.timestamp.isBefore(endOfDay))
          .toList();
      locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return locations;
    } catch (e) {
      throw Exception('Failed to get locations for day: $e');
    }
  }

  // ✅ Get Latest Location of a User (for Admin Dashboard)
  Future<LocationModel?> getLatestLocation(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LocationModel.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ Get All Latest Locations (for Admin Dashboard)
  Future<List<LocationModel>> getAllLatestLocations() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();
      final Map<String, LocationModel> latestByUser = {};

      for (final doc in snapshot.docs) {
        final location = LocationModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        latestByUser.putIfAbsent(location.userId, () => location);
      }

      return latestByUser.values.toList();
    } catch (e) {
      throw Exception('Failed to get latest locations: $e');
    }
  }

  // ✅ Sync Offline Data
  Future<void> syncAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection(AppConstants.attendanceCollection)
          .doc(attendance.id)
          .set(attendance.toJson());
    } catch (e) {
      // Will retry later
    }
  }

  Future<void> syncLocation(LocationModel location) async {
    await _firestore
        .collection(AppConstants.locationsCollection)
        .doc(location.id)
        .set(location.toJson());
  }
}
