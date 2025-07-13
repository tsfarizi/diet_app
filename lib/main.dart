import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'services/permission_service.dart';
import 'services/local_notification_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/food_search_service.dart'; // ← ganti CSV
import 'themes/app_theme.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Background task started: $task');

      await Firebase.initializeApp();

      await _executeBackgroundSmartNotifications();

      print('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      print('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

Future<void> _executeBackgroundSmartNotifications() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No authenticated user for background notifications');
      return;
    }

    final localNotifications = LocalNotificationService();
    await localNotifications.initialize();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return;
    final userData = userDoc.data()!;

    final reminderSettings =
        userData['reminderSettings'] as Map<String, dynamic>?;
    if (reminderSettings == null ||
        reminderSettings['smartNotifications'] != true) {
      print('⚠️ Smart notifications disabled for user');
      return;
    }

    final mealsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(today.add(Duration(days: 1))),
        )
        .get();

    double totalCalories = 0.0;
    for (var mealDoc in mealsSnapshot.docs) {
      final mealData = mealDoc.data();
      final foods = mealData['foods'] as List<dynamic>? ?? [];
      for (var food in foods) {
        final nutrition = food['nutrition'] as Map<String, dynamic>? ?? {};
        totalCalories += ((nutrition['calories'] ?? 0.0) as num).toDouble();
      }
    }

    final walkingSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('walking_sessions')
        .where('startTime', isGreaterThanOrEqualTo: today.toIso8601String())
        .where(
          'startTime',
          isLessThanOrEqualTo: today.add(Duration(days: 1)).toIso8601String(),
        )
        .get();

    double cardioCalories = 0.0;
    int totalSteps = 0;
    for (var walkingDoc in walkingSnapshot.docs) {
      final walkingData = walkingDoc.data();
      cardioCalories += ((walkingData['calories'] ?? 0.0) as num).toDouble();
      totalSteps += ((walkingData['steps'] ?? 0) as num).toInt();
    }

    final hour = now.hour;

    if (hour >= 18 && hour < 19 && cardioCalories < 100 && totalSteps < 3000) {
      await localNotifications.showInstantNotification(
        title: '🏃‍♂️ Waktunya Bergerak!',
        body:
            'Anda belum banyak beraktivitas hari ini. Yuk jalan-jalan sebentar atau lakukan cardio ringan!',
        payload: 'background_cardio_reminder',
      );
    }

    if (hour >= 20 && hour < 21) {
      final calorieTarget =
          ((userData['calculatedCalorieTarget'] ?? 2000.0) as num).toDouble();

      if (totalCalories > calorieTarget * 1.2) {
        final excess = (totalCalories - calorieTarget).round();
        await localNotifications.showInstantNotification(
          title: '⚠️ Perhatian Kalori',
          body:
              'Anda sudah melebihi target kalori sebanyak $excess kcal. Pertimbangkan aktivitas cardio ringan untuk membakar kalori.',
          payload: 'background_overeating_alert',
        );
      } else if (totalCalories >= calorieTarget * 0.8) {
        await localNotifications.showInstantNotification(
          title: '🎯 Hari yang Baik!',
          body:
              'Target kalori tercapai ${(totalCalories / calorieTarget * 100).round()}%! Cardio: ${cardioCalories.round()} kcal, Langkah: $totalSteps.',
          payload: 'background_daily_summary',
        );
      }
    }

    if (hour >= 15 && hour < 16) {
      final motivationalMessages = [
        "💪 Konsistensi adalah kunci kesuksesan! Keep going!",
        "🌟 Setiap langkah kecil membawa kamu lebih dekat ke tujuan!",
        "🎯 Focus on progress, not perfection!",
        "🔥 Your body can do it. It's your mind you need to convince!",
        "✨ Strong is the new beautiful!",
        "🏃‍♂️ The only bad workout is the one that didn't happen!",
      ];

      final randomMessage =
          motivationalMessages[now.millisecond % motivationalMessages.length];

      await localNotifications.showInstantNotification(
        title: '✨ Motivasi Hari Ini',
        body: randomMessage,
        payload: 'background_motivation',
      );
    }

    print('✅ Smart notifications check completed');
  } catch (e) {
    print('❌ Error in background smart notifications: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final appTheme = AppTheme();
  await appTheme.initialize();

  runApp(MyApp(appTheme: appTheme));
}

class MyApp extends StatelessWidget {
  final AppTheme appTheme;
  const MyApp({super.key, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>.value(value: appTheme),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<PermissionService>(create: (_) => PermissionService()),
        Provider<LocalNotificationService>(
          create: (_) => LocalNotificationService(),
        ),
        Provider<DailyReminderService>(create: (_) => DailyReminderService()),
      ],
      child: Consumer<AppTheme>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Shihhati',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: StreamBuilder(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const OptimizedSplashScreen();
                }

                if (snapshot.hasData) {
                  return const DataInitializerWrapper();
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

/* ───────────────────────── Data initializer ───────────────────────── */

class DataInitializerWrapper extends StatefulWidget {
  const DataInitializerWrapper({super.key});

  @override
  State<DataInitializerWrapper> createState() => _DataInitializerWrapperState();
}

class _DataInitializerWrapperState extends State<DataInitializerWrapper> {
  bool _isDataLoaded = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isLoadingData || _isDataLoaded) return;

    setState(() => _isLoadingData = true);

    try {
      await Future.wait([_initializeServices(), _warmUpFirestore()]);

      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      final permissionService = Provider.of<PermissionService>(
        context,
        listen: false,
      );
      final localNotificationService = Provider.of<LocalNotificationService>(
        context,
        listen: false,
      );
      final dailyReminderService = Provider.of<DailyReminderService>(
        context,
        listen: false,
      );

      await permissionService.requestNotificationPermission();
      await permissionService.requestScheduleExactAlarmPermission();
      await localNotificationService.initialize();
      await dailyReminderService.initialize();

      debugPrint('✅ Services initialized');
    } catch (e) {
      debugPrint('⚠️ Service initialization error (non-critical): $e');
    }
  }

  /// Warm-up query agar cache Firestore siap (pengganti load CSV).
  Future<void> _warmUpFirestore() async {
    try {
      await FoodSearchService.getPopularFoods(
        limit: 20,
      ).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ Firestore warm-up error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const OptimizedSplashScreen(showProgress: true);
    }
    return const MainNavigationWithLocalNotifications();
  }
}

/* ───────────────────── Main navigation wrapper ────────────────────── */

class MainNavigationWithLocalNotifications extends StatefulWidget {
  const MainNavigationWithLocalNotifications({super.key});

  @override
  State<MainNavigationWithLocalNotifications> createState() =>
      _MainNavigationWithLocalNotificationsState();
}

class _MainNavigationWithLocalNotificationsState
    extends State<MainNavigationWithLocalNotifications> {
  @override
  void initState() {
    super.initState();
    _showWelcomeNotification();
  }

  Future<void> _showWelcomeNotification() async {
    try {
      final localNotificationService = Provider.of<LocalNotificationService>(
        context,
        listen: false,
      );

      await Future.delayed(const Duration(seconds: 2));

      await localNotificationService.showCustomNotification(
        title: "🎉 Selamat Datang!",
        body:
            "Notifikasi otomatis sudah aktif! Kami akan mengingatkan Anda untuk mencapai target harian. 💪",
        data: {'action': 'open_home', 'type': 'welcome'},
      );
    } catch (e) {
      debugPrint('⚠️ Welcome notification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => const MainNavigation();
}

/* ───────────────────────── Splash screen ─────────────────────────── */

class OptimizedSplashScreen extends StatelessWidget {
  final bool showProgress;
  const OptimizedSplashScreen({super.key, this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Shihhati',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Personal Health Companion',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              if (showProgress) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      const Text(
                        'Mempersiapkan aplikasi...',
                        style: TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 48),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
