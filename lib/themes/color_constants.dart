import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Green Theme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenLight = Color(0xFF81C784);
  static const Color accentGreen = Color(0xFF8BC34A);
  
  // Secondary Colors
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color red = Color(0xFFF44336);
  static const Color purple = Color(0xFF9C27B0);
  
  // Neutral Colors - Light Theme
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color dividerLight = Color(0xFFE0E0E0);
  
  // Neutral Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF3D3D3D);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Transparent Colors
  static const Color transparent = Colors.transparent;
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3A000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenDark],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, primaryGreenLight],
  );
  
  // Nutrition Colors
  static const Color caloriesColor = Color(0xFFFF6B6B);
  static const Color proteinColor = Color(0xFF4ECDC4);
  static const Color carbsColor = Color(0xFFFFE66D);
  static const Color fatColor = Color(0xFFFF8E53);
  static const Color fiberColor = Color(0xFFA8E6CF);
  static const Color waterColor = Color(0xFF74B9FF);
}