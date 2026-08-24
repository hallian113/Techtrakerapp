class AppConstants {
  static const String appName = 'TechTracker';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Premium Workforce Tracking';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String attendanceCollection = 'attendance';
  static const String locationsCollection = 'locations';

  // SharedPreferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefUserName = 'user_name';
  static const String prefUserRole = 'user_role';
  static const String prefIsLoggedIn = 'is_logged_in';

  // Location Update Interval (in seconds)
  static const int locationUpdateInterval = 10;

  // Punch Status
  static const String punchIn = 'in';
  static const String punchOut = 'out';

  // User Roles
  static const String roleTech = 'tech';
  static const String roleAdmin = 'admin';
}
