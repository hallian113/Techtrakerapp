class TechModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' ya 'tech'
  final bool isPunchedIn;

  TechModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isPunchedIn = false,
  });

  // Firebase se data aane par usko Object mein convert karne ke liye
  factory TechModel.fromMap(Map<String, dynamic> map) {
    return TechModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      role: map['role'] ?? 'tech',
      isPunchedIn: map['isPunchedIn'] ?? false,
    );
  }

  // Object ko Firebase mein save karne ke liye
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isPunchedIn': isPunchedIn,
    };
  }
}
