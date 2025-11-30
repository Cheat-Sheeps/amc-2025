import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  // Default to Dark Mode
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  void toggleTheme() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // --- THE DARK OUTFIT (Your current look) ---
  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0E0A),
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF00FF41),
      secondary: const Color(0xFF39FF14),
      surface: const Color(0xFF1A251A),
      background: const Color(0xFF0A0E0A),
      error: const Color(0xFFFF4444),
    ),
    // ... (I kept your font logic simple for brevity, it inherits automatically)
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0E0A),
      elevation: 0,
      titleTextStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF00FF41), fontSize: 20),
    ),
  );

  // --- THE LIGHT OUTFIT (New!) ---
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey/White
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF008F28), // Darker Green for contrast on white
      secondary: const Color(0xFF00FF41),
      surface: const Color(0xFFFFFFFF), // Pure White cards
      background: const Color(0xFFF5F5F5),
      error: const Color(0xFFFF4444),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFFFFFFF),
      elevation: 4,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF008F28), fontSize: 20),
    ),
  );
}