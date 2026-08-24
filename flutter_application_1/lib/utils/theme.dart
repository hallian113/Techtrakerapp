// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🥇 Gold Colors
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C84A);
  static const Color goldDark = Color(0xFFB8960F);
  static const Color goldShimmer = Color(0xFFF5E56B);

  // ⚫ Black Colors
  static const Color black = Color(0xFF0A0A0A);
  static const Color blackLight = Color(0xFF1A1A1A);
  static const Color blackCard = Color(0xFF1E1E1E);
  static const Color blackDark = Color(0xFF050505);

  // ⚪ Grey
  static const Color greyLight = Color(0xFFB8B8B8);
  static const Color greyMedium = Color(0xFF888888);
  static const Color greyDark = Color(0xFF444444);

  // 🟢 Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFC107);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,

      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: blackLight,
        background: black,
        error: error,
        onPrimary: black,
        onSecondary: black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        brightness: Brightness.dark,
      ),

      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          elevation: 8,
          shadowColor: gold.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: blackCard,
        elevation: 4,
        shadowColor: gold.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: gold.withOpacity(0.2), width: 0.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: blackLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: greyDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(color: greyLight),
        hintStyle: const TextStyle(color: greyMedium),
        prefixIconColor: gold,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: gold,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: gold),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: blackLight,
        selectedItemColor: gold,
        unselectedItemColor: greyMedium,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      dividerTheme: DividerThemeData(
        color: gold.withOpacity(0.2),
        thickness: 1,
        space: 20,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: blackCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: gold.withOpacity(0.2)),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: gold,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70),
      ),
    );
  }

  // 🥇 Gold Gradient
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight, gold],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // 🎨 Background Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [black, blackLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 🥇 Shimmer Gold
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [goldDark, gold, goldLight, gold, goldDark],
    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
