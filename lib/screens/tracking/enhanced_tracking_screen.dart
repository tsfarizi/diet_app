import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/food_model.dart';
import '../../models/meal_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/food_search_service.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';

class EnhancedTrackingScreen extends StatefulWidget {
  const EnhancedTrackingScreen({super.key});

  @override
  State<EnhancedTrackingScreen> createState() => _EnhancedTrackingScreenState();
}

class _EnhancedTrackingScreenState extends State<EnhancedTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final _searchController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _amountController = TextEditingController()..text = '100';
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // State
  List<FoodModel> _searchResults = [];
  bool _isInitializing = true;
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isLoadingSearch = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  int _totalFoods = 0;

  // Pilihan input manual
  MealType _selectedMealType = MealType.breakfast;
  final String _selectedCategory = 'other';
  final String _selectedServingSize = '100g';

  // Services
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _foodNameController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  /// Load page pertama & total count
  Future<void> _loadInitialData() async {
    setState(() => _isInitializing = true);
    try {
      final (foods, cursor) = await FoodSearchService.fetchFoodsPage(limit: 20);
      final count = await FoodSearchService.getTotalFoodsCount();
      setState(() {
        _searchResults = foods;
        _cursor = cursor;
        _totalFoods = count ?? 0;
        _hasMore = cursor != null;
        _isInitializing = false;
        _isSearching = false;
        _showSuggestions = false;
      });
    } catch (_) {
      setState(() => _isInitializing = false);
    }
  }

  /// Load next page
  Future<void> _loadMoreFoods() async {
    if (_cursor == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final (foods, cursor) = await FoodSearchService.fetchFoodsPage(
        limit: 20,
        last: _cursor,
      );
      setState(() {
        _searchResults.addAll(foods);
        _cursor = cursor;
        _hasMore = cursor != null;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Callback saat text berubah di search bar
  void _onSearchChanged(String query) async {
    setState(() {
      _isLoadingSearch = query.isNotEmpty;
      _showSuggestions = query.isNotEmpty;
      _hasMore = query.isEmpty;
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) _cursor = null;
    });

    if (query.isNotEmpty) {
      try {
        final res = await FoodSearchService.searchFoods(query);
        setState(() {
          _searchResults = res;
          _isLoadingSearch = false;
        });
      } catch (_) {
        setState(() {
          _searchResults = [];
          _isLoadingSearch = false;
        });
      }
    } else {
      await _loadInitialData();
      setState(() => _isLoadingSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (_, theme, __) => Scaffold(
        body: Column(
          children: [
            _buildHeader(theme),
            _isInitializing
                ? _buildInitializing()
                : Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSelectFoodTab(theme),
                        _buildManualInputTab(theme),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) => Container(
    decoration: BoxDecoration(
      gradient: theme.isDarkMode
          ? const LinearGradient(
              colors: [AppColors.surfaceDark, AppColors.cardDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : AppColors.primaryGradient,
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          AppBar(
            title: const Text('Track Makanan'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.search_rounded), text: 'Cari Makanan'),
              Tab(icon: Icon(Icons.edit_rounded), text: 'Input Makanan'),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildInitializing() => Expanded(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Memuat database makanan...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '$_totalFoods makanan tersedia',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    ),
  );

  Widget _buildSelectFoodTab(AppTheme theme) => Column(
    children: [
      _buildSearchSection(theme),
      Expanded(child: _buildFoodResultsSection(theme)),
    ],
  );

  Widget _buildSearchSection(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.isDarkMode ? Colors.black26 : Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: _totalFoods == 0
                  ? 'Cari makanan...'
                  : 'Cari dari $_totalFoods makanan...',
              prefixIcon: _isLoadingSearch
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

          if (_showSuggestions && _searchController.text.isNotEmpty)
            const SizedBox(height: 8),
          if (_showSuggestions && _searchController.text.isNotEmpty)
            FutureBuilder<List<String>>(
              future: FoodSearchService.getSuggestions(_searchController.text),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: snap.data!
                        .map(
                          (s) => InkWell(
                            onTap: () {
                              _searchController.text = s;
                              _onSearchChanged(s);
                              setState(() => _showSuggestions = false);
                            },
                            child: Chip(
                              label: Text(s),
                              backgroundColor: AppColors.primaryGreen
                                  .withOpacity(0.1),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFoodResultsSection(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSearching)
            Text(
              'Hasil Pencarian (${_searchResults.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (_isSearching) const SizedBox(height: 12),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (sn) {
                      if (sn.metrics.pixels >=
                              sn.metrics.maxScrollExtent - 32 &&
                          !_isLoadingMore &&
                          _hasMore &&
                          !_isSearching) {
                        _loadMoreFoods();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _searchResults.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final food = _searchResults[i];
                        return _buildFoodListItem(food, theme)
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (i * 50).ms)
                            .slideX(begin: 0.1);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          _isSearching ? 'Tidak ditemukan' : 'Mulai cari makanan',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _foodNameController.text = _searchController.text;
              _tabController.animateTo(1);
            },
            child: const Text('Input Manual'),
          ),
        ],
      ],
    ),
  );

  Widget _buildFoodListItem(FoodModel food, AppTheme theme) {
    final leading = food.imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.network(
              food.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackAvatar(food),
            ),
          )
        : _fallbackAvatar(food);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${food.nutritionPer100g.calories.toInt()} kcal per 100g'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('P: ${food.nutritionPer100g.protein.toStringAsFixed(1)}g'),
                const SizedBox(width: 12),
                Text('C: ${food.nutritionPer100g.carbs.toStringAsFixed(1)}g'),
                const SizedBox(width: 12),
                Text('F: ${food.nutritionPer100g.fat.toStringAsFixed(1)}g'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                FoodSearchService.isFavorite(food.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: FoodSearchService.isFavorite(food.id)
                    ? AppColors.error
                    : null,
              ),
              onPressed: () {
                setState(() {
                  if (FoodSearchService.isFavorite(food.id)) {
                    FoodSearchService.removeFromFavorites(food.id);
                  } else {
                    FoodSearchService.addToFavorites(food.id);
                  }
                });
              },
            ),
            const Icon(Icons.add_circle, color: AppColors.primaryGreen),
          ],
        ),
        onTap: () => _showAddFoodDialog(food),
      ),
    );
  }

  Widget _fallbackAvatar(FoodModel food) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: _getCategoryColor(food.category).withOpacity(0.2),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Icon(
      _getCategoryIcon(food.category),
      color: _getCategoryColor(food.category),
    ),
  );

  void _showAddFoodDialog(FoodModel food) {
    double amount = 100;
    MealType mealType = _getCurrentMealType();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(food.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: amount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (gram)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  amount = double.tryParse(v) ?? 100;
                  setStateDialog(() {});
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealType>(
                value: mealType,
                decoration: const InputDecoration(
                  labelText: 'Waktu Makan',
                  border: OutlineInputBorder(),
                ),
                items: MealType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text('${e.icon} ${e.displayName}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  mealType = v!;
                  setStateDialog(() {});
                },
              ),
              const SizedBox(height: 16),
              _buildPreviewCard(food, amount),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addFoodToMeal(food, amount);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(FoodModel food, double amount) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryGreen.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text('Preview Nutrisi', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionItem(
              'Kal',
              '${(food.nutritionPer100g.calories * amount / 100).toInt()}',
            ),
            _buildNutritionItem(
              'Protein',
              '${(food.nutritionPer100g.protein * amount / 100).toStringAsFixed(1)}g',
            ),
            _buildNutritionItem(
              'Karbo',
              '${(food.nutritionPer100g.carbs * amount / 100).toStringAsFixed(1)}g',
            ),
            _buildNutritionItem(
              'Lemak',
              '${(food.nutritionPer100g.fat * amount / 100).toStringAsFixed(1)}g',
            ),
          ],
        ),
      ],
    ),
  );

  Column _buildNutritionItem(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  Future<void> _addFoodToMeal(FoodModel food, double amount) async {
    try {
      final entry = FoodEntry.create(
        food: food,
        amount: amount,
        servingSize: _selectedServingSize,
      );
      final meal = MealModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _authService.currentUser!.uid,
        date: DateTime.now(),
        mealType: _getCurrentMealType(),
        foods: [entry],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _databaseService.addMeal(meal);
      FoodSearchService.addToRecentSearches(food.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildManualInputTab(AppTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Makanan Manual',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _foodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Makanan *',
                      hintText: 'cth: Nasi Goreng, Bakso, Sate Ayam',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<MealType>(
                          value: _selectedMealType,
                          decoration: const InputDecoration(
                            labelText: 'Waktu Makan',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          items: MealType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('${e.icon} ${e.displayName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMealType = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah (gram) *',
                            hintText: '100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Informasi Nutrisi per ${_amountController.text.isEmpty ? "100" : _amountController.text} gram',
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
                            labelText: 'Kalori *',
                            hintText: '0',
                            border: OutlineInputBorder(),
                            suffixText: 'kkal',
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
                            hintText: '0',
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
                            labelText: 'Karbohidrat',
                            hintText: '0',
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
                            labelText: 'Lemak',
                            hintText: '0',
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
                      onPressed: _addManualMeal,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Makanan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addManualMeal() async {
    if (_foodNameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi kolom yang wajib diisi')),
      );
      return;
    }
    final info = NutritionInfo(
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
    );
    final food = FoodModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _foodNameController.text,
      brand: '',
      category: _selectedCategory,
      nutritionPer100g: info,
      servingSizes: const ['100g', '1 porsi'],
      isCustom: true,
      createdBy: _authService.currentUser?.uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final entry = FoodEntry.create(
      food: food,
      amount: double.tryParse(_amountController.text) ?? 100,
      servingSize: _selectedServingSize,
    );
    final meal = MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _authService.currentUser!.uid,
      date: DateTime.now(),
      mealType: _selectedMealType,
      foods: [entry],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _databaseService.addMeal(meal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Makanan berhasil ditambahkan!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearForm() {
    _foodNameController.clear();
    _amountController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();
    setState(() => _amountController.text = '100');
  }

  MealType _getCurrentMealType() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 15) return MealType.lunch;
    if (h >= 15 && h < 18) return MealType.snack;
    return MealType.dinner;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'grains':
        return Icons.rice_bowl;
      case 'protein':
        return Icons.set_meal;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      case 'beverages':
        return Icons.local_cafe;
      case 'fastFood':
        return Icons.fastfood;
      default:
        return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'grains':
        return AppColors.carbsColor;
      case 'protein':
        return AppColors.proteinColor;
      case 'vegetables':
        return AppColors.fiberColor;
      case 'fruits':
        return AppColors.orange;
      case 'dairy':
        return AppColors.blue;
      case 'snacks':
        return AppColors.caloriesColor;
      case 'beverages':
        return AppColors.waterColor;
      case 'fastFood':
        return AppColors.red;
      default:
        return AppColors.primaryGreen;
    }
  }
}
