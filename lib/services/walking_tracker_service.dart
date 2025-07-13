import 'dart:async';
import 'dart:math';
import '../models/walking_session_model.dart';
import '../services/database_service.dart';
import 'gps_tracking_service.dart';
import 'step_counter_service.dart';
import 'permission_service.dart';
import '../utils/walking_calculator.dart';

class WalkingTrackerService {
  static final WalkingTrackerService _instance = WalkingTrackerService._internal();
  factory WalkingTrackerService() => _instance;
  WalkingTrackerService._internal();

  final GPSTrackingService _gpsService = GPSTrackingService();
  final StepCounterService _stepService = StepCounterService();
  final PermissionService _permissionService = PermissionService();
  final WalkingCalculator _calculator = WalkingCalculator();
  final DatabaseService _databaseService = DatabaseService();

  WalkingSession? _currentSession;
  Timer? _sessionTimer;
  Timer? _statsUpdateTimer;
  StreamController<WalkingSession>? _sessionController;

  double _userWeight = 70.0;

  StreamSubscription<LocationPoint>? _gpsSubscription;
  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<String>? _gpsErrorSubscription;

  Stream<WalkingSession>? get sessionStream => _sessionController?.stream;
  WalkingSession? get currentSession => _currentSession;
  bool get isTracking => _currentSession?.isActive ?? false;

  Future<bool> startWalkingSession({
    required double userWeight,
    required int userAge,
    required double userHeight,
  }) async {
    try {
      if (_currentSession?.isActive == true) {
        return false;
      }

      _userWeight = userWeight;

      final hasAllPermissions = await _requestAllPermissions();
      if (!hasAllPermissions) {
        throw Exception('Permission tidak lengkap');
      }

      final gpsStarted = await _gpsService.startTracking();
      if (!gpsStarted) {
        throw Exception('GPS service gagal dimulai');
      }

      final stepStarted = await _stepService.startCounting();
      if (!stepStarted) {
        print('⚠️ Step counter gagal, menggunakan GPS saja');
      }

      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      _currentSession = WalkingSession(
        id: sessionId,
        startTime: DateTime.now(),
        steps: 0,
        distance: 0.0,
        calories: 0.0,
        duration: 0,
        isActive: true,
        route: [],
        averageSpeed: 0.0,
        maxSpeed: 0.0,
      );

      _sessionController = StreamController<WalkingSession>.broadcast();

      _startSessionTimer();
      _startStatsUpdateTimer();
      _listenToSteps();
      _listenToGPS();
      _listenToGPSErrors();

      print('✅ Walking session started successfully');
      return true;

    } catch (e) {
      print('❌ Failed to start walking session: $e');
      await _cleanup();
      return false;
    }
  }

  Future<bool> _requestAllPermissions() async {
    try {
      final hasLocation = await _permissionService.requestLocationPermission();
      final hasActivity = await _permissionService.requestActivityPermission();
      final hasSensors = await _permissionService.requestSensorsPermission();

      print('📍 Location permission: $hasLocation');
      print('🏃 Activity permission: $hasActivity');
      print('📱 Sensors permission: $hasSensors');

      return hasLocation && hasActivity;
    } catch (e) {
      print('❌ Permission error: $e');
      return false;
    }
  }

  void _listenToGPS() {
    _gpsSubscription?.cancel();
    _gpsSubscription = _gpsService.locationStream?.listen(
          (location) {
        _handleLocationUpdate(location);
      },
      onError: (error) {
        print('❌ GPS location error: $error');
      },
    );
    print('📍 GPS listener started');
  }

  void _listenToGPSErrors() {
    _gpsErrorSubscription?.cancel();
    _gpsErrorSubscription = _gpsService.errorStream?.listen(
          (error) {
        print('❌ GPS error: $error');
      },
    );
  }

  void _listenToSteps() {
    _stepSubscription?.cancel();
    _stepSubscription = _stepService.stepStream?.listen(
          (steps) {
        _handleStepUpdate(steps);
      },
      onError: (error) {
        print('❌ Step counter error: $error');
      },
    );
    print('🚶 Step listener started');
  }

  void _handleLocationUpdate(LocationPoint location) {
    if (_currentSession == null || !_currentSession!.isActive) return;

    final newRoute = List<LocationPoint>.from(_currentSession!.route);

    if (newRoute.isNotEmpty) {
      final lastPoint = newRoute.last;
      final distance = _calculateDistance(
        lastPoint.latitude,
        lastPoint.longitude,
        location.latitude,
        location.longitude,
      );

      final timeDiff = location.timestamp.difference(lastPoint.timestamp).inSeconds;

      if (distance < 1.0 && timeDiff < 3) {
        return;
      }

      if (distance > 100.0) {
        print('⚠️ GPS jump detected: ${distance.toInt()}m, ignoring');
        return;
      }
    }

    newRoute.add(location);

    _currentSession = _currentSession!.copyWith(route: newRoute);
    print('📍 Location updated: ${location.latitude}, ${location.longitude} (${newRoute.length} points)');
  }

  void _handleStepUpdate(int steps) {
    if (_currentSession == null || !_currentSession!.isActive) return;

    _currentSession = _currentSession!.copyWith(steps: steps);
    print('🚶 Steps updated: $steps');
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_currentSession != null && _currentSession!.isActive) {
        final now = DateTime.now();
        final duration = now.difference(_currentSession!.startTime).inSeconds;

        _currentSession = _currentSession!.copyWith(duration: duration);
        _sessionController?.add(_currentSession!);
      }
    });
    print('⏱️ Session timer started');
  }

  void _startStatsUpdateTimer() {
    _statsUpdateTimer?.cancel();
    _statsUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentSession != null && _currentSession!.isActive) {
        _updateRealTimeStats();
      }
    });
    print('📊 Stats update timer started');
  }

  void _updateRealTimeStats() {
    if (_currentSession == null || !_currentSession!.isActive) return;

    final route = _currentSession!.route;
    if (route.isEmpty) return;

    double totalDistance = 0.0;
    double maxSpeed = _currentSession!.maxSpeed;

    if (route.length > 1) {
      for (int i = 1; i < route.length; i++) {
        totalDistance += _calculateDistance(
          route[i-1].latitude,
          route[i-1].longitude,
          route[i].latitude,
          route[i].longitude,
        );
      }

      if (route.length >= 2) {
        final currentSpeed = _calculateCurrentSpeed(route);
        if (currentSpeed > maxSpeed && currentSpeed < 30.0) {
          maxSpeed = currentSpeed;
        }
      }
    }

    final averageSpeed = _currentSession!.duration > 0
        ? (totalDistance / 1000) / (_currentSession!.duration / 3600)
        : 0.0;

    final distanceCalories = _calculator.calculateRealTimeCalories(
      distanceKm: totalDistance / 1000,
      durationSeconds: _currentSession!.duration,
      weightKg: _userWeight,
      steps: _currentSession!.steps,
    );

    _currentSession = _currentSession!.copyWith(
      distance: totalDistance,
      calories: distanceCalories,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
    );

    _sessionController?.add(_currentSession!);
    print('📊 Stats updated - Distance: ${totalDistance.toInt()}m, Calories: ${distanceCalories.toInt()}, Speed: ${averageSpeed.toStringAsFixed(1)}km/h');
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _calculateCurrentSpeed(List<LocationPoint> route) {
    if (route.length < 2) return 0.0;

    final lastPoint = route[route.length - 1];
    final secondLastPoint = route[route.length - 2];

    final distance = _calculateDistance(
      secondLastPoint.latitude,
      secondLastPoint.longitude,
      lastPoint.latitude,
      lastPoint.longitude,
    );

    final timeDiff = lastPoint.timestamp.difference(secondLastPoint.timestamp).inSeconds;
    if (timeDiff == 0) return 0.0;

    final speed = (distance / timeDiff) * 3.6;

    return speed > 30.0 ? 0.0 : speed;
  }

  Future<WalkingSession?> pauseSession() async {
    if (_currentSession == null || !_currentSession!.isActive) {
      return null;
    }

    _sessionTimer?.cancel();
    _statsUpdateTimer?.cancel();
    await _gpsService.pauseTracking();
    await _stepService.pauseCounting();

    _currentSession = _currentSession!.copyWith(isActive: false);
    _sessionController?.add(_currentSession!);

    print('⏸️ Session paused');
    return _currentSession;
  }

  Future<WalkingSession?> resumeSession() async {
    if (_currentSession == null || _currentSession!.isActive) {
      return null;
    }

    await _gpsService.resumeTracking();
    await _stepService.resumeCounting();

    _currentSession = _currentSession!.copyWith(isActive: true);
    _startSessionTimer();
    _startStatsUpdateTimer();
    _sessionController?.add(_currentSession!);

    print('▶️ Session resumed');
    return _currentSession;
  }

  Future<WalkingSession?> stopSession() async {
    if (_currentSession == null) {
      return null;
    }

    final finalSession = _currentSession!.copyWith(
      isActive: false,
      endTime: DateTime.now(),
    );

    try {
      await _databaseService.saveWalkingSession(finalSession);
      print('💾 Walking session saved to database successfully');
    } catch (e) {
      print('❌ Failed to save walking session to database: $e');
    }

    await _cleanup();

    print('🛑 Session stopped - Final stats: ${finalSession.formattedDistance}, ${finalSession.formattedDuration}, ${finalSession.steps} steps');
    return finalSession;
  }

  Future<void> _cleanup() async {
    _sessionTimer?.cancel();
    _statsUpdateTimer?.cancel();

    await _gpsService.stopTracking();
    await _stepService.stopCounting();

    await _gpsSubscription?.cancel();
    await _stepSubscription?.cancel();
    await _gpsErrorSubscription?.cancel();

    await _sessionController?.close();
    _sessionController = null;
    _currentSession = null;

    print('🧹 Cleanup completed');
  }

  Map<String, dynamic> getSessionStats() {
    if (_currentSession == null) {
      return {
        'duration': 0,
        'distance': 0.0,
        'steps': 0,
        'calories': 0.0,
        'averageSpeed': 0.0,
        'maxSpeed': 0.0,
        'pace': '0:00 min/km',
        'isActive': false,
      };
    }

    final pace = _currentSession!.averageSpeed > 0
        ? 60.0 / _currentSession!.averageSpeed
        : 0.0;
    final paceMinutes = pace.floor();
    final paceSeconds = ((pace - paceMinutes) * 60).round();

    return {
      'duration': _currentSession!.duration,
      'distance': _currentSession!.distance,
      'steps': _currentSession!.steps,
      'calories': _currentSession!.calories,
      'averageSpeed': _currentSession!.averageSpeed,
      'maxSpeed': _currentSession!.maxSpeed,
      'pace': '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')} min/km',
      'isActive': _currentSession!.isActive,
    };
  }

  String getFormattedDuration() {
    if (_currentSession == null) return '00:00';

    final duration = _currentSession!.duration;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<List<WalkingSession>> getTodaysSessions() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      return await _databaseService.getWalkingSessionsForDateRange(startOfDay, endOfDay);
    } catch (e) {
      print('❌ Failed to get today sessions: $e');
      return [];
    }
  }

  Future<List<WalkingSession>> getWeeklySessions() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));

      return await _databaseService.getWalkingSessionsForDateRange(weekAgo, now);
    } catch (e) {
      print('❌ Failed to get weekly sessions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final sessions = await getTodaysSessions();

      double totalDistance = 0.0;
      double totalCalories = 0.0;
      int totalSteps = 0;
      int totalDuration = 0;

      for (var session in sessions) {
        totalDistance += session.distance;
        totalCalories += session.calories;
        totalSteps += session.steps;
        totalDuration += session.duration;
      }

      return {
        'sessions': sessions.length,
        'totalDistance': totalDistance,
        'totalCalories': totalCalories,
        'totalSteps': totalSteps,
        'totalDuration': totalDuration,
        'averageSpeed': totalDuration > 0 ? (totalDistance / 1000) / (totalDuration / 3600) : 0.0,
      };
    } catch (e) {
      print('❌ Failed to get today stats: $e');
      return {
        'sessions': 0,
        'totalDistance': 0.0,
        'totalCalories': 0.0,
        'totalSteps': 0,
        'totalDuration': 0,
        'averageSpeed': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    try {
      final now = DateTime.now();
      final weeklyData = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final sessions = await _databaseService.getWalkingSessionsForDateRange(startOfDay, endOfDay);

        double dayDistance = 0.0;
        double dayCalories = 0.0;
        int daySteps = 0;
        int dayDuration = 0;

        for (var session in sessions) {
          dayDistance += session.distance;
          dayCalories += session.calories;
          daySteps += session.steps;
          dayDuration += session.duration;
        }

        weeklyData.add({
          'date': date,
          'dayName': _getDayName(date.weekday),
          'sessions': sessions.length,
          'distance': dayDistance,
          'calories': dayCalories,
          'steps': daySteps,
          'duration': dayDuration,
        });
      }

      return weeklyData;
    } catch (e) {
      print('❌ Failed to get weekly stats: $e');
      return [];
    }
  }

  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  void dispose() {
    _cleanup();
  }
}