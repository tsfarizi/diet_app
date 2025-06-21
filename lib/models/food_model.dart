class FoodModel {
  final String id;
  final String name;
  final String brand; // Brand makanan (optional)
  final String category; // 'fruits', 'vegetables', 'grains', 'protein', 'dairy', 'snacks', etc.
  final String? barcode; // Barcode untuk scan
  final String? imageUrl;
  final NutritionInfo nutritionPer100g; // Nutrisi per 100g
  final List<String> servingSizes; // ['1 buah', '100g', '1 slice', etc.]
  final bool isVerified; // Apakah data sudah diverifikasi
  final bool isCustom; // Apakah ini makanan custom user
  final String? createdBy; // User ID yang buat (untuk custom food)
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodModel({
    required this.id,
    required this.name,
    this.brand = '',
    required this.category,
    this.barcode,
    this.imageUrl,
    required this.nutritionPer100g,
    required this.servingSizes,
    this.isVerified = false,
    this.isCustom = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore
  factory FoodModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FoodModel(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? 'other',
      barcode: data['barcode'],
      imageUrl: data['imageUrl'],
      nutritionPer100g: NutritionInfo.fromMap(data['nutritionPer100g'] ?? {}),
      servingSizes: List<String>.from(data['servingSizes'] ?? ['100g']),
      isVerified: data['isVerified'] ?? false,
      isCustom: data['isCustom'] ?? false,
      createdBy: data['createdBy'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'nutritionPer100g': nutritionPer100g.toMap(),
      'servingSizes': servingSizes,
      'isVerified': isVerified,
      'isCustom': isCustom,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Get display name (dengan brand jika ada)
  String get displayName {
    return brand.isNotEmpty ? '$brand $name' : name;
  }

  // Calculate nutrition for specific amount
  NutritionInfo calculateNutrition(double grams) {
    double multiplier = grams / 100;
    return NutritionInfo(
      calories: nutritionPer100g.calories * multiplier,
      protein: nutritionPer100g.protein * multiplier,
      carbs: nutritionPer100g.carbs * multiplier,
      fat: nutritionPer100g.fat * multiplier,
      fiber: nutritionPer100g.fiber * multiplier,
      sugar: nutritionPer100g.sugar * multiplier,
      sodium: nutritionPer100g.sodium * multiplier,
    );
  }

  // Copy with method for updates
  FoodModel copyWith({
    String? name,
    String? brand,
    String? category,
    String? barcode,
    String? imageUrl,
    NutritionInfo? nutritionPer100g,
    List<String>? servingSizes,
    bool? isVerified,
    bool? isCustom,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionPer100g: nutritionPer100g ?? this.nutritionPer100g,
      servingSizes: servingSizes ?? this.servingSizes,
      isVerified: isVerified ?? this.isVerified,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Class untuk informasi nutrisi
class NutritionInfo {
  final double calories;
  final double protein; // gram
  final double carbs; // gram
  final double fat; // gram
  final double fiber; // gram
  final double sugar; // gram
  final double sodium; // mg

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  // Convert from Map
  factory NutritionInfo.fromMap(Map<String, dynamic> data) {
    return NutritionInfo(
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      fiber: (data['fiber'] ?? 0).toDouble(),
      sugar: (data['sugar'] ?? 0).toDouble(),
      sodium: (data['sodium'] ?? 0).toDouble(),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  // Add two nutrition infos
  NutritionInfo operator +(NutritionInfo other) {
    return NutritionInfo(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sugar: sugar + other.sugar,
      sodium: sodium + other.sodium,
    );
  }

  // Multiply nutrition by factor
  NutritionInfo operator *(double factor) {
    return NutritionInfo(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      sodium: sodium * factor,
    );
  }

  // Get macronutrient percentages
  Map<String, double> get macroPercentages {
    double totalCalories = calories;
    if (totalCalories == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    
    return {
      'protein': (protein * 4) / totalCalories * 100, // 1g protein = 4 cal
      'carbs': (carbs * 4) / totalCalories * 100, // 1g carbs = 4 cal
      'fat': (fat * 9) / totalCalories * 100, // 1g fat = 9 cal
    };
  }
}

// Enum untuk kategori makanan
enum FoodCategory {
  fruits('Buah-buahan'),
  vegetables('Sayuran'),
  grains('Karbohidrat'),
  protein('Protein'),
  dairy('Susu & Olahan'),
  snacks('Cemilan'),
  beverages('Minuman'),
  fastFood('Fast Food'),
  other('Lainnya');

  const FoodCategory(this.displayName);
  final String displayName;
}