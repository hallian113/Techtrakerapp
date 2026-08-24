class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String punchType; // 'in' or 'out'
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? address;
  final bool isSynced;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.punchType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationName,
    this.address,
    this.isSynced = true,
    this.note,
  });

  // 📥 From JSON (Firestore)
  factory AttendanceModel.fromJson(Map<String, dynamic> json, String id) {
    return AttendanceModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      punchType: json['punchType'] ?? 'in',
      timestamp: (json['timestamp'] as dynamic?)?.toDate() ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'],
      address: json['address'],
      isSynced: json['isSynced'] ?? true,
      note: json['note'],
    );
  }

  // 📤 To JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'punchType': punchType,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'address': address,
      'isSynced': isSynced,
      'note': note,
    };
  }

  // 📝 Copy with
  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? punchType,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? locationName,
    String? address,
    bool? isSynced,
    String? note,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      punchType: punchType ?? this.punchType,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      isSynced: isSynced ?? this.isSynced,
      note: note ?? this.note,
    );
  }

  // 🎨 Get Punch Type Color
  String get punchTypeColor {
    switch (punchType) {
      case 'in':
        return '#00C853'; // Green
      case 'out':
        return '#FF1744'; // Red
      default:
        return '#888888'; // Grey
    }
  }

  // 🏷️ Get Punch Type Display Name
  String get punchTypeDisplayName {
    switch (punchType) {
      case 'in':
        return 'Punch In';
      case 'out':
        return 'Punch Out';
      default:
        return 'Unknown';
    }
  }

  // ✨ Get Punch Type Icon
  String get punchTypeIcon {
    switch (punchType) {
      case 'in':
        return '📥';
      case 'out':
        return '📤';
      default:
        return '⏰';
    }
  }

  // 📅 Get Date String
  String get dateString {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // 🕐 Get Time String
  String get timeString {
    int hour = timestamp.hour;
    int minute = timestamp.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $ampm';
  }
}
