// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/food_model.dart';
import '../models/meal_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      if (_currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .update(user.toFirestore());
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  // ==================== FOOD OPERATIONS ====================

  // Add custom food
  Future<String> addCustomFood(FoodModel food) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      // Add to global foods collection
      DocumentReference docRef = await _firestore
          .collection('foods')
          .add(food.toFirestore());

      // Also add to user's custom foods
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('custom_foods')
          .doc(docRef.id)
          .set(food.toFirestore());

      return docRef.id;
    } catch (e) {
      throw 'Failed to add custom food: $e';
    }
  }

  // Search foods by name
  Future<List<FoodModel>> searchFoods(String query) async {
    try {
      if (query.isEmpty) return [];

      // Search in global foods
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .limit(20)
          .get();

      List<FoodModel> foods = snapshot.docs
          .map((doc) => FoodModel.fromFirestore(doc))
          .toList();

      // Also search user's custom foods if authenticated
      if (_currentUserId != null) {
        QuerySnapshot customSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('custom_foods')
            .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
            .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
            .limit(10)
            .get();

        List<FoodModel> customFoods = customSnapshot.docs
            .map((doc) => FoodModel.fromFirestore(doc))
            .toList();

        foods.addAll(customFoods);
      }

      return foods;
    } catch (e) {
      throw 'Failed to search foods: $e';
    }
  }

  // Get food by barcode
  Future<FoodModel?> getFoodByBarcode(String barcode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FoodModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Failed to get food by barcode: $e';
    }
  }

  // Get popular foods
  Future<List<FoodModel>> getPopularFoods({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('isPopular', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get popular foods: $e';
    }
  }

  // Get foods by category
  Future<List<FoodModel>> getFoodsByCategory(String category, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('category', isEqualTo: category)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get foods by category: $e';
    }
  }

  // Get user's custom foods
  Future<List<FoodModel>> getUserCustomFoods() async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('custom_foods')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get user custom foods: $e';
    }
  }

  // ==================== MEAL OPERATIONS ====================

  // Add meal entry
  Future<String> addMeal(MealModel meal) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .add(meal.toFirestore());

      return docRef.id;
    } catch (e) {
      throw 'Failed to add meal: $e';
    }
  }

  // Update meal entry
  Future<void> updateMeal(String mealId, MealModel meal) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .doc(mealId)
          .update(meal.toFirestore());
    } catch (e) {
      throw 'Failed to update meal: $e';
    }
  }

  // Delete meal entry
  Future<void> deleteMeal(String mealId) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .doc(mealId)
          .delete();
    } catch (e) {
      throw 'Failed to delete meal: $e';
    }
  }

  // Get meals for specific date
  Future<List<MealModel>> getMealsForDate(DateTime date) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      // Get start and end of day
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get meals for date: $e';
    }
  }

  // Get meals for date range
  Future<List<MealModel>> getMealsForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get meals for date range: $e';
    }
  }

  // Get nutrition summary for date
  Future<Map<String, double>> getNutritionSummaryForDate(DateTime date) async {
    try {
      List<MealModel> meals = await getMealsForDate(date);
      
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalWater = 0;

      for (MealModel meal in meals) {
        totalCalories += meal.totalCalories;
        totalProtein += meal.totalProtein;
        totalCarbs += meal.totalCarbs;
        totalFat += meal.totalFat;
        totalFiber += meal.totalFiber;
        totalWater += meal.waterIntake;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
        'water': totalWater,
      };
    } catch (e) {
      throw 'Failed to get nutrition summary: $e';
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  // Get weight history
  Future<List<Map<String, dynamic>>> getWeightHistory({int days = 30}) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      DateTime startDate = DateTime.now().subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('weight_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'date': (data['date'] as Timestamp).toDate(),
          'weight': data['weight'].toDouble(),
        };
      }).toList();
    } catch (e) {
      throw 'Failed to get weight history: $e';
    }
  }

  // Log weight
  Future<void> logWeight(double weight, DateTime date) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('weight_logs')
          .add({
        'weight': weight,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.now(),
      });

      // Also update current weight in user profile
      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .update({
        'weight': weight,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Failed to log weight: $e';
    }
  }

  // Get recent foods (user's food history)
  Future<List<FoodModel>> getRecentFoods({int limit = 10}) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('recent_foods')
          .orderBy('lastUsed', descending: true)
          .limit(limit)
          .get();

      List<FoodModel> foods = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['foodData'] != null) {
          foods.add(FoodModel.fromMap(data['foodData']));
        }
      }

      return foods;
    } catch (e) {
      throw 'Failed to get recent foods: $e';
    }
  }

  // Update recent foods
  Future<void> updateRecentFood(FoodModel food) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('recent_foods')
          .doc(food.id)
          .set({
        'foodData': food.toFirestore(),
        'lastUsed': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore errors for recent foods update
    }
  }

  // ==================== UTILITIES ====================

  // Stream for real-time meals today
  Stream<List<MealModel>> streamMealsToday() {
    if (_currentUserId == null) return Stream.value([]);

    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MealModel.fromFirestore(doc))
            .toList());
  }

  // Stream for user profile
  Stream<UserModel?> streamUserProfile() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}