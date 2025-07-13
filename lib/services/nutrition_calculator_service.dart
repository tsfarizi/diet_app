import 'dart:math';

class NutritionCalculationService {
  static const double _caloriesPerKgFat = 7700; // 1kg fat = 7700 kcal

  // ==================== BMR CALCULATIONS ====================
  
  /// Calculate Basal Metabolic Rate using Mifflin St Jeor equation
  /// This is more accurate than Harris Benedict formula
  static double calculateBMR({
    required double weight, // in kg
    required double height, // in cm
    required int age, // in years
    required String gender, // 'male' or 'female'
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // ==================== TDEE CALCULATIONS ====================
  
  /// Calculate Total Daily Energy Expenditure
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = getActivityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// Get activity level multiplier
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Little/no exercise
      case 'light':
        return 1.375; // Light exercise 1-3 days/week
      case 'moderate':
        return 1.55; // Moderate exercise 3-5 days/week
      case 'active':
        return 1.725; // Hard exercise 6-7 days/week
      case 'very_active':
        return 1.9; // Very hard exercise, physical job
      default:
        return 1.2; // Default to sedentary
    }
  }

  // ==================== CALORIE TARGET CALCULATIONS ====================
  
  /// Calculate daily calorie target for weight loss based on BMI
  static double calculateCalorieTarget({
    required double tdee,
    required double currentWeight,
    required double height,
    required String goal,
  }) {
    final bmi = calculateBMI(weight: currentWeight, height: height);
    
    // Smart deficit based on BMI for safe weight loss
    double deficit;
    if (bmi > 30) {
      deficit = 750; // Obese: 750 kcal deficit (0.75kg/week)
    } else if (bmi > 25) {
      deficit = 500; // Overweight: 500 kcal deficit (0.5kg/week)
    } else {
      deficit = 300; // Normal: 300 kcal deficit (0.3kg/week)
    }

    // Ensure minimum calorie intake for safety
    final targetCalories = tdee - deficit;
    
    // Men: minimum 1500 kcal, Women: minimum 1200 kcal (but we'll use 1400 to be safer)
    final minimumCalories = 1400.0;
    
    return max(targetCalories, minimumCalories);
  }

  // ==================== MACRO TARGET CALCULATIONS ====================
  
  /// Calculate protein target for weight loss (preserve muscle mass)
  static double calculateProteinTarget({
    required double weight,
    required String goal,
  }) {
    // For weight loss: higher protein to preserve muscle mass
    return weight * 1.6; // 1.6g per kg body weight
  }

  /// Calculate carbohydrate target
  static double calculateCarbTarget({
    required double calorieTarget,
    required double proteinTarget,
    required double fatTarget,
  }) {
    final proteinCalories = proteinTarget * 4; // 1g protein = 4 kcal
    final fatCalories = fatTarget * 9; // 1g fat = 9 kcal
    final carbCalories = calorieTarget - proteinCalories - fatCalories;
    
    // Ensure positive carb calories
    return max(carbCalories / 4, 0); // 1g carb = 4 kcal
  }

  /// Calculate fat target (25% of total calories)
  static double calculateFatTarget({
    required double calorieTarget,
  }) {
    return (calorieTarget * 0.25) / 9; // 25% of calories, 1g fat = 9 kcal
  }

  // ==================== WATER TARGET CALCULATIONS ====================
  
  /// Calculate daily water target
  static double calculateWaterTarget({
    required double weight,
    required String activityLevel,
  }) {
    // Base water: 35ml per kg body weight
    double baseWater = weight * 35;
    
    // Additional water based on activity level
    switch (activityLevel.toLowerCase()) {
      case 'active':
      case 'very_active':
        return baseWater + 500; // Add 500ml for high activity
      case 'moderate':
        return baseWater + 250; // Add 250ml for moderate activity
      default:
        return baseWater;
    }
  }

  // ==================== BMI CALCULATIONS ====================
  
  /// Calculate Body Mass Index
  static double calculateBMI({
    required double weight, // in kg
    required double height, // in cm
  }) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // ==================== WEIGHT LOSS ESTIMATIONS ====================
  
  /// Calculate estimated weight loss per week
  static double calculateWeightLossPerWeek({
    required double tdee,
    required double calorieTarget,
  }) {
    final dailyDeficit = tdee - calorieTarget;
    final weeklyDeficit = dailyDeficit * 7;
    return weeklyDeficit / _caloriesPerKgFat;
  }

  /// Calculate estimated weeks to reach target weight
  static int calculateWeeksToTarget({
    required double currentWeight,
    required double targetWeight,
    required double weeklyWeightLoss,
  }) {
    if (targetWeight >= currentWeight || weeklyWeightLoss <= 0) return 0;
    
    final weightToLose = currentWeight - targetWeight;
    return (weightToLose / weeklyWeightLoss).ceil();
  }

  // ==================== ACTIVITY LEVEL GUIDANCE ====================
  
  /// Get activity level description
  static String getActivityLevelDescription(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 'Kerja duduk, olahraga 0-1x/minggu, <5000 langkah/hari';
      case 'light':
        return 'Olahraga ringan 1-3x/minggu, 30-45 menit/sesi (yoga, jalan cepat)';
      case 'moderate':
        return 'Olahraga 3-5x/minggu, 45-60 menit/sesi (gym, jogging)';
      case 'active':
        return 'Olahraga intense 6-7x/minggu, 60+ menit/sesi (atletik, training)';
      case 'very_active':
        return 'Olahraga 2x/hari atau atlet profesional';
      default:
        return 'Pilih tingkat aktivitas yang sesuai';
    }
  }

  /// Validate if activity level is realistic for age
  static bool isActivityLevelRealistic({
    required String activityLevel,
    required int age,
    required double calorieTarget,
  }) {
    // Check if very active at older age
    if (activityLevel == 'very_active' && age > 50) {
      return false;
    }
    
    // Check if calorie target is too low (dangerous)
    if (calorieTarget < 1200) {
      return false;
    }
    
    return true;
  }

  /// Get warning message for unrealistic activity level
  static String? getActivityLevelWarning({
    required String activityLevel,
    required int age,
    required double calorieTarget,
  }) {
    if (activityLevel == 'very_active' && age > 50) {
      return 'Apakah yakin olahraga 2x/hari di usia $age tahun? Pertimbangkan turun ke "Active"';
    }
    
    if (calorieTarget < 1200) {
      return 'Target kalori terlalu rendah (${calorieTarget.round()} kcal). Coba naikkan aktivitas atau kurangi deficit.';
    }
    
    return null;
  }

  // ==================== CALORIE IMPACT CALCULATIONS ====================
  
  /// Calculate calorie impact if changing activity level
  static double calculateCalorieImpactIfChange({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String currentActivityLevel,
    required String newActivityLevel,
  }) {
    if (currentActivityLevel == newActivityLevel) return 0;
    
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    
    final currentTdee = calculateTDEE(bmr: bmr, activityLevel: currentActivityLevel);
    final newTdee = calculateTDEE(bmr: bmr, activityLevel: newActivityLevel);
    
    final currentCalorieTarget = calculateCalorieTarget(
      tdee: currentTdee,
      currentWeight: weight,
      height: height,
      goal: 'lose_weight',
    );
    
    final newCalorieTarget = calculateCalorieTarget(
      tdee: newTdee,
      currentWeight: weight,
      height: height,
      goal: 'lose_weight',
    );
    
    return newCalorieTarget - currentCalorieTarget;
  }

  // ==================== COMPLETE NUTRITION PROFILE ====================
  
  /// Calculate complete nutrition profile
  static Map<String, dynamic> calculateCompleteProfile({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required double targetWeight,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    
    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    
    final calorieTarget = calculateCalorieTarget(
      tdee: tdee,
      currentWeight: weight,
      height: height,
      goal: 'lose_weight',
    );
    
    final proteinTarget = calculateProteinTarget(
      weight: weight,
      goal: 'lose_weight',
    );
    
    final fatTarget = calculateFatTarget(calorieTarget: calorieTarget);
    
    final carbTarget = calculateCarbTarget(
      calorieTarget: calorieTarget,
      proteinTarget: proteinTarget,
      fatTarget: fatTarget,
    );
    
    final waterTarget = calculateWaterTarget(
      weight: weight,
      activityLevel: activityLevel,
    );
    
    final weeklyWeightLoss = calculateWeightLossPerWeek(
      tdee: tdee,
      calorieTarget: calorieTarget,
    );
    
    final weeksToTarget = calculateWeeksToTarget(
      currentWeight: weight,
      targetWeight: targetWeight,
      weeklyWeightLoss: weeklyWeightLoss,
    );
    
    final bmi = calculateBMI(weight: weight, height: height);
    final bmiCategory = getBMICategory(bmi);
    
    return {
      'bmr': bmr,
      'tdee': tdee,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'targets': {
        'calories': calorieTarget,
        'protein': proteinTarget,
        'carbs': carbTarget,
        'fat': fatTarget,
        'water': waterTarget,
      },
      'estimations': {
        'weeklyWeightLoss': weeklyWeightLoss,
        'weeksToTarget': weeksToTarget,
        'dailyDeficit': tdee - calorieTarget,
      },
      'activityInfo': {
        'level': activityLevel,
        'description': getActivityLevelDescription(activityLevel),
        'multiplier': getActivityMultiplier(activityLevel),
        'isRealistic': isActivityLevelRealistic(
          activityLevel: activityLevel,
          age: age,
          calorieTarget: calorieTarget,
        ),
        'warning': getActivityLevelWarning(
          activityLevel: activityLevel,
          age: age,
          calorieTarget: calorieTarget,
        ),
      },
    };
  }

  // ==================== PROGRESS ANALYSIS ====================
  
  /// Analyze nutrition progress against targets
  static Map<String, dynamic> analyzeProgress({
    required Map<String, double> actualIntake,
    required Map<String, double> targets,
  }) {
    final progress = <String, double>{};
    final achievements = <String, bool>{};
    final recommendations = <String>[];

    for (final nutrient in targets.keys) {
      final actual = actualIntake[nutrient] ?? 0.0;
      final target = targets[nutrient] ?? 1.0;
      final percentage = actual / target;
      
      progress[nutrient] = percentage;
      achievements[nutrient] = percentage >= 0.9 && percentage <= 1.1;
      
      // Generate recommendations
      if (percentage < 0.8) {
        recommendations.add(_getLowIntakeRecommendation(nutrient));
      } else if (percentage > 1.2) {
        recommendations.add(_getHighIntakeRecommendation(nutrient));
      }
    }

    return {
      'progress': progress,
      'achievements': achievements,
      'recommendations': recommendations,
      'overallScore': _calculateOverallScore(progress),
    };
  }

  static String _getLowIntakeRecommendation(String nutrient) {
    switch (nutrient) {
      case 'calories':
        return 'Kalori masih kurang. Tambah camilan sehat atau naikkan porsi makan.';
      case 'protein':
        return 'Protein kurang. Tambah telur, daging tanpa lemak, atau protein shake.';
      case 'water':
        return 'Minum air lebih banyak. Set reminder setiap 2 jam.';
      default:
        return 'Asupan $nutrient masih kurang dari target.';
    }
  }

  static String _getHighIntakeRecommendation(String nutrient) {
    switch (nutrient) {
      case 'calories':
        return 'Kalori berlebihan. Kurangi porsi atau pilih makanan rendah kalori.';
      case 'fat':
        return 'Lemak berlebihan. Kurangi makanan gorengan dan pilih protein tanpa lemak.';
      case 'carbs':
        return 'Karbohidrat berlebihan. Kurangi nasi/roti dan perbanyak sayuran.';
      default:
        return 'Asupan $nutrient melebihi target.';
    }
  }

  static double _calculateOverallScore(Map<String, double> progress) {
    if (progress.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final percentage in progress.values) {
      // Score 100 for 90-110%, decreasing as it goes further from optimal
      if (percentage >= 0.9 && percentage <= 1.1) {
        totalScore += 100;
      } else if (percentage >= 0.8 && percentage <= 1.2) {
        totalScore += 80;
      } else if (percentage >= 0.7 && percentage <= 1.3) {
        totalScore += 60;
      } else {
        totalScore += 40;
      }
    }
    
    return totalScore / progress.length;
  }

  // ==================== MEAL PLANNING ASSISTANCE ====================
  
  /// Get suggested calorie distribution for meals
  static Map<String, double> getMealCalorieDistribution(double dailyCalorieTarget) {
    return {
      'breakfast': dailyCalorieTarget * 0.25, // 25%
      'lunch': dailyCalorieTarget * 0.35,     // 35%
      'dinner': dailyCalorieTarget * 0.30,    // 30%
      'snacks': dailyCalorieTarget * 0.10,    // 10%
    };
  }

  /// Get suggested macro distribution for a meal
  static Map<String, double> getMealMacroDistribution({
    required double mealCalories,
    required String mealType,
  }) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return {
          'protein': mealCalories * 0.20 / 4, // 20% protein
          'carbs': mealCalories * 0.50 / 4,   // 50% carbs
          'fat': mealCalories * 0.30 / 9,     // 30% fat
        };
      case 'lunch':
        return {
          'protein': mealCalories * 0.30 / 4, // 30% protein
          'carbs': mealCalories * 0.45 / 4,   // 45% carbs
          'fat': mealCalories * 0.25 / 9,     // 25% fat
        };
      case 'dinner':
        return {
          'protein': mealCalories * 0.35 / 4, // 35% protein
          'carbs': mealCalories * 0.35 / 4,   // 35% carbs
          'fat': mealCalories * 0.30 / 9,     // 30% fat
        };
      default: // snacks
        return {
          'protein': mealCalories * 0.25 / 4, // 25% protein
          'carbs': mealCalories * 0.45 / 4,   // 45% carbs
          'fat': mealCalories * 0.30 / 9,     // 30% fat
        };
    }
  }
}