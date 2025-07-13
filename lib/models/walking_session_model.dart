class WalkingSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int steps;
  final double distance;
  final double calories;
  final int duration;
  final bool isActive;
  final List<LocationPoint> route;
  final double averageSpeed;
  final double maxSpeed;

  WalkingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.duration,
    required this.isActive,
    required this.route,
    required this.averageSpeed,
    required this.maxSpeed,
  });

  factory WalkingSession.fromMap(Map<String, dynamic> map) {
    return WalkingSession(
      id: map['id'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      steps: map['steps'] ?? 0,
      distance: map['distance']?.toDouble() ?? 0.0,
      calories: map['calories']?.toDouble() ?? 0.0,
      duration: map['duration'] ?? 0,
      isActive: map['isActive'] ?? false,
      route: (map['route'] as List<dynamic>?)
          ?.map((point) => LocationPoint.fromMap(point))
          .toList() ?? [],
      averageSpeed: map['averageSpeed']?.toDouble() ?? 0.0,
      maxSpeed: map['maxSpeed']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'duration': duration,
      'isActive': isActive,
      'route': route.map((point) => point.toMap()).toList(),
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
    };
  }

  WalkingSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? steps,
    double? distance,
    double? calories,
    int? duration,
    bool? isActive,
    List<LocationPoint>? route,
    double? averageSpeed,
    double? maxSpeed,
  }) {
    return WalkingSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      route: route ?? this.route,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
    );
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  String get formattedSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/h';
  }

  String get formattedCalories {
    return '${calories.toStringAsFixed(0)} kal';
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.accuracy,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      altitude: map['altitude']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'altitude': altitude,
      'accuracy': accuracy,
    };
  }
}