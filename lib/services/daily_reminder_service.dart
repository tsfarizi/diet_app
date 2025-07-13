import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';  // ADDED
import 'local_notification_service.dart';

class DailyReminderService {
  static final DailyReminderService _instance = DailyReminderService._internal();
  factory DailyReminderService() => _instance;
  DailyReminderService._internal();

  final LocalNotificationService _localNotifications = LocalNotificationService();
  
  // REMOVED: Timer? _backgroundChecker;
  // REPLACED WITH: Workmanager background tasks
  
  bool _isInitialized = false;
  bool _backgroundNotificationsEnabled = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _localNotifications.initialize();
    
    // REPLACED: _startBackgroundChecker() with workmanager setup
    await _setupWorkmanagerTasks();
    await _setupUserPreferences();
    
    _isInitialized = true;
    print('✅ Daily Reminder Service initialized with Workmanager');
  }

  // ADDED: Setup workmanager background tasks
  Future<void> _setupWorkmanagerTasks() async {
    try {
      // Check if background notifications should be enabled
      final reminderStatus = await getReminderStatus();
      _backgroundNotificationsEnabled = reminderStatus['enabled'] ?? false;
      
      if (_backgroundNotificationsEnabled) {
        await startBackgroundNotifications();
      }
    } catch (e) {
      print('Error setting up workmanager tasks: $e');
    }
  }

  // ADDED: Start background notifications using workmanager
  Future<void> startBackgroundNotifications() async {
    try {
      // Cancel any existing background tasks first
      await Workmanager().cancelByUniqueName("smart_notification_task");
      
      // Register new periodic task for smart notifications
      await Workmanager().registerPeriodicTask(
        "smart_notification_task",
        "smartNotificationTask",
        frequency: Duration(minutes: 30), // Every 30 minutes
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresDeviceIdle: false,
        ),
        inputData: {
          'type': 'smart_notification',
          'started_at': DateTime.now().toIso8601String(),
        },
      );
      
      _backgroundNotificationsEnabled = true;
      await _updateUserReminderStatus(true);
      
      print('✅ Background notifications started with Workmanager');
    } catch (e) {
      print('❌ Error starting background notifications: $e');
    }
  }

  // ADDED: Stop background notifications
  Future<void> stopBackgroundNotifications() async {
    try {
      await Workmanager().cancelByUniqueName("smart_notification_task");
      
      _backgroundNotificationsEnabled = false;
      await _updateUserReminderStatus(false);
      
      print('✅ Background notifications stopped');
    } catch (e) {
      print('❌ Error stopping background notifications: $e');
    }
  }

  // ADDED: Update user reminder status in Firestore
  Future<void> _updateUserReminderStatus(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'reminderSettings.smartNotifications': enabled,
        'reminderSettings.lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating reminder status: $e');
    }
  }

  // GETTER: Check if background notifications are enabled
  bool get isBackgroundNotificationsEnabled => _backgroundNotificationsEnabled;

  // REMOVED: _startBackgroundChecker() method with Timer.periodic
  // REMOVED: _checkTriggeredReminders() method (moved to main.dart background callback)

  // KEEP EXISTING: User preferences setup
  Future<void> _setupUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        await _createDefaultUserSettings(user.uid);
      } else {
        await _updateReminderSettings(user.uid, userDoc.data()!);
      }
    } catch (e) {
      print('Error setting up user preferences: $e');
    }
  }

  // KEEP EXISTING: Create default user settings
  Future<void> _createDefaultUserSettings(String userId) async {
    final defaultSettings = {
      'reminderSettings': {
        'enabled': true,
        'morningReminder': true,
        'lunchReminder': true,
        'eveningReminder': true,
        'nightCheck': true,
        'smartNotifications': true,  // Enable by default
      },
      'reminderTimes': {
        'morning': '09:00',
        'lunch': '12:00',
        'evening': '18:00',
        'night': '20:00',
      },
      'notificationPreferences': {
        'sound': true,
        'vibration': true,
        'priority': 'high',
      },
      'lastReminderUpdate': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(defaultSettings, SetOptions(merge: true));
    
    print('✅ Default reminder settings created for user');
  }

  // KEEP EXISTING: Update reminder settings
  Future<void> _updateReminderSettings(String userId, Map<String, dynamic> userData) async {
    final reminderSettings = userData['reminderSettings'] as Map<String, dynamic>?;
    
    if (reminderSettings == null || reminderSettings['enabled'] != true) {
      print('⚠️ Reminders disabled for user');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'lastReminderUpdate': FieldValue.serverTimestamp(),
    });
  }

  // KEEP EXISTING: Check overeating alert (can be called manually)
  Future<void> checkOvereatingAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayStats = userData['dailyStats'] != null && userData['dailyStats'][today] != null
          ? userData['dailyStats'][today] as Map<String, dynamic>
          : <String, dynamic>{};
      
      final currentCalories = todayStats['calories'] ?? 0;
      final calorieTarget = userData['calorieTarget'] ?? 2000;
      final overeatThreshold = calorieTarget * 1.1;

      if (currentCalories > overeatThreshold) {
        final excess = (currentCalories - calorieTarget).round();
        
        await _localNotifications.showCustomNotification(
          title: "⚠️ Kalori Berlebih",
          body: "Kalori hari ini sudah $excess lebih dari target. Pertimbangkan olahraga tambahan! 🏃‍♂️",
          data: {'action': 'open_exercise', 'type': 'overeating_alert'},
        );

        await _logNotificationSent('overeating_alert', {
          'excessCalories': excess,
          'currentCalories': currentCalories,
          'targetCalories': calorieTarget,
        });
      }
    } catch (e) {
      print('Error checking overeating alert: $e');
    }
  }

  // KEEP EXISTING: Check water reminder (can be called manually)
  Future<void> checkWaterReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayStats = userData['dailyStats'] != null && userData['dailyStats'][today] != null
          ? userData['dailyStats'][today] as Map<String, dynamic>
          : <String, dynamic>{};
      
      final currentWater = todayStats['water'] ?? 0;
      final waterTarget = userData['waterTarget'] ?? 8;

      if (currentWater < waterTarget * 0.5) {
        await _localNotifications.showCustomNotification(
          title: "💧 Jangan Lupa Minum!",
          body: "Hari ini baru minum $currentWater gelas. Target: $waterTarget gelas. Tetap terhidrasi ya! 💧",
          data: {'action': 'open_tracking', 'type': 'water_reminder'},
        );
      }
    } catch (e) {
      print('Error checking water reminder: $e');
    }
  }

  // KEEP EXISTING: Check motivational boost (can be called manually)
  Future<void> checkMotivationalBoost() async {
    final motivationalMessages = [
      "💪 Konsistensi adalah kunci kesuksesan! Keep going!",
      "🌟 Setiap langkah kecil membawa kamu lebih dekat ke tujuan!",
      "🎯 Focus on progress, not perfection!",
      "🔥 Your body can do it. It's your mind you need to convince!",
      "✨ Strong is the new beautiful!",
      "🏃‍♂️ The only bad workout is the one that didn't happen!",
      "🥗 Fuel your body with good choices today!",
      "💚 Health is not about the weight you lose, but about the life you gain!",
    ];

    final randomMessage = motivationalMessages[DateTime.now().millisecond % motivationalMessages.length];

    await _localNotifications.showCustomNotification(
      title: "✨ Motivasi Hari Ini",
      body: randomMessage,
      data: {'action': 'open_tracking', 'type': 'motivational'},
    );
  }

  // MODIFIED: Trigger reminder check (now just calls specific functions, workmanager handles scheduling)
  Future<void> triggerReminderCheck() async {
    final now = DateTime.now();
    final hour = now.hour;

    switch (hour) {
      case 9:
        print('🌅 Morning reminder check');
        break;
      case 12:
        print('🍽️ Lunch reminder check');
        break;
      case 15:
        await checkMotivationalBoost();
        break;
      case 18:
        await checkOvereatingAlert();
        break;
      case 20:
        await checkWaterReminder();
        break;
    }
  }

  // KEEP EXISTING: Log notification sent
  Future<void> _logNotificationSent(String type, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'notificationHistory': FieldValue.arrayUnion([
          {
            'type': type,
            'timestamp': FieldValue.serverTimestamp(),
            'data': data,
            'sent': true,
          }
        ]),
        'lastNotificationSent': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging notification: $e');
    }
  }

  // ENHANCED: Update reminder preferences with workmanager control
  Future<void> updateReminderPreferences({
    bool? morningReminder,
    bool? lunchReminder,
    bool? eveningReminder,
    bool? nightCheck,
    bool? smartNotifications,  // ADDED
    String? morningTime,
    String? lunchTime,
    String? eveningTime,
    String? nightTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};

    if (morningReminder != null) updates['reminderSettings.morningReminder'] = morningReminder;
    if (lunchReminder != null) updates['reminderSettings.lunchReminder'] = lunchReminder;
    if (eveningReminder != null) updates['reminderSettings.eveningReminder'] = eveningReminder;
    if (nightCheck != null) updates['reminderSettings.nightCheck'] = nightCheck;
    if (smartNotifications != null) updates['reminderSettings.smartNotifications'] = smartNotifications;

    if (morningTime != null) updates['reminderTimes.morning'] = morningTime;
    if (lunchTime != null) updates['reminderTimes.lunch'] = lunchTime;
    if (eveningTime != null) updates['reminderTimes.evening'] = eveningTime;
    if (nightTime != null) updates['reminderTimes.night'] = nightTime;

    if (updates.isNotEmpty) {
      updates['lastReminderUpdate'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Handle smart notifications toggle
      if (smartNotifications != null) {
        if (smartNotifications) {
          await startBackgroundNotifications();
        } else {
          await stopBackgroundNotifications();
        }
      }

      await _localNotifications.rescheduleAllReminders();
      print('✅ Reminder preferences updated');
    }
  }

  // KEEP EXISTING: Get reminder status
  Future<Map<String, dynamic>> getReminderStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'enabled': false};

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData == null) return {'enabled': false};

      return {
        'enabled': userData['reminderSettings']?['enabled'] ?? true,
        'smartNotifications': userData['reminderSettings']?['smartNotifications'] ?? true,
        'settings': userData['reminderSettings'] ?? {},
        'times': userData['reminderTimes'] ?? {},
        'lastUpdate': userData['lastReminderUpdate'],
      };
    } catch (e) {
      print('Error getting reminder status: $e');
      return {'enabled': false, 'error': e.toString()};
    }
  }

  // MODIFIED: Dispose method
  void dispose() {
    // REMOVED: _backgroundChecker?.cancel();
    // ADDED: Cancel workmanager tasks
    Workmanager().cancelByUniqueName("smart_notification_task").catchError((e) {
      print('Error canceling workmanager task: $e');
    });
    
    _isInitialized = false;
    _backgroundNotificationsEnabled = false;
  }

  // ADDED: Manual trigger for testing
  Future<void> testBackgroundNotification() async {
    await _localNotifications.showCustomNotification(
      title: "🧪 Test Notification",
      body: "Background notification system is working! This is a test from DailyReminderService.",
      data: {'action': 'test', 'type': 'test_notification'},
    );
    print('✅ Test notification sent');
  }
}