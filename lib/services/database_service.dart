import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Punch In Function (Server Time Save Hoga)
  Future<void> punchIn(String techId) async {
    String todayDate = DateTime.now().toUtc().toIso8601String().split(
      'T',
    )[0]; // YYYY-MM-DD

    // Tech ki current status update karna
    await _db.collection('technicians').doc(techId).update({
      'isPunchedIn': true,
      'currentStatus': 'Working', // Default status
    });

    // History mein Punch In entry karna (Server Timestamp use kar rahe hain fake time rokne ke liye)
    await _db
        .collection('technicians')
        .doc(techId)
        .collection('history')
        .doc(todayDate)
        .set({
          'punchInTime': FieldValue.serverTimestamp(), // CANADA/UTC Real Time
          'punchOutTime': null,
        }, SetOptions(merge: true));
  }

  // 2. Live Location Firebase Mein Save Karna
  Future<void> updateLiveLocation(
    String techId,
    double lat,
    double lng,
    String address,
  ) async {
    String todayDate = DateTime.now().toUtc().toIso8601String().split('T')[0];

    // Admin ko real-time dekhne ke liye current location update karna
    await _db.collection('technicians').doc(techId).update({
      'currentLat': lat,
      'currentLng': lng,
      'currentAddress': address,
    });

    // Daily basis par location ki history save karna
    await _db
        .collection('technicians')
        .doc(techId)
        .collection('history')
        .doc(todayDate)
        .collection('locations')
        .add({
          'lat': lat,
          'lng': lng,
          'address': address,
          'timestamp': FieldValue.serverTimestamp(), // Real Time
        });
  }

  // 3. Punch Out Function
  Future<void> punchOut(String techId) async {
    String todayDate = DateTime.now().toUtc().toIso8601String().split('T')[0];

    await _db.collection('technicians').doc(techId).update({
      'isPunchedIn': false,
      'currentStatus': 'Off Duty',
    });

    // History mein Punch Out time save karna
    await _db
        .collection('technicians')
        .doc(techId)
        .collection('history')
        .doc(todayDate)
        .update({
          'punchOutTime': FieldValue.serverTimestamp(), // Real Time
        });
  }
}
