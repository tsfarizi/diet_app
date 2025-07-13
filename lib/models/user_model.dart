class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final double weight; // kg
  final double height; // cm  
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String goal; // 'lose_weight', 'maintain', 'gain_weight'
  final double targetWeight; // kg
  final int dailyCalorieTarget; // Legacy field, masih dipakai untuk backward compatibility
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.targetWeight,
    required this.dailyCalorieTarget,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      gender: data['gender'] ?? 'male',
      activityLevel: data['activityLevel'] ?? 'sedentary',
      goal: data['goal'] ?? 'maintain',
      targetWeight: (data['targetWeight'] ?? 0).toDouble(),
      dailyCalorieTarget: data['dailyCalorieTarget'] ?? 2000,
      profileImageUrl: data['profileImageUrl'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'targetWeight': targetWeight,
      'dailyCalorieTarget': dailyCalorieTarget,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Calculate BMI
  double get bmi => weight / ((height / 100) * (height / 100));

  // Get BMI category
  String get bmiCategory {
    double bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Calculate BMR using Mifflin St Jeor equation (lebih akurat)
  double get bmr {
    if (gender == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double get dailyCalorieNeeds {
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    return bmr * multiplier;
  }

  // Calculate target kalori untuk weight loss (deficit untuk turun berat)
  double get calculatedCalorieTarget {
    double tdee = dailyCalorieNeeds;
    double currentBmi = bmi;
    
    // Adjust deficit berdasarkan BMI untuk safety
    if (currentBmi > 30) {
      return tdee - 750; // Deficit 750 kcal untuk obesitas (turun 0.75kg/minggu)
    } else if (currentBmi > 25) {
      return tdee - 500; // Deficit 500 kcal untuk overweight (turun 0.5kg/minggu) 
    } else {
      return tdee - 300; // Deficit 300 kcal untuk normal BMI (turun 0.3kg/minggu)
    }
  }

  // Calculate target protein untuk weight loss (preserve muscle mass)
  double get calculatedProteinTarget {
    return weight * 1.6; // 1.6g per kg untuk cutting (mencegah kehilangan otot)
  }

  // Calculate target air berdasarkan berat badan
  double get calculatedWaterTarget {
    double baseWater = weight * 35; // 35ml per kg berat badan
    
    // Tambah air berdasarkan activity level
    switch (activityLevel) {
      case 'active':
      case 'very_active':
        return baseWater + 500; // Tambah 500ml untuk yang aktif
      case 'moderate':
        return baseWater + 250; // Tambah 250ml untuk yang moderat
      default:
        return baseWater;
    }
  }

  // Calculate target karbo berdasarkan kalori dan protein
  double get calculatedCarbTarget {
    double proteinCalories = calculatedProteinTarget * 4; // 1g protein = 4 kcal
    double fatCalories = calculatedCalorieTarget * 0.25; // 25% dari kalori total untuk lemak
    double carbCalories = calculatedCalorieTarget - proteinCalories - fatCalories;
    return carbCalories / 4; // 1g carb = 4 kcal
  }

  // Calculate target lemak
  double get calculatedFatTarget {
    return (calculatedCalorieTarget * 0.25) / 9; // 25% kalori total, 1g fat = 9 kcal
  }

  // Check apakah semua data lengkap untuk calculation
  bool get isDataComplete {
    return age > 0 && weight > 0 && height > 0 && targetWeight > 0;
  }

  // Helper method untuk guidance activity level
  String getActivityLevelGuidance(String level) {
    switch (level) {
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

  // Get activity level description untuk display
  String get activityLevelDescription {
    return getActivityLevelGuidance(activityLevel);
  }

  // Calculate impact kalori kalau ganti activity level
  double getCalorieImpactIfChange(String newActivityLevel) {
    if (newActivityLevel == activityLevel) return 0;
    
    // Calculate TDEE with new activity level
    double multiplier;
    switch (newActivityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    
    double newTdee = bmr * multiplier;
    double newCalorieTarget = _calculateCalorieTargetForTdee(newTdee);
    
    return newCalorieTarget - calculatedCalorieTarget;
  }

  // Helper untuk calculate calorie target dari TDEE
  double _calculateCalorieTargetForTdee(double tdee) {
    double currentBmi = bmi;
    
    if (currentBmi > 30) {
      return tdee - 750;
    } else if (currentBmi > 25) {
      return tdee - 500;
    } else {
      return tdee - 300;
    }
  }

  // Validation apakah activity level realistic
  bool isActivityLevelRealistic() {
    // Check kalau umur > 50 tapi claim very active
    if (activityLevel == 'very_active' && age > 50) {
      return false;
    }
    
    // Check kalau target kalori terlalu rendah (bahaya)
    if (calculatedCalorieTarget < 1200) {
      return false;
    }
    
    return true;
  }

  // Get warning message kalau activity level tidak realistic
  String? getActivityLevelWarning() {
    if (activityLevel == 'very_active' && age > 50) {
      return 'Apakah yakin olahraga 2x/hari di usia $age tahun? Pertimbangkan turun ke "Active"';
    }
    
    if (calculatedCalorieTarget < 1200) {
      return 'Target kalori terlalu rendah (${calculatedCalorieTarget.round()} kcal). Coba naikkan aktivitas atau kurangi deficit.';
    }
    
    return null;
  }

  // Calculate estimasi turun berat per minggu
  double get estimatedWeightLossPerWeek {
    double deficit = dailyCalorieNeeds - calculatedCalorieTarget;
    return (deficit * 7) / 7700; // 7700 kcal = 1kg lemak
  }

  // Calculate estimasi waktu mencapai target berat
  int get estimatedWeeksToTarget {
    if (targetWeight >= weight) return 0;
    
    double weightToLose = weight - targetWeight;
    double weeklyLoss = estimatedWeightLossPerWeek;
    
    if (weeklyLoss <= 0) return 0;
    
    return (weightToLose / weeklyLoss).ceil();
  }

  // Get progress percentage ke target berat
  double getWeightProgress(double startWeight) {
    if (startWeight <= targetWeight) return 100.0;
    
    double totalToLose = startWeight - targetWeight;
    double alreadyLost = startWeight - weight;
    
    return (alreadyLost / totalToLose * 100).clamp(0.0, 100.0);
  }

  // Copy with method for updates
  UserModel copyWith({
    String? email,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
    double? targetWeight,
    int? dailyCalorieTarget,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}