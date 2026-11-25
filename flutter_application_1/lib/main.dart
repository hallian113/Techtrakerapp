import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tracking_app/services/notification_service.dart';
import 'package:tracking_app/providers/auth_provider.dart';
import 'package:tracking_app/providers/location_provider.dart';
import 'package:tracking_app/providers/attendance_provider.dart';
import 'package:tracking_app/screens/splash_screen.dart';
import 'package:tracking_app/screens/login_screen.dart';
import 'package:tracking_app/screens/home_screen.dart';
import 'package:tracking_app/screens/punch_in_screen.dart';
import 'package:tracking_app/screens/history_screen.dart';
import 'package:tracking_app/screens/admin_dashboard_screen.dart';
import 'package:tracking_app/utils/theme.dart';
import 'package:tracking_app/utils/constants.dart';
import 'package:timezone/data/latest.dart' as tzdata;

// ✅ Handles notifications when app is fully closed/killed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background notifications are shown automatically by the system
  // when a 'notification' payload is included in the FCM message.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  Object? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (error) {
    startupError = error;
  }

  runApp(startupError == null
      ? const MyApp()
      : StartupErrorApp(error: startupError));
}

class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'TechTracker could not start.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData, // 🥇 Gold & Black Theme
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/punch': (context) => const PunchInScreen(),
          '/history': (context) => const HistoryScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}
