class LocationModel {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? locationName;
  final String? address;
  final double? speed;
  final double? accuracy;
  final bool isSynced;
  final String? sessionId;

  LocationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.locationName,
    this.address,
    this.speed,
    this.accuracy,
    this.isSynced = true,
    this.sessionId,
  });

  // 📥 From JSON (Firestore)
  factory LocationModel.fromJson(Map<String, dynamic> json, String id) {
    return LocationModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as dynamic?)?.toDate() ?? DateTime.now(),
      locationName: json['locationName'],
      address: json['address'],
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      isSynced: json['isSynced'] ?? true,
      sessionId: json['sessionId'],
    );
  }

  // 📤 To JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'locationName': locationName,
      'address': address,
      'speed': speed,
      'accuracy': accuracy,
      'isSynced': isSynced,
      'sessionId': sessionId,
    };
  }

  // 📝 Copy with
  LocationModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? locationName,
    String? address,
    double? speed,
    double? accuracy,
    bool? isSynced,
    String? sessionId,
  }) {
    return LocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      isSynced: isSynced ?? this.isSynced,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  // 🌍 Get Location String
  String get locationString {
    return '$latitude, $longitude';
  }

  // 📅 Get Time String
  String get timeString {
    int hour = timestamp.hour;
    int minute = timestamp.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $ampm';
  }

  // 📅 Get Date String
  String get dateString {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
