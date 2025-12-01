import 'package:flutter/material.dart';

/// Duolingo-inspired pastel color palette for Healtiefy
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF58CC02); // Duolingo green
  static const Color primaryLight = Color(0xFF89E219); // Light green
  static const Color primaryDark = Color(0xFF4CAD00); // Dark green

  // Secondary Colors
  static const Color secondary = Color(0xFF1CB0F6); // Sky blue
  static const Color secondaryLight = Color(0xFF4FC3F7);
  static const Color secondaryDark = Color.fromARGB(255, 3, 33, 47);

  // Tertiary Colors
  static const Color tertiary = Color(0xFFFF9600); // Orange
  static const Color tertiaryLight = Color(0xFFFFB347);
  static const Color tertiaryDark = Color(0xFFE68A00);

  // Accent Colors
  static const Color accent1 = Color(0xFFCE82FF); // Purple
  static const Color accent2 = Color(0xFFFF4B4B); // Red/Pink
  static const Color accent3 = Color(0xFFFFDE00); // Yellow
  static const Color accent4 = Color(0xFF2B70C9); // Dark blue

  // Convenience aliases
  static const Color purple = accent1;
  static const Color accent = tertiary; // Orange

  // Background Colors
  static const Color background = Color(0xFFF7F7F7); // Light gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimary = Color(0xFF3C3C3C); // Dark gray
  static const Color textSecondary = Color(0xFF777777); // Medium gray
  static const Color textLight = Color(0xFFAFAFAF); // Light gray

  // Status Colors
  static const Color success = Color(0xFF58CC02); // Green
  static const Color warning = Color(0xFFFF9600); // Orange
  static const Color error = Color(0xFFFF4B4B); // Red
  static const Color info = Color(0xFF1CB0F6); // Blue

  // Card Colors (Soft Pastel)
  static const Color cardGreen = Color(0xFFE5F9D0);
  static const Color cardBlue = Color(0xFFD4F1FF);
  static const Color cardOrange = Color(0xFFFFEDD4);
  static const Color cardPurple = Color(0xFFF3E5FF);
  static const Color cardYellow = Color(0xFFFFF9D4);
  static const Color cardPink = Color(0xFFFFE5E5);

  // Progress Colors
  static const Color progressBackground = Color(0xFFE5E5E5);
  static const Color progressFill = Color(0xFF58CC02);

  // Shadows
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiaryLight, tertiary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent1, Color(0xFF9B59B6)],
  );

  // Building Type Colors (for city building feature)
  static const Color buildingHouse = Color(0xFF58CC02);
  static const Color buildingShop = Color(0xFF1CB0F6);
  static const Color buildingPark = Color(0xFF89E219);
  static const Color buildingFactory = Color(0xFFFF9600);
  static const Color buildingSchool = Color(0xFFCE82FF);

  // Map Colors
  static const Color mapRoute = Color(0xFF58CC02);
  static const Color mapRouteCompleted = Color(0xFF4CAD00);
  static const Color mapMarker = Color(0xFFFF4B4B);
  static const Color mapBuildableZone = Color(0x4058CC02);
}
