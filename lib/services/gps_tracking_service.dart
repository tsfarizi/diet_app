import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/walking_session_model.dart';
import 'permission_service.dart';

class GPSTrackingService {
  static final GPSTrackingService _instance = GPSTrackingService._internal();
  factory GPSTrackingService() => _instance;
  GPSTrackingService._internal();

  final PermissionService _permissionService = PermissionService();
  
  StreamSubscription<Position>? _positionSubscription;
  StreamController<LocationPoint>? _locationController;
  StreamController<String>? _errorController;
  Position? _lastKnownPosition;
  bool _isTracking = false;
  bool _isPaused = false;

  Stream<LocationPoint>? get locationStream => _locationController?.stream;
  Stream<String>? get errorStream => _errorController?.stream;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  Position? get lastKnownPosition => _lastKnownPosition;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
    timeLimit: Duration(seconds: 10),
  );

  Future<bool> startTracking() async {
    try {
      if (_isTracking) {
        return true;
      }

      final hasPermission = await _permissionService.requestLocationPermission();
      if (!hasPermission) {
        return false;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return false;
      }

      _locationController = StreamController<LocationPoint>.broadcast();
      _errorController = StreamController<String>.broadcast();
      
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: _onLocationError,
      );

      _isTracking = true;
      _isPaused = false;

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> pauseTracking() async {
    if (!_isTracking || _isPaused) {
      return;
    }

    _isPaused = true;
  }

  Future<void> resumeTracking() async {
    if (!_isTracking || !_isPaused) {
      return;
    }

    _isPaused = false;
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    
    await _locationController?.close();
    _locationController = null;
    
    await _errorController?.close();
    _errorController = null;
    
    _isTracking = false;
    _isPaused = false;
    _lastKnownPosition = null;
  }

  void _onLocationUpdate(Position position) {
    if (!_isTracking || _isPaused) {
      return;
    }

    _lastKnownPosition = position;
    
    final locationPoint = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      altitude: position.altitude,
      accuracy: position.accuracy,
    );

    _locationController?.add(locationPoint);
  }

  void _onLocationError(dynamic error) {
    if (error is LocationServiceDisabledException) {
      _errorController?.add('GPS service tidak aktif');
    } else if (error is PermissionDeniedException) {
      _errorController?.add('Permission GPS ditolak');
    } else if (error is PositionUpdateException) {
      _errorController?.add('Gagal mendapat posisi GPS');
    } else if (error is TimeoutException) {
      _errorController?.add('GPS timeout');
    } else {
      _errorController?.add('Error GPS: ${error.toString()}');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _permissionService.requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  Future<double> calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<double> calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  String getLocationPermissionStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Akses lokasi ditolak';
      case LocationPermission.deniedForever:
        return 'Akses lokasi ditolak permanen';
      case LocationPermission.whileInUse:
        return 'Akses lokasi saat aplikasi digunakan';
      case LocationPermission.always:
        return 'Akses lokasi selalu';
      default:
        return 'Status tidak diketahui';
    }
  }

  double calculateSpeed(Position position1, Position position2) {
    final distance = Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );

    final timeDifference = position2.timestamp.difference(position1.timestamp).inSeconds;
    
    if (timeDifference == 0) {
      return 0.0;
    }

    return (distance / timeDifference) * 3.6;
  }

  void dispose() {
    stopTracking();
  }
}