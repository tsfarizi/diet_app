// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ==================== APP CONFIGURATION ====================
class AppConfig {
  static const String appName = 'Healthy Eating Tracker';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.example.diet_app';
  
  // Firebase Emulator Config (for development)
  static const bool useEmulator = true; // Set to false for production
  static const String emulatorHost = '127.0.0.1';
  static const int firestoreEmulatorPort = 8080;
  static const int authEmulatorPort = 9099;
  static const int storageEmulatorPort = 9199;
}

// ==================== APP COLORS ====================
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4CAF50);      // Green
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF9800);     // Orange
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFCC02);
  
  // Accent Colors
  static const Color accent = Color(0xFF2196F3);        // Blue
  static const Color accentLight = Color(0xFF64B5F6);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);
  
  // Nutrition Colors
  static const Color calories = Color(0xFFFF5722);      // Deep Orange
  static const Color protein = Color(0xFF3F51B5);       // Indigo
  static const Color carbs = Color(0xFF9C27B0);         // Purple
  static const Color fat = Color(0xFFFF9800);           // Orange
  static const Color fiber = Color(0xFF795548);         // Brown
  static const Color water = Color(0xFF00BCD4);         // Cyan
  
  // Meal Type Colors
  static const Color breakfast = Color(0xFFFFEB3B);     // Yellow
  static const Color lunch = Color(0xFF4CAF50);         // Green
  static const Color dinner = Color(0xFF9C27B0);        // Purple
  static const Color snack = Color(0xFFFF9800);         // Orange
  
  // Progress Colors
  static const Color progressLow = Color(0xFFF44336);    // Red
  static const Color progressMedium = Color(0xFFFF9800); // Orange
  static const Color progressHigh = Color(0xFF4CAF50);   // Green
  static const Color progressComplete = Color(0xFF2196F3); // Blue
  
  // Goal Colors
  static const Color loseWeight = Color(0xFFE91E63);     // Pink
  static const Color maintainWeight = Color(0xFF4CAF50); // Green
  static const Color gainWeight = Color(0xFF3F51B5);     // Indigo
}

// ==================== TEXT STYLES ====================
class AppTextStyles {
  // Font Family
  static const String fontFamily = 'Roboto';
  
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    fontFamily: fontFamily,
  );
  
  // Special Styles
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    fontFamily: fontFamily,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
    fontFamily: fontFamily,
  );
}

// ==================== DIMENSIONS ====================
class AppDimensions {
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Padding
  static const EdgeInsets paddingXSmall = EdgeInsets.all(spacingXSmall);
  static const EdgeInsets paddingSmall = EdgeInsets.all(spacingSmall);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spacingMedium);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacingLarge);
  static const EdgeInsets paddingXLarge = EdgeInsets.all(spacingXLarge);
  
  // Horizontal Padding
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: spacingSmall);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: spacingMedium);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: spacingLarge);
  
  // Vertical Padding
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: spacingSmall);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: spacingMedium);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: spacingLarge);
  
  // Border Radius
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 50.0;
  
  // Border Radius
  static const BorderRadius borderRadiusXSmall = BorderRadius.all(Radius.circular(radiusXSmall));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  
  // Icon Sizes
  static const double iconXSmall = 16.0;
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Button Heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightXLarge = 56.0;
  
  // Card/Container Heights
  static const double cardHeightSmall = 80.0;
  static const double cardHeightMedium = 120.0;
  static const double cardHeightLarge = 160.0;
  
  // AppBar Height
  static const double appBarHeight = 56.0;
  
  // Bottom Navigation Height
  static const double bottomNavHeight = 80.0;
  
  // FAB Size
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
}

// ==================== NUTRITION CONSTANTS ====================
class NutritionConstants {
  // Macronutrient calories per gram
  static const double caloriesPerGramProtein = 4.0;
  static const double caloriesPerGramCarbs = 4.0;
  static const double caloriesPerGramFat = 9.0;
  static const double caloriesPerGramAlcohol = 7.0;
  
  // Daily recommended values (general guidelines)
  static const double dailyWaterIntakeML = 2000.0;
  static const double dailyFiberGrams = 25.0;
  static const double dailySodiumMG = 2300.0;
  static const double dailySugarGrams = 50.0;
  
  // Activity multipliers for BMR calculation
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
    'extra_active': 1.9,
  };
  
  // Weight goals calorie adjustments (per day)
  static const Map<String, int> goalCalorieAdjustments = {
    'lose_weight': -500,     // 1 lb per week
    'maintain_weight': 0,
    'gain_weight': 500,      // 1 lb per week
  };
  
  // Macronutrient ratio recommendations (%)
  static const Map<String, Map<String, double>> macroRatios = {
    'balanced': {
      'protein': 0.25,
      'carbs': 0.45,
      'fat': 0.30,
    },
    'low_carb': {
      'protein': 0.30,
      'carbs': 0.20,
      'fat': 0.50,
    },
    'high_protein': {
      'protein': 0.40,
      'carbs': 0.35,
      'fat': 0.25,
    },
  };
}

// ==================== APP STRINGS ====================
class AppStrings {
  // General
  static const String appName = 'Healthy Eating Tracker';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String update = 'Update';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  
  // Authentication
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  
  // Navigation
  static const String home = 'Home';
  static const String profile = 'Profile';
  static const String tracking = 'Tracking';
  static const String foods = 'Foods';
  static const String meals = 'Meals';
  static const String analytics = 'Analytics';
  static const String settings = 'Settings';
  
  // Nutrition
  static const String calories = 'Calories';
  static const String protein = 'Protein';
  static const String carbs = 'Carbs';
  static const String fat = 'Fat';
  static const String fiber = 'Fiber';
  static const String water = 'Water';
  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String snack = 'Snack';
  
  // Goals
  static const String loseWeight = 'Lose Weight';
  static const String maintainWeight = 'Maintain Weight';
  static const String gainWeight = 'Gain Weight';
  
  // Units
  static const String grams = 'g';
  static const String milligrams = 'mg';
  static const String milliliters = 'ml';
  static const String liters = 'L';
  static const String kilograms = 'kg';
  static const String pounds = 'lbs';
  static const String centimeters = 'cm';
  static const String feet = 'ft';
  static const String inches = 'in';
  
  // Messages
  static const String noDataAvailable = 'No data available';
  static const String connectionError = 'Connection error. Please check your internet.';
  static const String unexpectedError = 'An unexpected error occurred';
  static const String dataSavedSuccessfully = 'Data saved successfully';
  static const String dataDeletedSuccessfully = 'Data deleted successfully';
}

// ==================== ANIMATION DURATIONS ====================
class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration extraLong = Duration(milliseconds: 800);
  
  static const Duration pageTransition = medium;
  static const Duration buttonPress = short;
  static const Duration cardAnimation = medium;
  static const Duration slideAnimation = long;
  static const Duration fadeAnimation = medium;
}