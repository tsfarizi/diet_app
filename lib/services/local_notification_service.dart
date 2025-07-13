import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'diet_reminders';
  static const String _channelName = 'Diet Reminders';
  static const String _channelDescription = 'Automatic reminders for diet tracking';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    
    await _requestPermissions();
    await _initializeNotifications();
    await _scheduleAllReminders();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _scheduleAllReminders() async {
    await _scheduleMorningReminder();
    await _scheduleLunchReminder();
    await _scheduleEveningReminder();
    await _scheduleNightCheck();
  }

  Future<void> _scheduleMorningReminder() async {
    await _scheduleRepeatingNotification(
      id: 1,
      title: "🌅 Selamat Pagi!",
      body: "Jangan lupa sarapan sehat untuk memulai hari yang produktif! 🍳",
      hour: 9,
      minute: 0,
    );
  }

  Future<void> _scheduleLunchReminder() async {
    await _scheduleRepeatingNotification(
      id: 2,
      title: "🍽️ Waktunya Makan Siang!",
      body: "Jangan skip makan siang, tubuh butuh energi untuk aktivitas sore! 🥗",
      hour: 12,
      minute: 0,
    );
  }

  Future<void> _scheduleEveningReminder() async {
    await _scheduleSmartNotification(
      id: 3,
      hour: 18,
      minute: 0,
      checkType: 'exercise_steps',
    );
  }

  Future<void> _scheduleNightCheck() async {
    await _scheduleSmartNotification(
      id: 4,
      hour: 20,
      minute: 0,
      checkType: 'daily_targets',
    );
  }

  Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'reminder', 'action': 'open_app'}),
    );
  }

  Future<void> _scheduleSmartNotification({
    required int id,
    required int hour,
    required int minute,
    required String checkType,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      "⏰ Checking Progress...",
      "Sedang mengecek progress harian Anda...",
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'smart_check', 'checkType': checkType}),
    );
  }

  Future<void> checkAndShowSmartNotification(String checkType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      if (checkType == 'exercise_steps') {
        await _checkExerciseAndSteps(userData);
      } else if (checkType == 'daily_targets') {
        await _checkDailyTargets(userData);
      }
    } catch (e) {
      print('Error checking smart notification: $e');
    }
  }

  Future<void> _checkExerciseAndSteps(Map<String, dynamic> userData) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStats = userData['dailyStats'] != null && userData['dailyStats'][today] != null
        ? userData['dailyStats'][today] as Map<String, dynamic>
        : <String, dynamic>{};
    
    final currentSteps = todayStats['steps'] ?? 0;
    final stepTarget = userData['stepTarget'] ?? 8000;
    final hasExercised = todayStats['exercise'] ?? false;

    String title = "🏃‍♂️ Waktunya Bergerak!";
    String body = "";

    if (currentSteps < 5000 && !hasExercised) {
      body = "Langkah hari ini: $currentSteps. Yuk jalan kaki atau olahraga ringan! 👟";
    } else if (currentSteps < stepTarget) {
      final remaining = stepTarget - currentSteps;
      body = "Langkah: $currentSteps/$stepTarget. Masih kurang $remaining langkah! 🚶‍♂️";
    } else if (!hasExercised) {
      body = "Langkah sudah $currentSteps! Tambah olahraga untuk kesehatan optimal 💪";
    } else {
      title = "🎉 Great Job!";
      body = "Langkah: $currentSteps, sudah olahraga! Pertahankan! ✨";
    }

    await _showInstantNotification(
      id: 100,
      title: title,
      body: body,
      payload: {'action': 'open_exercise'},
    );
  }

  Future<void> _checkDailyTargets(Map<String, dynamic> userData) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStats = userData['dailyStats'] != null && userData['dailyStats'][today] != null
        ? userData['dailyStats'][today] as Map<String, dynamic>
        : <String, dynamic>{};
    
    final currentCalories = todayStats['calories'] ?? 0;
    final calorieTarget = userData['calorieTarget'] ?? 2000;
    final currentSteps = todayStats['steps'] ?? 0;
    final stepTarget = userData['stepTarget'] ?? 8000;

    final calorieProgress = ((currentCalories / calorieTarget) * 100).round();
    final stepProgress = ((currentSteps / stepTarget) * 100).round();

    String title = "🌙 Recap Hari Ini";
    String body = "";

    if (calorieProgress >= 100 && stepProgress >= 100) {
      title = "🎉 Target Tercapai!";
      body = "Luar biasa! Semua target hari ini sudah tercapai. Keep it up! 💪";
    } else if (currentCalories > calorieTarget * 1.1) {
      title = "⚠️ Kalori Berlebih";
      final excess = currentCalories - calorieTarget;
      body = "Kalori hari ini $excess lebih dari target. Pertimbangkan olahraga tambahan! 🏃‍♂️";
    } else if (calorieProgress < 80) {
      final remaining = calorieTarget - currentCalories;
      title = "📊 Target Kalori Belum Tercapai";
      body = "Kalori: $currentCalories/$calorieTarget. Masih kurang $remaining kalori.";
    } else {
      body = "Kalori: $calorieProgress% | Langkah: $stepProgress%. ";
      if (stepProgress < 80) {
        body += "Besok lebih semangat lagi ya! 💪";
      } else {
        body += "Progress bagus! 👍";
      }
    }

    await _showInstantNotification(
      id: 101,
      title: title,
      body: body,
      payload: {'action': 'open_analytics'},
    );
  }

  // EXISTING: Private method (keep as is)
  Future<void> _showInstantNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  // ADDED: Public method for workmanager background callbacks
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        payload: payload != null ? {'raw_payload': payload} : null,
      );
      
      print('✅ Instant notification sent: $title');
    } catch (e) {
      print('❌ Error sending instant notification: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'];
        
        if (type == 'smart_check') {
          final checkType = data['checkType'];
          checkAndShowSmartNotification(checkType);
        }
        
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // EXISTING: Keep this method as is (already perfect)
  Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      payload: data,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllReminders() async {
    await cancelAllNotifications();
    await _scheduleAllReminders();
  }
}