import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';
import '../../services/database_service.dart';
import '../../models/meal_model.dart';
import '../../models/walking_session_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final DatabaseService _databaseService;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showCalendar = false;

  List<DateTime> _datesWithData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseService = Provider.of<DatabaseService>(context, listen: false);
      _loadDatesWithData();
    });
  }

  Future<void> _loadDatesWithData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      List<DateTime> dates = [];

      for (DateTime date = startDate; date.isBefore(endDate); date = date.add(Duration(days: 1))) {
        try {
          final meals = await _databaseService.getMealsForDate(date);
          final waterIntake = await _databaseService.getWaterIntakeForDate(date);
          final steps = await _databaseService.getStepsForDate(date);

          if (meals.isNotEmpty || waterIntake > 0 || steps > 0) {
            dates.add(DateTime(date.year, date.month, date.day));
          }
        } catch (e) {
          debugPrint('Skipping date ${date.toString()}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _datesWithData = dates;
        });
      }
    } catch (e) {
      debugPrint('Error loading dates with data: $e');
    }
  }

  void _onDateSelected(DateTime selectedDate, DateTime focusedDate) {
    if (mounted) {
      setState(() {
        _selectedDate = selectedDate;
        _focusedDate = focusedDate;
        _showCalendar = false;
      });
    }
  }

  void _goToPreviousDay() {
    final previousDay = _selectedDate.subtract(Duration(days: 1));
    if (mounted) {
      setState(() {
        _selectedDate = previousDay;
        _focusedDate = previousDay;
      });
    }
  }

  void _goToNextDay() {
    final nextDay = _selectedDate.add(Duration(days: 1));
    if (!isSameDay(nextDay, DateTime.now().add(Duration(days: 1)))) {
      if (mounted) {
        setState(() {
          _selectedDate = nextDay;
          _focusedDate = nextDay;
        });
      }
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    if (mounted) {
      setState(() {
        _selectedDate = today;
        _focusedDate = today;
      });
    }
  }

  Stream<Map<String, dynamic>> _getSelectedDateProgress() {
    return _databaseService.streamProgressForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode
                  ? const LinearGradient(
                      colors: [AppColors.surfaceDark, AppColors.cardDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(themeProvider),
                      Expanded(
                        child: _buildAnalyticsContent(themeProvider),
                      ),
                    ],
                  ),
                  if (_showCalendar) _buildCalendarOverlay(themeProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme themeProvider) {
    final isToday = isSameDay(_selectedDate, DateTime.now());

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Progress harian diet & cardio',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (!isToday)
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          _buildDatePicker(themeProvider),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3);
  }

  Widget _buildDatePicker(AppTheme themeProvider) {
    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousDay,
          icon: Icon(Icons.chevron_left, color: Colors.white),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    _formatSelectedDate(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _canGoToNextDay() ? _goToNextDay : null,
          icon: Icon(
            Icons.chevron_right,
            color: _canGoToNextDay() ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarOverlay(AppTheme themeProvider) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showCalendar = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Tanggal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showCalendar = false;
                          });
                        },
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TableCalendar<DateTime>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDate,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDate, day);
                    },
                    eventLoader: (day) {
                      return _datesWithData.where((date) => isSameDay(date, day)).toList();
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: _onDateSelected,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDate = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: AppColors.orange),
                      holidayTextStyle: TextStyle(color: AppColors.orange),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAnalyticsContent(AppTheme themeProvider) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getSelectedDateProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Memuat data analytics...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Error loading analytics data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final progressData = snapshot.data!;
        if (progressData['error'] != null) {
          return _buildIncompleteProfile(themeProvider, progressData['error']);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadDatesWithData();
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCards(themeProvider, progressData),
                SizedBox(height: 24),
                _buildNutritionSummary(themeProvider, progressData),
                SizedBox(height: 24),
                _buildActivitiesList(themeProvider),
                SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncompleteProfile(AppTheme themeProvider, String errorMessage) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Data Tidak Lengkap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage == 'Profile incomplete' 
                  ? 'Lengkapi profil Anda di tab Profile untuk melihat analytics personal'
                  : errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCards(AppTheme themeProvider, Map<String, dynamic> progressData) {
    final actual = progressData['actual'] as Map<String, dynamic>? ?? {};
    final targets = progressData['targets'] as Map<String, dynamic>? ?? {};

    final todayCalories = (actual['calories'] ?? 0.0).toDouble();
    final cardioCalories = (actual['exerciseCalories'] ?? 0.0).toDouble();
    final waterIntake = (actual['water'] ?? 0.0).toDouble();
    final totalSteps = (actual['steps'] ?? 0).toInt();
    final totalWorkouts = (actual['workouts'] ?? 0).toInt();

    final targetCalories = (targets['calories'] ?? 2000.0).toDouble();
    final targetWater = (targets['water'] ?? 2000.0).toDouble();
    final targetSteps = (targets['steps'] ?? 8000).toInt();
    final targetWorkouts = (targets['workouts'] ?? 3).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getDateTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Kalori',
                value: '${todayCalories.toInt()}',
                unit: 'kcal',
                subtitle: 'Target: ${targetCalories.toInt()}',
                progress: targetCalories > 0 ? todayCalories / targetCalories : 0.0,
                color: AppColors.caloriesColor,
                icon: Icons.local_fire_department,
                themeProvider: themeProvider,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Cardio',
                value: '${cardioCalories.toInt()}',
                unit: 'kcal',
                subtitle: 'Target: 200 kcal',
                progress: cardioCalories / 200.0,
                color: AppColors.orange,
                icon: Icons.directions_run,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Air Minum',
                value: '${(waterIntake / 1000).toStringAsFixed(1)}',
                unit: 'L',
                subtitle: 'Target: ${(targetWater / 1000).toStringAsFixed(1)}L',
                progress: targetWater > 0 ? waterIntake / targetWater : 0.0,
                color: AppColors.waterColor,
                icon: Icons.water_drop,
                themeProvider: themeProvider,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Aktivitas',
                value: '$totalWorkouts',
                unit: 'sesi',
                subtitle: 'Target: $targetWorkouts',
                progress: targetWorkouts > 0 ? totalWorkouts / targetWorkouts.toDouble() : 0.0,
                color: AppColors.primaryGreen,
                icon: Icons.timeline,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Langkah',
                value: '$totalSteps',
                unit: 'steps',
                subtitle: 'Target: $targetSteps',
                progress: targetSteps > 0 ? totalSteps / targetSteps.toDouble() : 0.0,
                color: AppColors.blue,
                icon: Icons.directions_walk,
                themeProvider: themeProvider,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    SizedBox(height: 8),
                    Text(
                      _getMotivationMessage(totalWorkouts, cardioCalories),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 1000.ms, delay: 200.ms).slideY(begin: 0.2);
  }

  String _getMotivationMessage(int workouts, double calories) {
    if (workouts >= 3) return '🎉 Target tercapai!';
    if (workouts >= 2) return '💪 Hampir sampai!';
    if (workouts >= 1) return '🔥 Terus semangat!';
    if (calories > 0) return '✨ Mulai yang baik!';
    return '🚀 Ayo mulai!';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
    required AppTheme themeProvider,
  }) {
    final isOverTarget = progress > 1.0;
    final displayProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isOverTarget ? Colors.orange : color,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: displayProgress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(isOverTarget ? Colors.orange : color),
          ),
          SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: isOverTarget ? Colors.orange : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(AppTheme themeProvider, Map<String, dynamic> progressData) {
    final actual = progressData['actual'] as Map<String, dynamic>? ?? {};
    final targets = progressData['targets'] as Map<String, dynamic>? ?? {};

    final protein = (actual['protein'] ?? 0.0).toDouble();
    final carbs = (actual['carbs'] ?? 0.0).toDouble();
    final fat = (actual['fat'] ?? 0.0).toDouble();

    if (protein == 0 && carbs == 0 && fat == 0) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Belum ada data nutrisi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Mulai catat makanan untuk melihat breakdown',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Ringkasan Nutrisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  'Protein',
                  protein,
                  (targets['protein'] ?? 50.0).toDouble(),
                  AppColors.proteinColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildNutritionItem(
                  'Karbohidrat',
                  carbs,
                  (targets['carbs'] ?? 200.0).toDouble(),
                  AppColors.carbsColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildNutritionItem(
                  'Lemak',
                  fat,
                  (targets['fat'] ?? 60.0).toDouble(),
                  AppColors.fatColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1200.ms, delay: 400.ms).slideX(begin: 0.2);
  }

  Widget _buildNutritionItem(String label, double value, double target, Color color) {
    final percentage = target > 0 ? (value / target * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Target: ${target.toStringAsFixed(0)}g',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        SizedBox(height: 2),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(AppTheme themeProvider) {
    return StreamBuilder<List<dynamic>>(
      stream: _databaseService.streamAllActivitiesForDate(_selectedDate),
      builder: (context, activitiesSnapshot) {
        if (activitiesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final activities = activitiesSnapshot.data ?? [];

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Aktivitas ${_getDateTitle()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  if (activities.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activities.length} aktivitas',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              if (activities.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada aktivitas',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Mulai catat makanan dan cardio',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final item = activities[index];
                    if (item is MealModel) {
                      return _buildMealActivityItem(item, themeProvider);
                    } else if (item is WalkingSession) {
                      return _buildWalkingActivityItem(item, themeProvider);
                    }
                    return SizedBox.shrink();
                  },
                ),
            ],
          ),
        ).animate().fadeIn(duration: 1200.ms, delay: 600.ms).slideY(begin: 0.3);
      },
    );
  }

  Widget _buildMealActivityItem(MealModel meal, AppTheme themeProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.surfaceDark.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMealTypeIcon(meal.mealType),
              color: _getMealTypeColor(meal.mealType),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foods.isNotEmpty ? meal.foods.first.food.name : 'Makanan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_getMealTypeDisplayName(meal.mealType)} • ${meal.totalNutrition.calories.toInt()} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(meal.date),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingActivityItem(WalkingSession session, AppTheme themeProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.surfaceDark.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_run,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cardio Session',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${session.formattedDistance} • ${session.calories.toInt()} kcal • ${session.steps} langkah',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatTime(session.startTime),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final isToday = isSameDay(_selectedDate, DateTime.now());
    if (isToday) return 'Hari Ini';

    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final isYesterday = isSameDay(_selectedDate, yesterday);
    if (isYesterday) return 'Kemarin';

    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  String _getDateTitle() {
    final isToday = isSameDay(_selectedDate, DateTime.now());
    if (isToday) return 'Progress Hari Ini';

    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final isYesterday = isSameDay(_selectedDate, yesterday);
    if (isYesterday) return 'Progress Kemarin';

    return 'Progress ${_selectedDate.day}/${_selectedDate.month}';
  }

  bool _canGoToNextDay() {
    return !isSameDay(_selectedDate, DateTime.now());
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getMealTypeIcon(MealType type) {
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

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppColors.orange;
      case MealType.lunch:
        return AppColors.primaryGreen;
      case MealType.dinner:
        return AppColors.blue;
      case MealType.snack:
        return AppColors.purple;
    }
  }

  String _getMealTypeDisplayName(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Sarapan';
      case MealType.lunch:
        return 'Makan Siang';
      case MealType.dinner:
        return 'Makan Malam';
      case MealType.snack:
        return 'Snack';
    }
  }
}