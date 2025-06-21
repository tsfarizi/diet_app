import 'food_model.dart';

class MealModel {
  final String id;
  final String userId;
  final DateTime date; // Tanggal makan (YYYY-MM-DD)
  final MealType mealType; // breakfast, lunch, dinner, snack
  final List<FoodEntry> foods;
  final String? notes; // Catatan user
  final String? imageUrl; // Foto makanan
  final DateTime createdAt;
  final DateTime updatedAt;

  MealModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foods,
    this.notes,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore
  factory MealModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MealModel(
      id: id,
      userId: data['userId'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.breakfast,
      ),
      foods: (data['foods'] as List<dynamic>?)
          ?.map((food) => FoodEntry.fromMap(food))
          .toList() ?? [],
      notes: data['notes'],
      imageUrl: data['imageUrl'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'mealType': mealType.name,
      'foods': foods.map((food) => food.toMap()).toList(),
      'notes': notes,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Calculate total nutrition for this meal
  NutritionInfo get totalNutrition {
    return foods.fold(
      NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      (total, foodEntry) => total + foodEntry.nutrition,
    );
  }

  // Get total calories
  double get totalCalories => totalNutrition.calories;

  // Get date string for display
  String get dateString {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get meal time display
  String get mealTimeDisplay {
    switch (mealType) {
      case MealType.breakfast:
        return 'Sarapan';
      case MealType.lunch:
        return 'Makan Siang';
      case MealType.dinner:
        return 'Makan Malam';
      case MealType.snack:
        return 'Cemilan';
    }
  }

  // Add food to meal
  MealModel addFood(FoodEntry foodEntry) {
    List<FoodEntry> newFoods = List.from(foods)..add(foodEntry);
    return copyWith(foods: newFoods);
  }

  // Remove food from meal
  MealModel removeFood(String foodEntryId) {
    List<FoodEntry> newFoods = foods.where((f) => f.id != foodEntryId).toList();
    return copyWith(foods: newFoods);
  }

  // Update food entry
  MealModel updateFood(String foodEntryId, FoodEntry updatedFoodEntry) {
    List<FoodEntry> newFoods = foods.map((f) {
      return f.id == foodEntryId ? updatedFoodEntry : f;
    }).toList();
    return copyWith(foods: newFoods);
  }

  // Copy with method for updates
  MealModel copyWith({
    String? userId,
    DateTime? date,
    MealType? mealType,
    List<FoodEntry>? foods,
    String? notes,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return MealModel(
      id: id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foods: foods ?? this.foods,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Class untuk entry makanan dalam meal
class FoodEntry {
  final String id;
  final FoodModel food;
  final double amount; // dalam gram
  final String servingSize; // '100g', '1 buah', etc.
  final NutritionInfo nutrition; // Nutrition untuk amount ini
  final DateTime addedAt;

  FoodEntry({
    required this.id,
    required this.food,
    required this.amount,
    required this.servingSize,
    required this.nutrition,
    required this.addedAt,
  });

  // Factory constructor untuk membuat food entry
  factory FoodEntry.create({
    required FoodModel food,
    required double amount,
    required String servingSize,
  }) {
    String id = DateTime.now().millisecondsSinceEpoch.toString();
    NutritionInfo nutrition = food.calculateNutrition(amount);
    
    return FoodEntry(
      id: id,
      food: food,
      amount: amount,
      servingSize: servingSize,
      nutrition: nutrition,
      addedAt: DateTime.now(),
    );
  }

  // Convert from Map
  factory FoodEntry.fromMap(Map<String, dynamic> data) {
    return FoodEntry(
      id: data['id'] ?? '',
      food: FoodModel.fromFirestore(data['food'], data['food']['id'] ?? ''),
      amount: (data['amount'] ?? 0).toDouble(),
      servingSize: data['servingSize'] ?? '100g',
      nutrition: NutritionInfo.fromMap(data['nutrition'] ?? {}),
      addedAt: DateTime.parse(data['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food': food.toFirestore(),
      'amount': amount,
      'servingSize': servingSize,
      'nutrition': nutrition.toMap(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Update amount and recalculate nutrition
  FoodEntry updateAmount(double newAmount, String newServingSize) {
    return FoodEntry(
      id: id,
      food: food,
      amount: newAmount,
      servingSize: newServingSize,
      nutrition: food.calculateNutrition(newAmount),
      addedAt: addedAt,
    );
  }
}

// Enum untuk tipe meal
enum MealType {
  breakfast('breakfast', 'Sarapan', '🌅'),
  lunch('lunch', 'Makan Siang', '☀️'),
  dinner('dinner', 'Makan Malam', '🌙'),
  snack('snack', 'Cemilan', '🍪');

  const MealType(this.name, this.displayName, this.icon);
  final String name;
  final String displayName;
  final String icon;
}

// Class untuk daily summary
class DailySummary {
  final String userId;
  final DateTime date;
  final List<MealModel> meals;
  final NutritionInfo totalNutrition;
  final int targetCalories;
  final double waterIntake; // dalam liter
  final double? weight; // berat badan hari itu (optional)
  final String? notes; // catatan harian

  DailySummary({
    required this.userId,
    required this.date,
    required this.meals,
    required this.totalNutrition,
    required this.targetCalories,
    this.waterIntake = 0,
    this.weight,
    this.notes,
  });

  // Calculate from meals
  factory DailySummary.fromMeals({
    required String userId,
    required DateTime date,
    required List<MealModel> meals,
    required int targetCalories,
    double waterIntake = 0,
    double? weight,
    String? notes,
  }) {
    NutritionInfo totalNutrition = meals.fold(
      NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      (total, meal) => total + meal.totalNutrition,
    );

    return DailySummary(
      userId: userId,
      date: date,
      meals: meals,
      totalNutrition: totalNutrition,
      targetCalories: targetCalories,
      waterIntake: waterIntake,
      weight: weight,
      notes: notes,
    );
  }

  // Get remaining calories
  double get remainingCalories {
    return targetCalories - totalNutrition.calories;
  }

  // Get calorie progress percentage
  double get calorieProgress {
    return (totalNutrition.calories / targetCalories * 100).clamp(0, 100);
  }

  // Get meals by type
  List<MealModel> getMealsByType(MealType type) {
    return meals.where((meal) => meal.mealType == type).toList();
  }

  // Check if target achieved
  bool get isTargetAchieved {
    return totalNutrition.calories >= targetCalories * 0.9 && 
           totalNutrition.calories <= targetCalories * 1.1;
  }
}