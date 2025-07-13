import 'dart:math';
import '../models/walking_session_model.dart';

class GPSUtils {
  static const double earthRadiusKm = 6371.0;
  static const double minAccuracyMeters = 20.0;
  static const double maxSpeedKmh = 50.0;

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);
    
    final double y = sin(dLon) * cos(lat2Rad);
    final double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    
    final double bearing = atan2(y, x);
    return _radiansToDegrees(bearing);
  }

  static double calculateSpeed(LocationPoint point1, LocationPoint point2) {
    final distance = calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
    
    final timeDiff = point2.timestamp.difference(point1.timestamp).inSeconds;
    if (timeDiff == 0) return 0.0;
    
    final speedMps = distance / timeDiff;
    return speedMps * 3.6;
  }

  static bool isLocationAccurate(LocationPoint point) {
    return point.accuracy != null && point.accuracy! <= minAccuracyMeters;
  }

  static bool isSpeedRealistic(double speedKmh) {
    return speedKmh <= maxSpeedKmh;
  }

  static List<LocationPoint> filterAccuratePoints(List<LocationPoint> points) {
    return points.where((point) => isLocationAccurate(point)).toList();
  }

  static List<LocationPoint> removeOutliers(List<LocationPoint> points) {
    if (points.length < 3) return points;
    
    final filteredPoints = <LocationPoint>[];
    filteredPoints.add(points.first);
    
    for (int i = 1; i < points.length - 1; i++) {
      final prevPoint = points[i - 1];
      final currentPoint = points[i];
      final nextPoint = points[i + 1];
      
      final speed1 = calculateSpeed(prevPoint, currentPoint);
      final speed2 = calculateSpeed(currentPoint, nextPoint);
      
      if (isSpeedRealistic(speed1) && isSpeedRealistic(speed2)) {
        filteredPoints.add(currentPoint);
      }
    }
    
    if (points.isNotEmpty) {
      filteredPoints.add(points.last);
    }
    
    return filteredPoints;
  }

  static double calculateTotalDistance(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    
    return totalDistance;
  }

  static double calculateAverageSpeed(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;
    
    final totalDistance = calculateTotalDistance(points);
    final totalTime = points.last.timestamp.difference(points.first.timestamp).inSeconds;
    
    if (totalTime == 0) return 0.0;
    
    final avgSpeedMps = totalDistance / totalTime;
    return avgSpeedMps * 3.6;
  }

  static double calculateMaxSpeed(List<LocationPoint> points) {
    if (points.length < 2) return 0.0;
    
    double maxSpeed = 0.0;
    for (int i = 1; i < points.length; i++) {
      final speed = calculateSpeed(points[i - 1], points[i]);
      if (speed > maxSpeed) {
        maxSpeed = speed;
      }
    }
    
    return maxSpeed;
  }

  static Map<String, dynamic> analyzeRoute(List<LocationPoint> points) {
    if (points.isEmpty) {
      return {
        'totalDistance': 0.0,
        'averageSpeed': 0.0,
        'maxSpeed': 0.0,
        'duration': 0,
        'pointCount': 0,
        'accuratePoints': 0,
      };
    }
    
    final filteredPoints = removeOutliers(filterAccuratePoints(points));
    final totalDistance = calculateTotalDistance(filteredPoints);
    final averageSpeed = calculateAverageSpeed(filteredPoints);
    final maxSpeed = calculateMaxSpeed(filteredPoints);
    final duration = points.isNotEmpty 
        ? points.last.timestamp.difference(points.first.timestamp).inSeconds
        : 0;
    
    return {
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'duration': duration,
      'pointCount': points.length,
      'accuratePoints': filteredPoints.length,
      'filteredPoints': filteredPoints,
    };
  }

  static LocationPoint? getCenter(List<LocationPoint> points) {
    if (points.isEmpty) return null;
    
    double lat = 0.0;
    double lon = 0.0;
    
    for (final point in points) {
      lat += point.latitude;
      lon += point.longitude;
    }
    
    return LocationPoint(
      latitude: lat / points.length,
      longitude: lon / points.length,
      timestamp: DateTime.now(),
    );
  }

  static Map<String, double> getBounds(List<LocationPoint> points) {
    if (points.isEmpty) {
      return {
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLon': 0.0,
        'maxLon': 0.0,
      };
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;
    
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
    };
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  static String formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lonDirection = longitude >= 0 ? 'E' : 'W';
    
    return '${latitude.abs().toStringAsFixed(6)}°$latDirection, '
           '${longitude.abs().toStringAsFixed(6)}°$lonDirection';
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  static String formatSpeed(double kmh) {
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  static String formatBearing(double bearing) {
    final directions = [
      'Utara', 'Timur Laut', 'Timur', 'Tenggara',
      'Selatan', 'Barat Daya', 'Barat', 'Barat Laut'
    ];
    
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  static LocationPoint interpolatePoint(
    LocationPoint point1,
    LocationPoint point2,
    double ratio,
  ) {
    final lat = point1.latitude + (point2.latitude - point1.latitude) * ratio;
    final lon = point1.longitude + (point2.longitude - point1.longitude) * ratio;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      point1.timestamp.millisecondsSinceEpoch +
      ((point2.timestamp.millisecondsSinceEpoch - point1.timestamp.millisecondsSinceEpoch) * ratio).round()
    );
    
    return LocationPoint(
      latitude: lat,
      longitude: lon,
      timestamp: timestamp,
    );
  }

  static List<LocationPoint> smoothRoute(List<LocationPoint> points, {int windowSize = 3}) {
    if (points.length <= windowSize) return points;
    
    final smoothedPoints = <LocationPoint>[];
    
    for (int i = 0; i < points.length; i++) {
      if (i < windowSize ~/ 2 || i >= points.length - windowSize ~/ 2) {
        smoothedPoints.add(points[i]);
      } else {
        double avgLat = 0.0;
        double avgLon = 0.0;
        
        for (int j = i - windowSize ~/ 2; j <= i + windowSize ~/ 2; j++) {
          avgLat += points[j].latitude;
          avgLon += points[j].longitude;
        }
        
        avgLat /= windowSize;
        avgLon /= windowSize;
        
        smoothedPoints.add(LocationPoint(
          latitude: avgLat,
          longitude: avgLon,
          timestamp: points[i].timestamp,
          altitude: points[i].altitude,
          accuracy: points[i].accuracy,
        ));
      }
    }
    
    return smoothedPoints;
  }
}