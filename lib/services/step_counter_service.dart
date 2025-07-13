import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'permission_service.dart';

class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  final PermissionService _permissionService = PermissionService();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  StreamController<int>? _stepController;
  StreamController<String>? _statusController;

  int _sessionSteps = 0;
  int _initialSteps = 0;
  int _currentTotalSteps = 0;
  bool _isTracking = false;
  bool _isPaused = false;
  String _pedestrianStatus = 'stopped';

  Stream<int>? get stepStream => _stepController?.stream;
  Stream<String>? get statusStream => _statusController?.stream;

  int get currentSteps => _sessionSteps;
  int get totalSteps => _currentTotalSteps;
  String get pedestrianStatus => _pedestrianStatus;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;

  Future<bool> startCounting() async {
    try {
      if (_isTracking) {
        print('⚠️ Step counter already tracking');
        return true;
      }

      final hasPermission = await _permissionService
          .requestAllWalkingPermissions();
      if (!hasPermission) {
        print('❌ Step counter: permissions denied');
        return false;
      }

      _stepController = StreamController<int>.broadcast();
      _statusController = StreamController<String>.broadcast();

      _isTracking = true;
      _isPaused = false;
      _sessionSteps = 0;
      _initialSteps = 0;

      await _startPedometerTracking();
      await _startPedestrianStatusTracking();

      print('✅ Step counter started successfully');
      return true;
    } catch (e) {
      print('❌ Step counter start failed: $e');
      return false;
    }
  }

  Future<void> _startPedometerTracking() async {
    try {
      _stepCountSubscription?.cancel();

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (!_isTracking || _isPaused) return;

          _currentTotalSteps = event.steps;

          if (_initialSteps == 0) {
            _initialSteps = event.steps;
            print('📊 Initial steps set to: $_initialSteps');
          }

          _sessionSteps = _currentTotalSteps - _initialSteps;
          _stepController?.add(_sessionSteps);

          print(
            '👣 Session steps: $_sessionSteps (Total: $_currentTotalSteps)',
          );
        },
        onError: (error) {
          print('❌ Step count error: $error');
          _statusController?.add('sensor_error');
        },
      );

      print('📱 Pedometer listener started');
    } catch (e) {
      print('❌ Failed to start pedometer: $e');
      rethrow;
    }
  }

  Future<void> _startPedestrianStatusTracking() async {
    try {
      _pedestrianStatusSubscription?.cancel();

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          if (!_isTracking || _isPaused) return;

          String newStatus = event.status.toLowerCase();

          if (newStatus != _pedestrianStatus) {
            _pedestrianStatus = newStatus;
            _statusController?.add(_pedestrianStatus);
            print('🚶 Status changed to: $_pedestrianStatus');
          }
        },
        onError: (error) {
          print('❌ Pedestrian status error: $error');
          _pedestrianStatus = 'unknown';
          _statusController?.add(_pedestrianStatus);
        },
      );

      print('🚶 Pedestrian status listener started');
    } catch (e) {
      print('❌ Failed to start pedestrian status: $e');
    }
  }

  Future<void> pauseCounting() async {
    if (!_isTracking || _isPaused) {
      return;
    }
    _isPaused = true;
    print('⏸️ Step counter paused');
  }

  Future<void> resumeCounting() async {
    if (!_isTracking || !_isPaused) {
      return;
    }
    _isPaused = false;
    print('▶️ Step counter resumed');
  }

  Future<void> stopCounting() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;

    await _pedestrianStatusSubscription?.cancel();
    _pedestrianStatusSubscription = null;

    await _stepController?.close();
    _stepController = null;

    await _statusController?.close();
    _statusController = null;

    _isTracking = false;
    _isPaused = false;
    _sessionSteps = 0;
    _initialSteps = 0;
    _pedestrianStatus = 'stopped';

    print('🛑 Step counter stopped');
  }

  Future<bool> isStepCountingAvailable() async {
    try {
      final status = await _permissionService.checkSensorsPermission();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPedestrianStatusAvailable() async {
    try {
      final status = await _permissionService.checkActivityPermission();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  void resetSessionSteps() {
    _sessionSteps = 0;
    _initialSteps = _currentTotalSteps;
    if (_stepController != null && !_stepController!.isClosed) {
      _stepController!.add(_sessionSteps);
    }
    print('🔄 Session steps reset');
  }

  double calculateDistance({double? strideLength}) {
    final avgStrideLength = strideLength ?? 0.75;
    return (_sessionSteps * avgStrideLength) / 1000;
  }

  double calculateCalories({required double weightKg, double? strideLength}) {
    final distance = calculateDistance(strideLength: strideLength);
    final met = _getMetFromStatus();
    final estimatedTimeHours = _sessionSteps > 0 ? distance / 4.0 : 0.0;
    return met * weightKg * estimatedTimeHours;
  }

  double _getMetFromStatus() {
    switch (_pedestrianStatus.toLowerCase()) {
      case 'walking':
        return 3.5;
      case 'stopped':
        return 1.0;
      case 'unknown':
        return 2.5;
      default:
        return 3.0;
    }
  }

  Map<String, dynamic> getSessionSummary() {
    return {
      'steps': _sessionSteps,
      'totalSteps': _currentTotalSteps,
      'status': _pedestrianStatus,
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'initialSteps': _initialSteps,
    };
  }

  String getStatusEmoji() {
    switch (_pedestrianStatus.toLowerCase()) {
      case 'walking':
        return '🚶‍♂️';
      case 'stopped':
        return '🛑';
      case 'unknown':
        return '❓';
      default:
        return '🧍';
    }
  }

  String getStatusText() {
    switch (_pedestrianStatus.toLowerCase()) {
      case 'walking':
        return 'Sedang Berjalan';
      case 'stopped':
        return 'Berhenti';
      case 'unknown':
        return 'Tidak Diketahui';
      default:
        return 'Bergerak';
    }
  }

  void adjustSensitivity({
    required String userHeight,
    required String userWeight,
  }) {
    print('🎯 Using pedometer - no manual calibration needed');
    print('📏 User profile - Height: ${userHeight}cm, Weight: ${userWeight}kg');
  }

  void dispose() {
    stopCounting();
  }
}
