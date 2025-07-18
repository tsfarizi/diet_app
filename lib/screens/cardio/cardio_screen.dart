import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/walking_tracker_service.dart';
import '../../services/local_notification_service.dart';
import '../../models/user_model.dart';
import '../../models/walking_session_model.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';
import '../../widgets/exercise/walking_tracker_widget.dart';
import '../../widgets/exercise/daily_stats_widget.dart';
import '../profile/profile_screen.dart';

class CardioScreen extends StatefulWidget {
  const CardioScreen({super.key});

  @override
  State<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends State<CardioScreen>
    with TickerProviderStateMixin {
  final WalkingTrackerService _walkingService = WalkingTrackerService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  UserModel? _currentUser;
  StreamSubscription<WalkingSession>? _walkingSubscription;
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _initializeData();
    _listenToWalkingSession();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      if (!mounted) return;
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      Provider.of<AuthService>(context, listen: false);
      _currentUser = await databaseService.getUserProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _listenToWalkingSession() {
    _walkingSubscription = _walkingService.sessionStream?.listen((session) {});
  }

  void _onWalkingSessionComplete(WalkingSession session) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sesi cardio selesai! ${session.steps} langkah, ${session.calories.round()} kal',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
  }

  Future<void> _testNotification() async {
    final localNotificationService = Provider.of<LocalNotificationService>(
      context,
      listen: false,
    );
    await localNotificationService.showInstantNotification(
      title: '🔔 Test Notifikasi',
      body: 'Ini notifikasi simulasi dari tombol debug',
      payload: 'manual_test',
    );
  }

  @override
  void dispose() {
    _walkingSubscription?.cancel();
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Cardio'),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.timeline), text: 'Stats'),
                Tab(icon: Icon(Icons.directions_run), text: 'Tracker'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active),
                onPressed: _testNotification,
                tooltip: 'Test Notifikasi',
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _navigateToProfile,
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
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
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildStatsTab(themeProvider),
              _buildTrackerTab(themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(AppTheme themeProvider) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading cardio data...'),
          ],
        ),
      );
    }
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeData,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_currentUser != null) _buildProfileSection(themeProvider),
                const SizedBox(height: 24),
                _buildDailyStatsSection(),
                const SizedBox(height: 24),
                _buildCardioTips(themeProvider),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerTab(AppTheme themeProvider) {
    if (_currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user profile...'),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            WalkingTrackerWidget(
              userWeight: _currentUser!.weight,
              userAge: _currentUser!.age,
              userHeight: _currentUser!.height,
              autoStart: false,
              onSessionComplete: _onWalkingSessionComplete,
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Cardio Tracker',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Walking & Running tracker dengan GPS',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(AppTheme themeProvider) {
    final bmi =
        (_currentUser!.weight /
        ((_currentUser!.height / 100) * (_currentUser!.height / 100)));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue,
                child: Icon(Icons.directions_run, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Cardio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Target: Burn kalori & tingkatkan kondisi fisik',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _navigateToProfile,
                icon: Icon(Icons.edit, color: Colors.blue),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.monitor_weight,
                  label: 'Berat Badan',
                  value: '${_currentUser!.weight.toStringAsFixed(1)} kg',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.height,
                  label: 'Tinggi Badan',
                  value: '${_currentUser!.height.toStringAsFixed(0)} cm',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStat(
                  icon: Icons.analytics,
                  label: 'BMI',
                  value: bmi.toStringAsFixed(1),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 50.ms);
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatsSection() {
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    return StreamBuilder<Map<String, dynamic>>(
      stream: databaseService.streamExerciseStatsForDate(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DailyStatsWidget(
            currentSteps: 0,
            currentCalories: 0.0,
            currentWorkouts: 0,
            currentMinutes: 0,
            targetSteps: 8000,
            targetCalories: 300,
            targetWorkouts: 3,
            targetMinutes: 60,
          );
        }
        final stats = snapshot.data ?? {};
        final currentSteps = stats['steps'] ?? 0;
        final currentCalories = (stats['calories'] ?? 0.0).toDouble();
        final currentWorkouts = stats['workouts'] ?? 0;
        final currentMinutes = stats['duration'] ?? 0;
        return DailyStatsWidget(
          currentSteps: currentSteps,
          currentCalories: currentCalories,
          currentWorkouts: currentWorkouts,
          currentMinutes: currentMinutes,
          targetSteps: 8000,
          targetCalories: 300,
          targetWorkouts: 3,
          targetMinutes: 60,
        );
      },
    );
  }

  Widget _buildCardioTips(AppTheme themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Tips Cardio Hari Ini',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('🏃‍♂️', 'Mulai dengan warming up 5-10 menit'),
          _buildTipItem(
            '💧',
            'Minum air putih sebelum, saat, dan sesudah cardio',
          ),
          _buildTipItem('📱', 'Gunakan GPS tracker untuk monitoring akurat'),
          _buildTipItem('⏰', 'Target minimal 30 menit cardio per hari'),
          _buildTipItem('🎯', 'Konsistensi lebih penting daripada intensitas'),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 200.ms);
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
