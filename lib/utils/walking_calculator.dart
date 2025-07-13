import 'dart:math';

class WalkingCalculator {
  static const double earthRadiusKm = 6371.0;
  static const double averageStrideLength = 0.75;
  static const double walkingMetValue = 3.0;
  static const double joggingMetValue = 7.0;
  static const double runningMetValue = 11.0;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  double calculateSpeed(double distanceMeters, int timeSeconds) {
    if (timeSeconds == 0) return 0.0;
    return (distanceMeters / timeSeconds) * 3.6;
  }

  double calculatePace(double distanceKm, int timeSeconds) {
    if (distanceKm == 0) return 0.0;
    final timeMinutes = timeSeconds / 60.0;
    return timeMinutes / distanceKm;
  }

  double calculateRealTimePace(double speedKmh) {
    if (speedKmh <= 0) return 0.0;
    return 60.0 / speedKmh;
  }

  String formatPace(double paceMinutesPerKm) {
    if (paceMinutesPerKm <= 0) return '0:00';
    final minutes = paceMinutesPerKm.floor();
    final seconds = ((paceMinutesPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double calculateCaloriesFromSteps(int steps, double weightKg, {double? strideLength}) {
    final stride = strideLength ?? averageStrideLength;
    final distanceKm = (steps * stride) / 1000;
    return calculateCaloriesFromDistance(distanceKm, weightKg);
  }

  double calculateCaloriesFromDistance(double distanceKm, double weightKg, {double? avgSpeed}) {
    final speed = avgSpeed ?? 5.0;
    final met = _getMetFromSpeed(speed);
    final timeHours = distanceKm / speed;
    return met * weightKg * timeHours;
  }

  double calculateCaloriesFromTime(int timeSeconds, double weightKg, {double? avgSpeed}) {
    final speed = avgSpeed ?? 5.0;
    final met = _getMetFromSpeed(speed);
    final timeHours = timeSeconds / 3600.0;
    return met * weightKg * timeHours;
  }

  double calculateRealTimeCalories({
    required double distanceKm,
    required int durationSeconds,
    required double weightKg,
    int? steps,
  }) {
    if (durationSeconds <= 0) return 0.0;

    final timeHours = durationSeconds / 3600.0;
    final avgSpeed = distanceKm / timeHours;
    final met = _getMetFromSpeed(avgSpeed);
    
    double baseCalories = met * weightKg * timeHours;

    if (steps != null && steps > 0) {
      final stepCalories = calculateCaloriesFromSteps(steps, weightKg);
      baseCalories = max(baseCalories, stepCalories);
    }

    return baseCalories;
  }

  double _getMetFromSpeed(double speedKmh) {
    if (speedKmh < 3.0) {
      return 2.0;
    } else if (speedKmh < 4.0) {
      return 2.5;
    } else if (speedKmh < 5.5) {
      return walkingMetValue;
    } else if (speedKmh < 6.5) {
      return 3.5;
    } else if (speedKmh < 8.0) {
      return 4.5;
    } else if (speedKmh < 10.0) {
      return joggingMetValue;
    } else if (speedKmh < 12.0) {
      return 8.5;
    } else if (speedKmh < 14.0) {
      return 10.0;
    } else {
      return runningMetValue;
    }
  }

  int calculateStepsFromDistance(double distanceKm, {double? strideLength}) {
    final stride = strideLength ?? averageStrideLength;
    return ((distanceKm * 1000) / stride).round();
  }

  double calculateDistanceFromSteps(int steps, {double? strideLength}) {
    final stride = strideLength ?? averageStrideLength;
    return (steps * stride) / 1000;
  }

  double calculateStrideLength(double heightCm) {
    return heightCm * 0.43 / 100;
  }

  Map<String, dynamic> calculateLiveWorkoutStats({
    required int steps,
    required double distanceKm,
    required int durationSeconds,
    required double weightKg,
    required double currentSpeed,
    required double maxSpeed,
    double? heightCm,
  }) {
    final stride = heightCm != null ? calculateStrideLength(heightCm) : averageStrideLength;
    
    final avgSpeed = durationSeconds > 0 ? distanceKm / (durationSeconds / 3600.0) : 0.0;
    final calories = calculateRealTimeCalories(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      steps: steps,
    );
    
    final pace = calculateRealTimePace(avgSpeed);
    final currentPace = calculateRealTimePace(currentSpeed);
    
    final intensity = _getIntensityLevel(avgSpeed);
    final currentIntensity = _getIntensityLevel(currentSpeed);

    return {
      'steps': steps,
      'distance': distanceKm,
      'duration': durationSeconds,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'currentSpeed': currentSpeed,
      'maxSpeed': maxSpeed,
      'pace': pace,
      'currentPace': currentPace,
      'strideLength': stride,
      'intensity': intensity,
      'currentIntensity': currentIntensity,
      'formattedPace': formatPace(pace),
      'formattedCurrentPace': formatPace(currentPace),
    };
  }

  Map<String, dynamic> calculateWorkoutSummary({
    required int steps,
    required double distanceKm,
    required int durationSeconds,
    required double weightKg,
    double? heightCm,
  }) {
    final stride = heightCm != null ? calculateStrideLength(heightCm) : averageStrideLength;
    final avgSpeed = calculateSpeed(distanceKm * 1000, durationSeconds);
    final calories = calculateCaloriesFromDistance(distanceKm, weightKg, avgSpeed: avgSpeed);
    final pace = calculatePace(distanceKm, durationSeconds);

    return {
      'steps': steps,
      'distance': distanceKm,
      'duration': durationSeconds,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'pace': pace,
      'strideLength': stride,
      'intensity': _getIntensityLevel(avgSpeed),
    };
  }

  String _getIntensityLevel(double speedKmh) {
    if (speedKmh < 3.0) {
      return 'Sangat Ringan';
    } else if (speedKmh < 4.0) {
      return 'Ringan';
    } else if (speedKmh < 6.0) {
      return 'Sedang';
    } else if (speedKmh < 8.0) {
      return 'Tinggi';
    } else if (speedKmh < 10.0) {
      return 'Sangat Tinggi';
    } else {
      return 'Ekstrem';
    }
  }

  double calculateTargetCalories(double weightKg, int targetMinutes, {String intensity = 'sedang'}) {
    double met;
    switch (intensity.toLowerCase()) {
      case 'ringan':
        met = 2.5;
        break;
      case 'sedang':
        met = walkingMetValue;
        break;
      case 'tinggi':
        met = 4.5;
        break;
      case 'sangat tinggi':
        met = joggingMetValue;
        break;
      default:
        met = walkingMetValue;
    }
    
    final timeHours = targetMinutes / 60.0;
    return met * weightKg * timeHours;
  }

  int calculateTargetSteps(double targetDistanceKm, {double? strideLength}) {
    final stride = strideLength ?? averageStrideLength;
    return ((targetDistanceKm * 1000) / stride).round();
  }

  double calculateTargetDistance(int targetSteps, {double? strideLength}) {
    final stride = strideLength ?? averageStrideLength;
    return (targetSteps * stride) / 1000;
  }

  Map<String, dynamic> calculateDailyGoals({
    required double weightKg,
    required int age,
    required double heightCm,
    String activityLevel = 'sedang',
  }) {
    int targetSteps;
    double targetDistance;
    double targetCalories;
    int targetMinutes;

    switch (activityLevel.toLowerCase()) {
      case 'rendah':
        targetSteps = 6000;
        targetMinutes = 30;
        break;
      case 'sedang':
        targetSteps = 8000;
        targetMinutes = 45;
        break;
      case 'tinggi':
        targetSteps = 10000;
        targetMinutes = 60;
        break;
      case 'sangat tinggi':
        targetSteps = 12000;
        targetMinutes = 75;
        break;
      default:
        targetSteps = 8000;
        targetMinutes = 45;
    }

    final stride = calculateStrideLength(heightCm);
    targetDistance = calculateTargetDistance(targetSteps, strideLength: stride);
    targetCalories = calculateTargetCalories(weightKg, targetMinutes, intensity: activityLevel);

    return {
      'targetSteps': targetSteps,
      'targetDistance': targetDistance,
      'targetCalories': targetCalories,
      'targetMinutes': targetMinutes,
      'activityLevel': activityLevel,
      'strideLength': stride,
    };
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  String formatSpeed(double kmh) {
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String formatPaceFromSpeed(double speedKmh) {
    final pace = calculateRealTimePace(speedKmh);
    return formatPace(pace);
  }

  String formatCalories(double calories) {
    return '${calories.toStringAsFixed(0)} kal';
  }

  double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Kurus';
    } else if (bmi < 25.0) {
      return 'Normal';
    } else if (bmi < 30.0) {
      return 'Gemuk';
    } else {
      return 'Obesitas';
    }
  }

  Map<String, dynamic> getHealthRecommendations(double bmi, int age) {
    final category = getBMICategory(bmi);
    
    switch (category) {
      case 'Kurus':
        return {
          'recommendation': 'Fokus pada penambahan massa otot dengan kombinasi kardio ringan dan latihan kekuatan',
          'walkingDuration': 20,
          'intensity': 'ringan',
          'frequency': 'daily',
        };
      case 'Normal':
        return {
          'recommendation': 'Pertahankan kondisi dengan aktivitas teratur dan pola hidup sehat',
          'walkingDuration': 30,
          'intensity': 'sedang',
          'frequency': 'daily',
        };
      case 'Gemuk':
        return {
          'recommendation': 'Kombinasi kardio dan diet seimbang untuk menurunkan berat badan',
          'walkingDuration': 45,
          'intensity': 'sedang',
          'frequency': 'daily',
        };
      case 'Obesitas':
        return {
          'recommendation': 'Konsultasi dokter dan mulai dengan aktivitas ringan secara bertahap',
          'walkingDuration': 20,
          'intensity': 'ringan',
          'frequency': 'daily',
        };
      default:
        return {
          'recommendation': 'Konsultasi dengan profesional kesehatan',
          'walkingDuration': 30,
          'intensity': 'sedang',
          'frequency': 'daily',
        };
    }
  }

  List<Map<String, dynamic>> calculateSplitTimes(List<double> routeDistances, List<DateTime> timestamps) {
    List<Map<String, dynamic>> splits = [];
    double cumulativeDistance = 0.0;
    int splitIndex = 1;
    
    for (int i = 0; i < routeDistances.length; i++) {
      cumulativeDistance += routeDistances[i] / 1000;
      
      if (cumulativeDistance >= splitIndex) {
        final splitTime = timestamps[i].difference(timestamps[0]).inSeconds;
        final splitPace = calculatePace(splitIndex.toDouble(), splitTime);
        
        splits.add({
          'split': splitIndex,
          'time': splitTime,
          'pace': splitPace,
          'formattedTime': formatDuration(splitTime),
          'formattedPace': formatPace(splitPace),
        });
        
        splitIndex++;
      }
    }
    
    return splits;
  }

  double calculateCaloriesBurn({
    required double weightKg,
    required int durationMinutes,
    required double avgSpeedKmh,
  }) {
    final met = _getMetFromSpeed(avgSpeedKmh);
    final timeHours = durationMinutes / 60.0;
    return met * weightKg * timeHours;
  }

  Map<String, dynamic> predictWorkoutCompletion({
    required double currentDistance,
    required double targetDistance,
    required int currentDuration,
    required double currentSpeed,
  }) {
    final remainingDistance = targetDistance - currentDistance;
    final estimatedTimeToComplete = remainingDistance / currentSpeed * 3600;
    final totalEstimatedTime = currentDuration + estimatedTimeToComplete;
    
    return {
      'remainingDistance': remainingDistance,
      'estimatedTimeToComplete': estimatedTimeToComplete.round(),
      'totalEstimatedTime': totalEstimatedTime.round(),
      'formattedEstimatedTime': formatDuration(totalEstimatedTime.round()),
      'completionPercentage': (currentDistance / targetDistance * 100).clamp(0, 100),
    };
  }
}