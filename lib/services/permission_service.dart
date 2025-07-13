import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestLocationPermission() async {
    try {
      final status = await permission_handler.Permission.location.request();
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestLocationAlwaysPermission() async {
    try {
      final status = await permission_handler.Permission.locationAlways.request();
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestActivityPermission() async {
    try {
      final status = await permission_handler.Permission.activityRecognition.request();
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestSensorsPermission() async {
    try {
      final status = await permission_handler.Permission.sensors.request();
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final status = await permission_handler.Permission.notification.request();
      return status == permission_handler.PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestFCMPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await permission_handler.Permission.notification.request();
        if (status != permission_handler.PermissionStatus.granted) {
          return false;
        }
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestScheduleExactAlarmPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await permission_handler.Permission.scheduleExactAlarm.request();
        return status == permission_handler.PermissionStatus.granted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestAllWalkingPermissions() async {
    final results = await [
      permission_handler.Permission.location,
      permission_handler.Permission.activityRecognition,
      permission_handler.Permission.sensors,
    ].request();

    return results.values.every((status) =>
      status == permission_handler.PermissionStatus.granted ||
      status == permission_handler.PermissionStatus.limited
    );
  }

  Future<bool> requestAllNotificationPermissions() async {
    final basicNotification = await requestNotificationPermission();
    final fcmPermission = await requestFCMPermission();
    final schedulePermission = await requestScheduleExactAlarmPermission();

    return basicNotification && fcmPermission && schedulePermission;
  }

  Future<permission_handler.PermissionStatus> checkLocationPermission() async {
    return await permission_handler.Permission.location.status;
  }

  Future<permission_handler.PermissionStatus> checkActivityPermission() async {
    return await permission_handler.Permission.activityRecognition.status;
  }

  Future<permission_handler.PermissionStatus> checkSensorsPermission() async {
    return await permission_handler.Permission.sensors.status;
  }

  Future<permission_handler.PermissionStatus> checkNotificationPermission() async {
    return await permission_handler.Permission.notification.status;
  }

  Future<AuthorizationStatus> checkFCMPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      return AuthorizationStatus.denied;
    }
  }

  Future<permission_handler.PermissionStatus> checkScheduleExactAlarmPermission() async {
    try {
      if (Platform.isAndroid) {
        return await permission_handler.Permission.scheduleExactAlarm.status;
      }
      return permission_handler.PermissionStatus.granted;
    } catch (e) {
      return permission_handler.PermissionStatus.denied;
    }
  }

  Future<Map<permission_handler.Permission, permission_handler.PermissionStatus>> checkAllWalkingPermissions() async {
    return await [
      permission_handler.Permission.location,
      permission_handler.Permission.activityRecognition,
      permission_handler.Permission.sensors,
    ].request();
  }

  Future<bool> openAppSettings() async {
    try {
      return await permission_handler.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  Future<bool> shouldShowLocationRationale() async {
    return await permission_handler.Permission.location.shouldShowRequestRationale;
  }

  Future<bool> shouldShowActivityRationale() async {
    return await permission_handler.Permission.activityRecognition.shouldShowRequestRationale;
  }

  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final status = await permission_handler.Permission.location.status;
    return status == permission_handler.PermissionStatus.permanentlyDenied;
  }

  Future<bool> isActivityPermissionPermanentlyDenied() async {
    final status = await permission_handler.Permission.activityRecognition.status;
    return status == permission_handler.PermissionStatus.permanentlyDenied;
  }

  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    final status = await permission_handler.Permission.notification.status;
    return status == permission_handler.PermissionStatus.permanentlyDenied;
  }

  String getPermissionStatusText(permission_handler.PermissionStatus status) {
    switch (status) {
      case permission_handler.PermissionStatus.denied:
        return 'Akses ditolak';
      case permission_handler.PermissionStatus.granted:
        return 'Akses diberikan';
      case permission_handler.PermissionStatus.restricted:
        return 'Akses dibatasi';
      case permission_handler.PermissionStatus.limited:
        return 'Akses terbatas';
      case permission_handler.PermissionStatus.permanentlyDenied:
        return 'Akses ditolak permanen';
      default:
        return 'Status tidak diketahui';
    }
  }

  String getFCMStatusText(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Diizinkan';
      case AuthorizationStatus.denied:
        return 'Ditolak';
      case AuthorizationStatus.notDetermined:
        return 'Belum ditentukan';
      case AuthorizationStatus.provisional:
        return 'Sementara';
    }
  }

  String getLocationPermissionRationale() {
    return 'Aplikasi membutuhkan akses lokasi untuk melacak jarak dan rute berjalan Anda. '
           'Data lokasi hanya digunakan selama sesi tracking dan tidak dibagikan ke pihak ketiga.';
  }

  String getActivityPermissionRationale() {
    return 'Aplikasi membutuhkan akses sensor aktivitas untuk menghitung langkah Anda. '
           'Data ini membantu memberikan informasi yang akurat tentang aktivitas fisik Anda.';
  }

  String getSensorsPermissionRationale() {
    return 'Aplikasi membutuhkan akses sensor untuk mendeteksi gerakan dan aktivitas fisik Anda. '
           'Data sensor hanya digunakan untuk tracking kebugaran dan tidak disimpan secara permanen.';
  }

  String getNotificationPermissionRationale() {
    return 'Aplikasi membutuhkan izin notifikasi untuk mengirimkan pengingat makan, '
           'olahraga, dan pencapaian target harian Anda.';
  }

  String getFCMPermissionRationale() {
    return 'Aplikasi membutuhkan izin Firebase Cloud Messaging untuk mengirimkan '
           'notifikasi personal berdasarkan progress diet dan aktivitas Anda.';
  }

  Future<Map<String, dynamic>> getPermissionsSummary() async {
    final locationStatus = await checkLocationPermission();
    final activityStatus = await checkActivityPermission();
    final sensorsStatus = await checkSensorsPermission();
    final notificationStatus = await checkNotificationPermission();
    final fcmStatus = await checkFCMPermission();
    final scheduleStatus = await checkScheduleExactAlarmPermission();

    return {
      'location': {
        'status': locationStatus,
        'statusText': getPermissionStatusText(locationStatus),
        'isGranted': locationStatus == permission_handler.PermissionStatus.granted,
        'rationale': getLocationPermissionRationale(),
      },
      'activity': {
        'status': activityStatus,
        'statusText': getPermissionStatusText(activityStatus),
        'isGranted': activityStatus == permission_handler.PermissionStatus.granted,
        'rationale': getActivityPermissionRationale(),
      },
      'sensors': {
        'status': sensorsStatus,
        'statusText': getPermissionStatusText(sensorsStatus),
        'isGranted': sensorsStatus == permission_handler.PermissionStatus.granted,
        'rationale': getSensorsPermissionRationale(),
      },
      'notification': {
        'status': notificationStatus,
        'statusText': getPermissionStatusText(notificationStatus),
        'isGranted': notificationStatus == permission_handler.PermissionStatus.granted,
        'rationale': getNotificationPermissionRationale(),
      },
      'fcm': {
        'status': fcmStatus,
        'statusText': getFCMStatusText(fcmStatus),
        'isGranted': fcmStatus == AuthorizationStatus.authorized || fcmStatus == AuthorizationStatus.provisional,
        'rationale': getFCMPermissionRationale(),
      },
      'scheduleAlarm': {
        'status': scheduleStatus,
        'statusText': getPermissionStatusText(scheduleStatus),
        'isGranted': scheduleStatus == permission_handler.PermissionStatus.granted,
        'rationale': 'Izin untuk menjadwalkan alarm notifikasi yang tepat waktu',
      },
    };
  }

  Future<bool> isAllEssentialPermissionsGranted() async {
    final locationStatus = await checkLocationPermission();
    final activityStatus = await checkActivityPermission();

    return locationStatus == permission_handler.PermissionStatus.granted &&
           activityStatus == permission_handler.PermissionStatus.granted;
  }

  Future<bool> isAllNotificationPermissionsGranted() async {
    final notificationStatus = await checkNotificationPermission();
    final fcmStatus = await checkFCMPermission();

    return notificationStatus == permission_handler.PermissionStatus.granted &&
           (fcmStatus == AuthorizationStatus.authorized || fcmStatus == AuthorizationStatus.provisional);
  }

  Future<List<permission_handler.Permission>> getMissingPermissions() async {
    final missing = <permission_handler.Permission>[];

    if (await checkLocationPermission() != permission_handler.PermissionStatus.granted) {
      missing.add(permission_handler.Permission.location);
    }

    if (await checkActivityPermission() != permission_handler.PermissionStatus.granted) {
      missing.add(permission_handler.Permission.activityRecognition);
    }

    if (await checkSensorsPermission() != permission_handler.PermissionStatus.granted) {
      missing.add(permission_handler.Permission.sensors);
    }

    if (await checkNotificationPermission() != permission_handler.PermissionStatus.granted) {
      missing.add(permission_handler.Permission.notification);
    }

    return missing;
  }

  String getPermissionName(permission_handler.Permission permission) {
    switch (permission) {
      case permission_handler.Permission.location:
        return 'Lokasi';
      case permission_handler.Permission.activityRecognition:
        return 'Aktivitas Fisik';
      case permission_handler.Permission.sensors:
        return 'Sensor';
      case permission_handler.Permission.notification:
        return 'Notifikasi';
      case permission_handler.Permission.scheduleExactAlarm:
        return 'Jadwal Alarm';
      default:
        return 'Tidak Diketahui';
    }
  }

  Future<Map<String, bool>> getNotificationPermissionsStatus() async {
    final notificationGranted = await checkNotificationPermission() == permission_handler.PermissionStatus.granted;
    final fcmStatus = await checkFCMPermission();
    final fcmGranted = fcmStatus == AuthorizationStatus.authorized || fcmStatus == AuthorizationStatus.provisional;
    final scheduleGranted = await checkScheduleExactAlarmPermission() == permission_handler.PermissionStatus.granted;

    return {
      'notification': notificationGranted,
      'fcm': fcmGranted,
      'schedule': scheduleGranted,
      'allGranted': notificationGranted && fcmGranted && scheduleGranted,
    };
  }
}