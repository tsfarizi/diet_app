import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/meal_model.dart';
import '../../models/user_model.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';
import '../../widgets/common/theme_toggle_button.dart';

class EnhancedDashboardPage extends StatelessWidget {
  final VoidCallback onNavigateToTrack;

  const EnhancedDashboardPage({super.key, required this.onNavigateToTrack});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Shihhati'),
            centerTitle: false,
            actions: [
              const ThemeToggleButton(size: 20),
              const SizedBox(width: 16),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? const LinearGradient(
                        colors: [AppColors.surfaceDark, AppColors.cardDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.primaryGradient,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(context, themeProvider),
                const SizedBox(height: 20),
                _buildEnhancedSummaryCard(
                  context,
                  themeProvider,
                  databaseService,
                ),
                const SizedBox(height: 20),
                _buildQuickActionsSection(context, themeProvider),
                const SizedBox(height: 20),
                _buildEnhancedRecentMeals(
                  context,
                  themeProvider,
                  databaseService,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(BuildContext context, AppTheme themeProvider) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final now = DateTime.now();
    String greeting = 'Good Morning';

    if (now.hour >= 12 && now.hour < 17) {
      greeting = 'Good Afternoon';
    } else if (now.hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: themeProvider.isDarkMode
            ? LinearGradient(
                colors: [
                  AppColors.primaryGreenLight.withValues(alpha: 0.1),
                  AppColors.accentGreen.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black26
                : Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.isDarkMode
                  ? AppColors.textPrimaryDark
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

          const SizedBox(height: 4),

          StreamBuilder(
            stream: authService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(
                    user?.displayName ?? 'Welcome to Diet Tracker!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: themeProvider.isDarkMode
                          ? AppColors.textPrimaryDark
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.2);
            },
          ),

          const SizedBox(height: 8),

          Text(
            'Ready to track your healthy journey today?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.isDarkMode
                  ? AppColors.textSecondaryDark
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCard(
    BuildContext context,
    AppTheme themeProvider,
    DatabaseService databaseService,
  ) {
    return Card(
      elevation: 4,
      shadowColor: themeProvider.isDarkMode
          ? Colors.black38
          : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),

            const SizedBox(height: 20),

            StreamBuilder<Map<String, dynamic>>(
              stream: databaseService.streamTodayProgress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error loading data'));
                }

                final progressData = snapshot.data!;
                if (progressData['error'] != null) {
                  return Center(child: Text('${progressData['error']}'));
                }

                final actual = progressData['actual'] as Map<String, dynamic>;
                final targets = progressData['targets'] as Map<String, dynamic>;

                final totalCalories = actual['calories'] ?? 0.0;
                final totalProtein = actual['protein'] ?? 0.0;
                final totalCarbs = actual['carbs'] ?? 0.0;
                final totalFat = actual['fat'] ?? 0.0;
                final waterIntake = actual['water'] ?? 0.0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildEnhancedSummaryItem(
                                    context,
                                    'Calories',
                                    '${totalCalories.round()}',
                                    '${targets['calories'].round()}',
                                    Icons.local_fire_department_rounded,
                                    AppColors.caloriesColor,
                                    themeProvider,
                                    totalCalories / targets['calories'],
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 100.ms)
                                  .scale(),
                        ),
                        Expanded(
                          child:
                              _buildEnhancedSummaryItem(
                                    context,
                                    'Protein',
                                    '${totalProtein.round()}g',
                                    '${targets['protein'].round()}g',
                                    Icons.fitness_center_rounded,
                                    AppColors.proteinColor,
                                    themeProvider,
                                    totalProtein / targets['protein'],
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 200.ms)
                                  .scale(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildEnhancedSummaryItem(
                                    context,
                                    'Carbs',
                                    '${totalCarbs.round()}g',
                                    '${targets['carbs'].round()}g',
                                    Icons.grain_rounded,
                                    AppColors.carbsColor,
                                    themeProvider,
                                    totalCarbs / targets['carbs'],
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 300.ms)
                                  .scale(),
                        ),
                        Expanded(
                          child:
                              _buildEnhancedSummaryItem(
                                    context,
                                    'Fat',
                                    '${totalFat.round()}g',
                                    '${targets['fat'].round()}g',
                                    Icons.opacity_rounded,
                                    AppColors.fatColor,
                                    themeProvider,
                                    totalFat / targets['fat'],
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 400.ms)
                                  .scale(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildEnhancedSummaryItem(
                                    context,
                                    'Water',
                                    '${waterIntake.round()}ml',
                                    '${targets['water'].round()}ml',
                                    Icons.water_drop_rounded,
                                    AppColors.waterColor,
                                    themeProvider,
                                    waterIntake / targets['water'],
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 500.ms)
                                  .scale(),
                        ),
                        Expanded(
                          child: _buildEnhancedSummaryItem(
                            context,
                            'Cardio',
                            '${(actual['exerciseCalories'] ?? 0.0).round()}kcal',
                            '200kcal',
                            Icons.directions_run_rounded,
                            AppColors.orange,
                            themeProvider,
                            (actual['exerciseCalories'] ?? 0.0) / 200,
                          ).animate().fadeIn(duration: 600.ms, delay: 600.ms).scale(),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSummaryItem(
    BuildContext context,
    String label,
    String value,
    String target,
    IconData icon,
    Color color,
    AppTheme themeProvider,
    double progress,
  ) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of $target',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedProgress,
            child: Container(
              decoration: BoxDecoration(
                color: progress > 1.0 ? Colors.orange : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),

        if (progress > 0)
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: progress > 1.0 ? Colors.orange : color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    AppTheme themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.add_circle_rounded,
                title: 'Add Meal',
                subtitle: 'Track your food',
                color: AppColors.primaryGreen,
                onTap: onNavigateToTrack,
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms).scale(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.water_drop_rounded,
                title: 'Add Water',
                subtitle: 'Stay hydrated',
                color: AppColors.blue,
                onTap: () {
                  _showWaterIntakeDialog(context);
                },
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(),
            ),
          ],
        ),
      ],
    );
  }

  void _showWaterIntakeDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    double waterAmount = 250;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<UserModel?>(
        future: authService.getUserProfile(),
        builder: (context, userSnapshot) {
          final userProfile = userSnapshot.data;

          final targetWater = userProfile?.calculatedWaterTarget ?? 2000;
          final List<double> quickAmounts = [
            targetWater * 0.1,
            targetWater * 0.125,
            targetWater * 0.15,
            targetWater * 0.25,
            targetWater * 0.375,
            targetWater * 0.5,
          ].map((e) => (e / 50).round() * 50.0).toList();

          waterAmount = quickAmounts[1];

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.waterColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Water Intake'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userProfile != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.waterColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Daily target: ${userProfile.calculatedWaterTarget.round()}ml',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.waterColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickAmounts
                        .map(
                          (amount) => ChoiceChip(
                            label: Text('${amount.toInt()}ml'),
                            selected: waterAmount == amount,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  waterAmount = amount;
                                });
                              }
                            },
                            selectedColor: AppColors.waterColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: waterAmount.toInt().toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custom Amount (ml)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.water_drop_outlined,
                        color: AppColors.waterColor,
                      ),
                      suffixText: 'ml',
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value);
                      if (amount != null && amount > 0) {
                        setDialogState(() {
                          waterAmount = amount;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.waterColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.waterColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: AppColors.waterColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${waterAmount.toInt()} ml',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.waterColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop();
                      final databaseService = Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      );
                      await databaseService.addWaterIntake(waterAmount);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${waterAmount.toInt()}ml water intake!',
                            ),
                            backgroundColor: AppColors.waterColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add water intake: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.waterColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add Water'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedRecentMeals(
    BuildContext context,
    AppTheme themeProvider,
    DatabaseService databaseService,
  ) {
    return Card(
      elevation: 4,
      shadowColor: themeProvider.isDarkMode
          ? Colors.black38
          : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Meals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),

            const SizedBox(height: 16),

            StreamBuilder<List<MealModel>>(
              stream: databaseService.streamMealsToday(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final meals = snapshot.data ?? [];

                if (meals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No meals tracked yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap Track tab to add your first meal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: meals.take(3).map((meal) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.foods.isNotEmpty
                                      ? meal.foods.first.food.name
                                      : meal.mealTimeDisplay,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${meal.mealTimeDisplay} • ${meal.totalNutrition.calories.round()} cal',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
          ],
        ),
      ),
    );
  }
}
