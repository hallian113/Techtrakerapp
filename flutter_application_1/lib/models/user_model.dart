import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'tech' or 'admin'
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.createdAt,
    this.isActive = true,
  });

  // 📥 From JSON (Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    final dynamic createdAtValue = json['createdAt'];
    final DateTime? parsedCreatedAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : createdAtValue is DateTime
            ? createdAtValue
            : createdAtValue is String
                ? DateTime.tryParse(createdAtValue)
                : null;

    return UserModel(
      id: id,
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      role: json['role'] ?? 'tech',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: parsedCreatedAt,
      isActive: json['isActive'] ?? true,
    );
  }

  // 📤 To JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt ?? DateTime.now(),
      'isActive': isActive,
    };
  }

  // 📝 Copy with
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // 🎨 Get Role Color
  String get roleColor {
    switch (role) {
      case 'admin':
        return '#D4AF37'; // Gold
      case 'tech':
        return '#00C853'; // Success Green
      default:
        return '#888888'; // Grey
    }
  }

  // 🏷️ Get Role Display Name
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'tech':
        return 'Technician';
      default:
        return 'User';
    }
  }

  // ✨ Get Initials
  String get initials {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
