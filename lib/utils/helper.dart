// lib/utils/helper.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

// ==================== VALIDATION HELPERS ====================
class ValidationHelper {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(pattern);
    
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    // Check for only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }
  
  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13 || age > 120) {
      return 'Age must be between 13 and 120';
    }
    
    return null;
  }
  
  // Weight validation
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (weight < 20 || weight > 500) {
      return 'Weight must be between 20 and 500 kg';
    }
    
    return null;
  }
  
  // Height validation
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid height';
    }
    
    if (height < 100 || height > 250) {
      return 'Height must be between 100 and 250 cm';
    }
    
    return null;
  }
  
  // Food portion validation
  static String? validatePortion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Portion is required';
    }
    
    final portion = double.tryParse(value);
    if (portion == null) {
      return 'Please enter a valid portion';
    }
    
    if (portion <= 0 || portion > 10000) {
      return 'Portion must be between 0 and 10000';
    }
    
    return null;
  }
}

// ==================== FORMATTING HELPERS ====================
class FormatHelper {
  // Format numbers
  static String formatNumber(double number, {int decimals = 1}) {
    return number.toStringAsFixed(decimals);
  }
  
  // Format calories
  static String formatCalories(double calories) {
    if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}k';
    }
    return calories.toStringAsFixed(0);
  }
  
  // Format weight
  static String formatWeight(double weight, {bool includeUnit = true}) {
    String formatted = weight.toStringAsFixed(1);
    return includeUnit ? '$formatted kg' : formatted;
  }
  
  // Format height
  static String formatHeight(double height, {bool includeUnit = true}) {
    String formatted = height.toStringAsFixed(0);
    return includeUnit ? '$formatted cm' : formatted;
  }
  
  // Format BMI
  static String formatBMI(double bmi) {
    return bmi.toStringAsFixed(1);
  }
  
  // Format percentage
  static String formatPercentage(double percentage, {int decimals = 0}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }
  
  // Format macronutrients
  static String formatMacro(double grams, {bool includeUnit = true}) {
    String formatted = grams.toStringAsFixed(1);
    return includeUnit ? '${formatted}g' : formatted;
  }
  
  // Format water intake
  static String formatWater(double ml, {bool includeUnit = true}) {
    if (ml >= 1000) {
      double liters = ml / 1000;
      String formatted = liters.toStringAsFixed(1);
      return includeUnit ? '${formatted}L' : formatted;
    }
    String formatted = ml.toStringAsFixed(0);
    return includeUnit ? '${formatted}ml' : formatted;
  }
  
  // Format currency (for premium features)
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }
}

// ==================== DATE & TIME HELPERS ====================
class DateHelper {
  // Format date
  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }
  
  // Format time
  static String formatTime(DateTime time, {bool is24Hour = false}) {
    String pattern = is24Hour ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern).format(time);
  }
  
  // Format date time
  static String formatDateTime(DateTime dateTime, {String pattern = 'MMM dd, yyyy h:mm a'}) {
    return DateFormat(pattern).format(dateTime);
  }
  
  // Get relative time
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  // Get days in current month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
  
  // Get week days
  static List<DateTime> getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }
}

// ==================== CALCULATION HELPERS ====================
class CalculationHelper {
  // Calculate BMI
  static double calculateBMI(double weightKg, double heightCm) {
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
  static double calculateBMR(double weightKg, double heightCm, int age, String gender) {
    double bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender.toLowerCase() == 'male' ? bmr + 5 : bmr - 161;
  }
  
  // Calculate daily calories need
  static double calculateDailyCalories(double bmr, String activityLevel, String goal) {
    double multiplier = NutritionConstants.activityMultipliers[activityLevel] ?? 1.2;
    double dailyCalories = bmr * multiplier;
    
    int adjustment = NutritionConstants.goalCalorieAdjustments[goal] ?? 0;
    return dailyCalories + adjustment;
  }
  
  // Calculate macro distribution
  static Map<String, double> calculateMacroDistribution(double dailyCalories, String plan) {
    Map<String, double> ratios = NutritionConstants.macroRatios[plan] ?? 
                                 NutritionConstants.macroRatios['balanced']!;
    
    double proteinCalories = dailyCalories * ratios['protein']!;
    double carbsCalories = dailyCalories * ratios['carbs']!;
    double fatCalories = dailyCalories * ratios['fat']!;
    
    return {
      'protein': proteinCalories / NutritionConstants.caloriesPerGramProtein,
      'carbs': carbsCalories / NutritionConstants.caloriesPerGramCarbs,
      'fat': fatCalories / NutritionConstants.caloriesPerGramFat,
    };
  }
  
  // Calculate nutrition per portion
  static Map<String, double> calculateNutritionPerPortion(
    Map<String, double> nutritionPer100g,
    double portionGrams,
  ) {
    double factor = portionGrams / 100;
    
    return nutritionPer100g.map((key, value) => 
      MapEntry(key, value * factor));
  }
  
  // Calculate progress percentage
  static double calculateProgress(double current, double target) {
    if (target <= 0) return 0;
    return (current / target * 100).clamp(0, 100);
  }
  
  // Calculate remaining values
  static double calculateRemaining(double current, double target) {
    return (target - current).clamp(0, double.infinity);
  }
  
  // Calculate calorie burn for activities (basic estimates)
  static double calculateCalorieBurn(String activity, int durationMinutes, double weightKg) {
    // MET values for common activities
    const Map<String, double> metValues = {
      'walking': 3.8,
      'running': 9.8,
      'cycling': 7.5,
      'swimming': 8.0,
      'strength_training': 6.0,
      'yoga': 2.5,
      'dancing': 4.8,
    };
    
    double met = metValues[activity] ?? 3.0;
    return met * weightKg * (durationMinutes / 60);
  }
}

// ==================== UI HELPERS ====================
class UIHelper {
  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusSmall,
        ),
      ),
    );
  }
  
  // Show success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppColors.success,
    );
  }
  
  // Show error message
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppColors.error,
    );
  }
  
  // Show warning message
  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppColors.warning,
    );
  }
  
  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacingMedium),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
  
  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  // Get color for progress
  static Color getProgressColor(double percentage) {
    if (percentage < 25) return AppColors.progressLow;
    if (percentage < 50) return AppColors.progressMedium;
    if (percentage < 100) return AppColors.progressHigh;
    return AppColors.progressComplete;
  }
  
  // Get color for nutrition type
  static Color getNutritionColor(String nutritionType) {
    switch (nutritionType.toLowerCase()) {
      case 'calories': return AppColors.calories;
      case 'protein': return AppColors.protein;
      case 'carbs': case 'carbohydrates': return AppColors.carbs;
      case 'fat': return AppColors.fat;
      case 'fiber': return AppColors.fiber;
      case 'water': return AppColors.water;
      default: return AppColors.primary;
    }
  }
  
  // Get color for meal type
  static Color getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast': return AppColors.breakfast;
      case 'lunch': return AppColors.lunch;
      case 'dinner': return AppColors.dinner;
      case 'snack': return AppColors.snack;
      default: return AppColors.primary;
    }
  }
  
  // Get icon for meal type
  static IconData getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast': return Icons.free_breakfast;
      case 'lunch': return Icons.lunch_dining;
      case 'dinner': return Icons.dinner_dining;
      case 'snack': return Icons.local_cafe;
      default: return Icons.restaurant;
    }
  }
  
  // Get icon for nutrition type
  static IconData getNutritionIcon(String nutritionType) {
    switch (nutritionType.toLowerCase()) {
      case 'calories': return Icons.local_fire_department;
      case 'protein': return Icons.fitness_center;
      case 'carbs': case 'carbohydrates': return Icons.grain;
      case 'fat': return Icons.opacity;
      case 'fiber': return Icons.eco;
      case 'water': return Icons.water_drop;
      default: return Icons.restaurant_menu;
    }
  }
  
  // Focus next field
  static void focusNextField(BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
  
  // Unfocus all fields
  static void unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

// ==================== STRING HELPERS ====================
class StringHelper {
  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  // Capitalize each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
  
  // Remove extra spaces
  static String cleanSpaces(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  // Generate initials
  static String getInitials(String name, {int maxLength = 2}) {
    List<String> words = name.trim().split(' ');
    String initials = '';
    
    for (int i = 0; i < words.length && i < maxLength; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0].toUpperCase();
      }
    }
    
    return initials;
  }
  
  // Truncate text
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + suffix;
  }
  
  // Check if string is numeric
  static bool isNumeric(String text) {
    return double.tryParse(text) != null;
  }
  
  // Remove special characters
  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }
  
  // Generate slug
  static String generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }
}

// ==================== LIST HELPERS ====================
class ListHelper {
  // Check if list is null or empty
  static bool isNullOrEmpty(List? list) {
    return list == null || list.isEmpty;
  }
  
  // Get safe element from list
  static T? safeGet<T>(List<T>? list, int index) {
    if (list == null || index < 0 || index >= list.length) {
      return null;
    }
    return list[index];
  }
  
  // Remove duplicates from list
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }
  
  // Chunk list into smaller lists
  static List<List<T>> chunk<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
  
  // Group list by key
  static Map<K, List<T>> groupBy<T, K>(List<T> list, K Function(T) keyFunction) {
    Map<K, List<T>> grouped = {};
    for (T item in list) {
      K key = keyFunction(item);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }
  
  // Find max item in list
  static T? findMax<T extends Comparable>(List<T> list) {
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }
  
  // Find min item in list
  static T? findMin<T extends Comparable>(List<T> list) {
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }
}

// ==================== DEVICE HELPERS ====================
class DeviceHelper {
  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }
  
  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }
  
  // Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  // Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  // Check if keyboard is open
  static bool isKeyboardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
  
  // Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
}

// ==================== STORAGE HELPERS ====================
class StorageHelper {
  // Convert bytes to human readable format
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (bytes.bitLength - 1) ~/ 10;
    
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
  
  // Check if file size is within limit
  static bool isFileSizeValid(int fileSizeBytes, int maxSizeMB) {
    int maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSizeBytes <= maxSizeBytes;
  }
  
  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }
  
  // Check if file is image
  static bool isImageFile(String fileName) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(getFileExtension(fileName));
  }
}