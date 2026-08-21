import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialize karna
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TechTrackApp());
}

class TechTrackApp extends StatelessWidget {
  const TechTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechTrack Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Premium Black & Gold Theme
        scaffoldBackgroundColor: Colors.black, // Background Black
        primaryColor: const Color(0xFFD4AF37), // Premium Gold
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black54,
          prefixIconColor: Color(0xFFD4AF37),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2.0),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFFD4AF37),
          secondary: Colors.white,
          brightness: Brightness.dark, // Dark mode base
        ),
        useMaterial3: true,
      ),
      // Yahan se navigation routes set kiye hain
      initialRoute: '/login',
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}
