import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/user_model.dart';
import '../models/food_model.dart';
import '../models/meal_model.dart';
import '../models/walking_session_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getUserProfile() async {
    try {
      if (_currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

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

  Stream<UserModel?> streamUserProfile() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                )
              : null,
        )
        .handleError((error) {
          print('❌ Error in streamUserProfile: $error');
          return null;
        });
  }

  Future<Map<String, dynamic>> getTodayProgress() async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null || !userProfile.isDataComplete) {
        return {'error': 'Profile incomplete', 'isComplete': false};
      }

      final today = DateTime.now();
      final nutritionSummary = await getNutritionSummaryForDate(today);
      final waterIntake = await getWaterIntakeForDate(today);
      final cardioCalories = await getCardioCaloriesForDate(today);
      final totalSteps = await getStepsForDate(today);

      return {
        'isComplete': true,
        'user': userProfile,
        'actual': {
          'calories': nutritionSummary['calories'] ?? 0.0,
          'protein': nutritionSummary['protein'] ?? 0.0,
          'carbs': nutritionSummary['carbs'] ?? 0.0,
          'fat': nutritionSummary['fat'] ?? 0.0,
          'water': waterIntake,
          'exerciseCalories': cardioCalories,
          'steps': totalSteps,
        },
        'targets': {
          'calories': userProfile.calculatedCalorieTarget,
          'protein': userProfile.calculatedProteinTarget,
          'carbs': userProfile.calculatedCarbTarget,
          'fat': userProfile.calculatedFatTarget,
          'water': userProfile.calculatedWaterTarget,
          'steps': 8000,
        },
        'progress': {
          'calories':
              (nutritionSummary['calories'] ?? 0.0) /
              userProfile.calculatedCalorieTarget,
          'protein':
              (nutritionSummary['protein'] ?? 0.0) /
              userProfile.calculatedProteinTarget,
          'carbs':
              (nutritionSummary['carbs'] ?? 0.0) /
              userProfile.calculatedCarbTarget,
          'fat':
              (nutritionSummary['fat'] ?? 0.0) /
              userProfile.calculatedFatTarget,
          'water': waterIntake / userProfile.calculatedWaterTarget,
          'steps': totalSteps / 8000.0,
        },
      };
    } catch (e) {
      throw 'Failed to get today progress: $e';
    }
  }

  Stream<Map<String, dynamic>> streamTodayProgress() {
    return streamProgressForDate(DateTime.now());
  }

  Future<List<Map<String, dynamic>>> getWeeklyProgressSummary() async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null || !userProfile.isDataComplete) return [];

      final now = DateTime.now();
      final weeklyData = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final nutritionSummary = await getNutritionSummaryForDate(date);
        final waterIntake = await getWaterIntakeForDate(date);
        final cardioCalories = await getCardioCaloriesForDate(date);
        final totalSteps = await getStepsForDate(date);

        weeklyData.add({
          'date': date,
          'dayName': _getDayName(date.weekday),
          'actual': {
            'calories': nutritionSummary['calories'] ?? 0.0,
            'protein': nutritionSummary['protein'] ?? 0.0,
            'water': waterIntake,
            'exerciseCalories': cardioCalories,
            'steps': totalSteps,
          },
          'targets': {
            'calories': userProfile.calculatedCalorieTarget,
            'protein': userProfile.calculatedProteinTarget,
            'water': userProfile.calculatedWaterTarget,
            'steps': 8000,
          },
          'progress': {
            'calories':
                (nutritionSummary['calories'] ?? 0.0) /
                userProfile.calculatedCalorieTarget,
            'protein':
                (nutritionSummary['protein'] ?? 0.0) /
                userProfile.calculatedProteinTarget,
            'water': waterIntake / userProfile.calculatedWaterTarget,
            'steps': totalSteps / 8000.0,
          },
        });
      }

      return weeklyData;
    } catch (e) {
      throw 'Failed to get weekly progress: $e';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  Future<void> saveWalkingSession(WalkingSession session) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('walking_sessions')
          .doc(session.id)
          .set(session.toMap());

      print('✅ Walking session saved to database: ${session.id}');
    } catch (e) {
      print('❌ Failed to save walking session: $e');
      throw 'Failed to save walking session: $e';
    }
  }

  Future<List<WalkingSession>> getWalkingSessionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('walking_sessions')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('startTime', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('startTime', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => WalkingSession.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ Failed to get walking sessions: $e');
      return [];
    }
  }

  Stream<List<WalkingSession>> streamWalkingSessionsToday() {
    return streamWalkingSessionsForDate(DateTime.now());
  }

  Future<double> getCardioCaloriesForDate(DateTime date) async {
    try {
      if (_currentUserId == null) return 0.0;

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final walkingCalories = await _getWalkingCaloriesForDate(
        startOfDay,
        endOfDay,
      );

      return walkingCalories;
    } catch (e) {
      print('❌ Failed to get cardio calories: $e');
      return 0.0;
    }
  }

  Future<double> _getWalkingCaloriesForDate(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('walking_sessions')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where('startTime', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      double totalCalories = 0.0;
      for (var doc in snapshot.docs) {
        final session = WalkingSession.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        totalCalories += session.calories;
      }

      return totalCalories;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> getStepsForDate(DateTime date) async {
    try {
      if (_currentUserId == null) return 0;

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('walking_sessions')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where('startTime', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      int totalSteps = 0;
      for (var doc in snapshot.docs) {
        final session = WalkingSession.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        totalSteps += session.steps;
      }

      return totalSteps;
    } catch (e) {
      print('❌ Failed to get steps: $e');
      return 0;
    }
  }

  Stream<Map<String, dynamic>> streamTodayCardioStats() {
    return streamCardioStatsForDate(DateTime.now());
  }

  Future<void> addWaterIntake(double amount) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      DateTime today = DateTime.now();
      String dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      DocumentReference docRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('water_intake')
          .doc(dateKey);

      DocumentSnapshot doc = await docRef.get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double currentAmount = (data['totalAmount'] ?? 0).toDouble();
        List<dynamic> intakes = data['intakes'] ?? [];

        intakes.add({'amount': amount, 'timestamp': Timestamp.now()});

        await docRef.update({
          'totalAmount': currentAmount + amount,
          'intakes': intakes,
          'updatedAt': Timestamp.now(),
        });
      } else {
        await docRef.set({
          'date': dateKey,
          'totalAmount': amount,
          'intakes': [
            {'amount': amount, 'timestamp': Timestamp.now()},
          ],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw 'Failed to add water intake: $e';
    }
  }

  Future<double> getWaterIntakeForDate(DateTime date) async {
    try {
      if (_currentUserId == null) return 0.0;

      String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('water_intake')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return (data['totalAmount'] ?? 0).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Stream<double> streamWaterIntakeToday() {
    return streamWaterIntakeForDate(DateTime.now());
  }

  Future<List<Map<String, dynamic>>> getWaterIntakeHistory({
    int days = 7,
  }) async {
    try {
      if (_currentUserId == null) return [];

      final List<Map<String, dynamic>> waterHistory = [];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final amount = await getWaterIntakeForDate(date);

        waterHistory.add({'date': date, 'totalAmount': amount / 1000});
      }

      return waterHistory;
    } catch (e) {
      return [];
    }
  }

  Future<String> addCustomFood(FoodModel food) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      DocumentReference docRef = await _firestore
          .collection('foods')
          .add(food.toFirestore());

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

  Future<List<FoodModel>> searchFoods(String query) async {
    try {
      if (query.isEmpty) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      List<FoodModel> foods = snapshot.docs
          .map(
            (doc) => FoodModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      if (_currentUserId != null) {
        QuerySnapshot customSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('custom_foods')
            .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
            .where('name', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
            .limit(10)
            .get();

        List<FoodModel> customFoods = customSnapshot.docs
            .map(
              (doc) => FoodModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        foods.addAll(customFoods);
      }

      return foods;
    } catch (e) {
      throw 'Failed to search foods: $e';
    }
  }

  Future<FoodModel?> getFoodByBarcode(String barcode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FoodModel.fromFirestore(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      throw 'Failed to get food by barcode: $e';
    }
  }

  Future<List<FoodModel>> getPopularFoods({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('isPopular', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => FoodModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get popular foods: $e';
    }
  }

  Future<List<FoodModel>> getFoodsByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foods')
          .where('category', isEqualTo: category)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => FoodModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get foods by category: $e';
    }
  }

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
          .map(
            (doc) => FoodModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get user custom foods: $e';
    }
  }

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
          foods.add(
            FoodModel.fromFirestore(
              data['foodData'] as Map<String, dynamic>,
              doc.id,
            ),
          );
        }
      }

      return foods;
    } catch (e) {
      throw 'Failed to get recent foods: $e';
    }
  }

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
    } catch (e) {}
  }

  Future<String> addMeal(MealModel meal) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('meals')
          .add(meal.toFirestore());

      for (var mealFood in meal.foods) {
        await updateRecentFood(mealFood.food);
      }

      return docRef.id;
    } catch (e) {
      throw 'Failed to add meal: $e';
    }
  }

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

  Future<List<MealModel>> getMealsForDate(DateTime date) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

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
          .map(
            (doc) => MealModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get meals for date: $e';
    }
  }

  Future<List<MealModel>> getMealsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
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
          .map(
            (doc) => MealModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw 'Failed to get meals for date range: $e';
    }
  }

  Stream<List<MealModel>> streamMealsToday() {
    return streamMealsForDate(DateTime.now());
  }

  Future<Map<String, double>> getNutritionSummaryForDate(DateTime date) async {
    try {
      List<MealModel> meals = await getMealsForDate(date);

      double totalCalories = 0,
          totalProtein = 0,
          totalCarbs = 0,
          totalFat = 0,
          totalFiber = 0,
          totalSugar = 0;

      for (MealModel meal in meals) {
        NutritionInfo nutrition = meal.totalNutrition;
        totalCalories += nutrition.calories;
        totalProtein += nutrition.protein;
        totalCarbs += nutrition.carbs;
        totalFat += nutrition.fat;
        totalFiber += nutrition.fiber;
        totalSugar += nutrition.sugar;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
        'sugar': totalSugar,
      };
    } catch (e) {
      throw 'Failed to get nutrition summary: $e';
    }
  }

  Future<Map<String, dynamic>> getDetailedNutritionAnalysis(
    DateTime date,
  ) async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null || !userProfile.isDataComplete) {
        return {'error': 'Profile incomplete'};
      }

      final nutritionSummary = await getNutritionSummaryForDate(date);
      final waterIntake = await getWaterIntakeForDate(date);
      final cardioCalories = await getCardioCaloriesForDate(date);
      final totalSteps = await getStepsForDate(date);

      return {
        'date': date,
        'user': userProfile,
        'nutrition': nutritionSummary,
        'waterIntake': waterIntake,
        'exerciseCalories': cardioCalories,
        'totalSteps': totalSteps,
        'targets': {
          'calories': userProfile.calculatedCalorieTarget,
          'protein': userProfile.calculatedProteinTarget,
          'carbs': userProfile.calculatedCarbTarget,
          'fat': userProfile.calculatedFatTarget,
          'water': userProfile.calculatedWaterTarget,
          'steps': 8000,
        },
        'achievements': {
          'calories':
              (nutritionSummary['calories'] ?? 0.0) >=
              userProfile.calculatedCalorieTarget * 0.9,
          'protein':
              (nutritionSummary['protein'] ?? 0.0) >=
              userProfile.calculatedProteinTarget * 0.9,
          'water': waterIntake >= userProfile.calculatedWaterTarget * 0.9,
          'cardio': cardioCalories >= 200.0,
          'steps': totalSteps >= 8000,
        },
        'deficits': {
          'calories':
              userProfile.calculatedCalorieTarget -
              (nutritionSummary['calories'] ?? 0.0),
          'protein':
              userProfile.calculatedProteinTarget -
              (nutritionSummary['protein'] ?? 0.0),
          'water': userProfile.calculatedWaterTarget - waterIntake,
          'steps': 8000 - totalSteps,
        },
      };
    } catch (e) {
      throw 'Failed to get detailed nutrition analysis: $e';
    }
  }

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

      await _firestore.collection('users').doc(_currentUserId!).update({
        'weight': weight,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Failed to log weight: $e';
    }
  }

  Future<Map<String, dynamic>> getWeightProgressAnalysis() async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null || !userProfile.isDataComplete) {
        return {'error': 'Profile incomplete'};
      }

      final weightHistory = await getWeightHistory(days: 90);

      if (weightHistory.isEmpty) {
        return {
          'currentWeight': userProfile.weight,
          'targetWeight': userProfile.targetWeight,
          'totalToLose': userProfile.weight - userProfile.targetWeight,
          'estimatedWeeks': userProfile.estimatedWeeksToTarget,
          'estimatedWeeklyLoss': userProfile.estimatedWeightLossPerWeek,
          'hasHistory': false,
        };
      }

      final latestWeight = weightHistory.last['weight'] as double;
      final startWeight = weightHistory.first['weight'] as double;
      final weightLost = startWeight - latestWeight;
      final daysTracked = weightHistory.length;

      return {
        'currentWeight': latestWeight,
        'startWeight': startWeight,
        'targetWeight': userProfile.targetWeight,
        'weightLost': weightLost,
        'totalToLose': userProfile.weight - userProfile.targetWeight,
        'remainingToLose': latestWeight - userProfile.targetWeight,
        'progressPercentage':
            weightLost / (startWeight - userProfile.targetWeight) * 100,
        'averageWeeklyLoss': weightLost / (daysTracked / 7),
        'estimatedWeeks': userProfile.estimatedWeeksToTarget,
        'hasHistory': true,
        'isOnTrack':
            weightLost / (daysTracked / 7) >=
            userProfile.estimatedWeightLossPerWeek * 0.8,
      };
    } catch (e) {
      throw 'Failed to get weight progress analysis: $e';
    }
  }

  Future<Map<String, int>> getUserStreaks() async {
    try {
      final now = DateTime.now();
      int mealStreak = 0, waterStreak = 0, deficitStreak = 0, cardioStreak = 0;

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final meals = await getMealsForDate(date);
        if (meals.length >= 3) {
          mealStreak++;
        } else {
          break;
        }
      }

      final userProfile = await getUserProfile();
      if (userProfile != null && userProfile.isDataComplete) {
        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          final waterIntake = await getWaterIntakeForDate(date);
          if (waterIntake >= userProfile.calculatedWaterTarget * 0.8) {
            waterStreak++;
          } else {
            break;
          }
        }

        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          final nutrition = await getNutritionSummaryForDate(date);
          final calories = nutrition['calories'] ?? 0.0;
          final target = userProfile.calculatedCalorieTarget;
          if (calories >= target * 0.9 && calories <= target * 1.1) {
            deficitStreak++;
          } else {
            break;
          }
        }

        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          final cardioCalories = await getCardioCaloriesForDate(date);
          if (cardioCalories >= 100.0) {
            cardioStreak++;
          } else {
            break;
          }
        }
      }

      return {
        'mealTracking': mealStreak,
        'waterIntake': waterStreak,
        'calorieDeficit': deficitStreak,
        'cardio': cardioStreak,
      };
    } catch (e) {
      return {
        'mealTracking': 0,
        'waterIntake': 0,
        'calorieDeficit': 0,
        'cardio': 0,
      };
    }
  }

  Stream<Map<String, dynamic>> streamProgressForDate(DateTime date) {
    if (_currentUserId == null)
      return Stream.value({'error': 'Not authenticated'});

    return streamUserProfile()
        .where((profile) => profile != null)
        .cast<UserModel>()
        .switchMap((userProfile) {
          if (!userProfile.isDataComplete) {
            return Stream.value({
              'error': 'Profile incomplete',
              'isComplete': false,
            });
          }

          return Rx.combineLatest3(
            streamMealsForDate(date),
            streamWaterIntakeForDate(date),
            streamWalkingSessionsForDate(date),
            (
              List<MealModel> meals,
              double water,
              List<WalkingSession> walkingSessions,
            ) {
              try {
                double totalCalories = 0,
                    totalProtein = 0,
                    totalCarbs = 0,
                    totalFat = 0;

                for (var meal in meals) {
                  final nutrition = meal.totalNutrition;
                  totalCalories += nutrition.calories;
                  totalProtein += nutrition.protein;
                  totalCarbs += nutrition.carbs;
                  totalFat += nutrition.fat;
                }

                double cardioCalories = 0.0;
                int totalSteps = 0;
                int totalWorkouts = 0;

                for (var session in walkingSessions) {
                  cardioCalories += session.calories;
                  totalSteps += session.steps;
                  totalWorkouts++;
                }

                return {
                  'isComplete': true,
                  'user': userProfile,
                  'actual': {
                    'calories': totalCalories,
                    'protein': totalProtein,
                    'carbs': totalCarbs,
                    'fat': totalFat,
                    'water': water,
                    'exerciseCalories': cardioCalories,
                    'steps': totalSteps,
                    'workouts': totalWorkouts,
                  },
                  'targets': {
                    'calories': userProfile.calculatedCalorieTarget,
                    'protein': userProfile.calculatedProteinTarget,
                    'carbs': userProfile.calculatedCarbTarget,
                    'fat': userProfile.calculatedFatTarget,
                    'water': userProfile.calculatedWaterTarget,
                    'steps': 8000,
                    'workouts': 3,
                  },
                  'progress': {
                    'calories': userProfile.calculatedCalorieTarget > 0
                        ? totalCalories / userProfile.calculatedCalorieTarget
                        : 0.0,
                    'protein': userProfile.calculatedProteinTarget > 0
                        ? totalProtein / userProfile.calculatedProteinTarget
                        : 0.0,
                    'carbs': userProfile.calculatedCarbTarget > 0
                        ? totalCarbs / userProfile.calculatedCarbTarget
                        : 0.0,
                    'fat': userProfile.calculatedFatTarget > 0
                        ? totalFat / userProfile.calculatedFatTarget
                        : 0.0,
                    'water': userProfile.calculatedWaterTarget > 0
                        ? water / userProfile.calculatedWaterTarget
                        : 0.0,
                    'steps': totalSteps / 8000.0,
                    'workouts': totalWorkouts / 3.0,
                  },
                };
              } catch (error) {
                print('❌ Stream error in streamProgressForDate: $error');
                return {
                  'error': 'Failed to load progress data',
                  'isComplete': false,
                  'details': error.toString(),
                };
              }
            },
          );
        });
  }

  Stream<List<MealModel>> streamMealsForDate(DateTime date) {
    if (_currentUserId == null) return Stream.value([]);

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => MealModel.fromFirestore(doc.data(), doc.id))
                .toList();
          } catch (e) {
            print('❌ Error in streamMealsForDate: $e');
            return <MealModel>[];
          }
        });
  }

  Stream<double> streamWaterIntakeForDate(DateTime date) {
    if (_currentUserId == null) return Stream.value(0.0);

    String dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('water_intake')
        .doc(dateKey)
        .snapshots()
        .map((doc) {
          try {
            return doc.exists
                ? (doc.data()!['totalAmount'] ?? 0.0).toDouble()
                : 0.0;
          } catch (e) {
            print('❌ Error in streamWaterIntakeForDate: $e');
            return 0.0;
          }
        });
  }

  Stream<Map<String, dynamic>> streamCardioStatsForDate(DateTime date) {
    if (_currentUserId == null)
      return Stream.value({'calories': 0.0, 'steps': 0, 'workouts': 0});

    return streamWalkingSessionsForDate(date).map((
      List<WalkingSession> walkingSessions,
    ) {
      try {
        double totalCalories = 0.0;
        int totalSteps = 0;
        double totalDistance = 0.0;
        int totalDuration = 0;
        int totalWorkouts = 0;

        for (var session in walkingSessions) {
          totalCalories += session.calories;
          totalSteps += session.steps;
          totalDistance += session.distance;
          totalDuration += (session.duration / 60).round();
          totalWorkouts++;
        }

        return {
          'calories': totalCalories,
          'steps': totalSteps,
          'distance': totalDistance,
          'duration': totalDuration,
          'workouts': totalWorkouts,
          'walkingSessions': walkingSessions.length,
        };
      } catch (e) {
        print('❌ Error in streamCardioStatsForDate: $e');
        return {
          'calories': 0.0,
          'steps': 0,
          'distance': 0.0,
          'duration': 0,
          'workouts': 0,
          'walkingSessions': 0,
        };
      }
    });
  }

  Stream<Map<String, dynamic>> streamExerciseStatsForDate(DateTime date) {
    return streamCardioStatsForDate(date);
  }

  Stream<List<WalkingSession>> streamWalkingSessionsForDate(DateTime date) {
    if (_currentUserId == null) return Stream.value([]);

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection('walking_sessions')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where('startTime', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => WalkingSession.fromMap(doc.data()))
                .toList();
          } catch (e) {
            print('❌ Error in streamWalkingSessionsForDate: $e');
            return <WalkingSession>[];
          }
        });
  }

  Future<Map<String, dynamic>> getCardioStatisticsForDate(DateTime date) async {
    try {
      final walkingSessions = await getWalkingSessionsForDateRange(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      double totalCalories = 0.0;
      int totalDuration = 0;
      int totalSteps = 0;
      int totalWorkouts = 0;

      for (var session in walkingSessions) {
        totalCalories += session.calories;
        totalDuration += (session.duration / 60).round();
        totalSteps += session.steps;
        totalWorkouts++;
      }

      return {
        'totalCalories': totalCalories,
        'totalDuration': totalDuration,
        'totalSteps': totalSteps,
        'totalWorkouts': totalWorkouts,
        'walkingSessionsCount': walkingSessions.length,
      };
    } catch (e) {
      return {
        'totalCalories': 0.0,
        'totalDuration': 0,
        'totalSteps': 0,
        'totalWorkouts': 0,
        'walkingSessionsCount': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getCardioHistoryForWeek({
    DateTime? startDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 6));
      final weekHistory = <Map<String, dynamic>>[];

      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final stats = await getCardioStatisticsForDate(date);

        weekHistory.add({
          'date': date,
          'dayName': _getDayName(date.weekday),
          'stats': stats,
        });
      }

      return weekHistory;
    } catch (e) {
      return [];
    }
  }

  Stream<List<dynamic>> streamAllActivitiesForDate(DateTime date) {
    if (_currentUserId == null) return Stream.value([]);

    return Rx.combineLatest2(
      streamMealsForDate(date),
      streamWalkingSessionsForDate(date),
      (List<MealModel> meals, List<WalkingSession> walkingSessions) {
        try {
          List<dynamic> combinedList = [...meals, ...walkingSessions];
          combinedList.sort((a, b) {
            DateTime dateA;
            DateTime dateB;

            if (a is MealModel) {
              dateA = a.date;
            } else if (a is WalkingSession) {
              dateA = a.startTime;
            } else {
              dateA = DateTime.now();
            }

            if (b is MealModel) {
              dateB = b.date;
            } else if (b is WalkingSession) {
              dateB = b.startTime;
            } else {
              dateB = DateTime.now();
            }

            return dateA.compareTo(dateB);
          });

          return combinedList;
        } catch (e) {
          print('❌ Error in streamAllActivitiesForDate: $e');
          return <dynamic>[];
        }
      },
    );
  }

  Future<List<dynamic>> getAllActivitiesForDate(DateTime date) async {
    try {
      final meals = await getMealsForDate(date);
      final walkingSessions = await getWalkingSessionsForDateRange(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      List<dynamic> combinedList = [...meals, ...walkingSessions];
      combinedList.sort((a, b) {
        DateTime dateA;
        DateTime dateB;

        if (a is MealModel) {
          dateA = a.date;
        } else if (a is WalkingSession) {
          dateA = a.startTime;
        } else {
          dateA = DateTime.now();
        }

        if (b is MealModel) {
          dateB = b.date;
        } else if (b is WalkingSession) {
          dateB = b.startTime;
        } else {
          dateB = DateTime.now();
        }

        return dateA.compareTo(dateB);
      });

      return combinedList;
    } catch (e) {
      return [];
    }
  }

  Future<UserModel?> getUser(String userId) => getUserProfile();
  Future<void> updateUser(UserModel user) => updateUserProfile(user);
  Stream<List<MealModel>> getTodayMeals(String userId) => streamMealsToday();
}
