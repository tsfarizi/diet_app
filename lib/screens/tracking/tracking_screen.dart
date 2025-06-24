import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../models/meal_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _foodNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _amountController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  MealType _selectedMealType = MealType.breakfast;
  // Fixed: Made fields final since they don't change
  final String _selectedCategory = 'other';
  final String _selectedServingSize = '100g';
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _amountController.text = '100';
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _brandController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _addMeal() async {
    if (_foodNameController.text.isEmpty || 
        _amountController.text.isEmpty ||
        _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    // Create nutrition info
    final nutritionInfo = NutritionInfo(
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
    );

    // Create food model
    final food = FoodModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _foodNameController.text,
      brand: _brandController.text,
      category: _selectedCategory,
      nutritionPer100g: nutritionInfo,
      servingSizes: ['100g', '1 porsi'],
      isCustom: true,
      createdBy: _authService.currentUser?.uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create food entry
    final foodEntry = FoodEntry.create(
      food: food,
      amount: double.tryParse(_amountController.text) ?? 100,
      servingSize: _selectedServingSize,
    );

    // Create meal
    final meal = MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _authService.currentUser!.uid,
      date: DateTime.now(),
      mealType: _selectedMealType,
      foods: [foodEntry],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _databaseService.addMeal(meal);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added successfully!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _foodNameController.clear();
    _brandController.clear();
    _amountController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();
    setState(() {
      _amountController.text = '100';
    });
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Meal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Food',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _foodNameController,
                            decoration: const InputDecoration(
                              labelText: 'Food Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.restaurant),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                              labelText: 'Brand',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<MealType>(
                            value: _selectedMealType,
                            decoration: const InputDecoration(
                              labelText: 'Meal Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                            ),
                            items: MealType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text('${type.icon} ${type.displayName}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMealType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount (g) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nutrition per ${_amountController.text.isEmpty ? "100" : _amountController.text}g',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Calories *',
                              border: OutlineInputBorder(),
                              suffixText: 'kcal',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _proteinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Protein',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Carbs',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fat',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addMeal,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Meal'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Today\'s Meals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<MealModel>>(
              stream: _databaseService.streamMealsToday(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('No meals tracked today'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final meal = snapshot.data![index];
                    final nutrition = meal.totalNutrition;
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(_getMealIcon(meal.mealType)),
                        title: Text(meal.foods.isNotEmpty 
                            ? meal.foods.first.food.name 
                            : 'Meal'),
                        subtitle: Text(
                          '${meal.mealTimeDisplay} - ${nutrition.calories.toStringAsFixed(0)} kcal',
                        ),
                        trailing: Text(
                          'P: ${nutrition.protein.toStringAsFixed(1)}g',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}