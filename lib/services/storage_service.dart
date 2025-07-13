// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== PROFILE IMAGES ====================

  // Upload user profile picture - FIXED METHOD NAME
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      String fileName = 'profile_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      Reference ref = _storage
          .ref()
          .child('profile_pictures')
          .child(_currentUserId!)
          .child(fileName);

      // Upload file
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.path).substring(1)}',
          customMetadata: {
            'userId': _currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload profile picture: $e');
      }
      return null;
    }
  }

  // Delete old profile pictures
  Future<void> deleteOldProfilePictures() async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      Reference profileDir = _storage
          .ref()
          .child('profile_pictures')
          .child(_currentUserId!);

      ListResult result = await profileDir.listAll();

      // Delete all old profile pictures
      for (Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      // Ignore errors when deleting old files
      if (kDebugMode) {
        print('Error deleting old profile pictures: $e');
      }
    }
  }

  // ==================== FOOD IMAGES ====================

  // Upload food image
  Future<String> uploadFoodImage(File imageFile, {String? customName}) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      String fileName = customName ??
          'food_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      Reference ref = _storage
          .ref()
          .child('food_images')
          .child(_currentUserId!)
          .child(fileName);

      // Compress and upload
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.path).substring(1)}',
          customMetadata: {
            'userId': _currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'food_image',
          },
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload food image: $e';
    }
  }

  // Upload meal photo (for food diary) - FIXED DUPLICATE DEFINITION
  Future<String> uploadMealPhoto(File imageFile, String mealType, DateTime date) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String fileName = 'meal_${mealType}_${dateStr}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      Reference ref = _storage
          .ref()
          .child('meal_photos')
          .child(_currentUserId!)
          .child(dateStr)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.path).substring(1)}',
          customMetadata: {
            'userId': _currentUserId!,
            'mealType': mealType,
            'date': dateStr,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'meal_photo',
          },
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload meal photo: $e';
    }
  }

  // ==================== CUSTOM FOOD IMAGES ====================

  // Upload custom food image (for user-created foods)
  Future<String> uploadCustomFoodImage(File imageFile, String foodName) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      String sanitizedName = foodName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      String fileName = 'custom_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      Reference ref = _storage
          .ref()
          .child('custom_foods')
          .child(_currentUserId!)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.path).substring(1)}',
          customMetadata: {
            'userId': _currentUserId!,
            'foodName': foodName,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'custom_food',
          },
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload custom food image: $e';
    }
  }

  // ==================== FILE MANAGEMENT ====================

  // Delete file by URL
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      // Don't throw error, as file might already be deleted
    }
  }

  // Delete user's meal photos for specific date
  Future<void> deleteMealPhotosForDate(DateTime date) async {
    try {
      if (_currentUserId == null) return;

      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      Reference dateDir = _storage
          .ref()
          .child('meal_photos')
          .child(_currentUserId!)
          .child(dateStr);

      ListResult result = await dateDir.listAll();

      for (Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting meal photos for date: $e');
      }
    }
  }

  // Get user's storage usage
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      int totalFiles = 0;
      int totalSize = 0;

      // Count profile pictures
      Reference profileDir = _storage.ref().child('profile_pictures').child(_currentUserId!);
      ListResult profileResult = await profileDir.listAll();
      totalFiles += profileResult.items.length;

      // Count food images
      Reference foodDir = _storage.ref().child('food_images').child(_currentUserId!);
      ListResult foodResult = await foodDir.listAll();
      totalFiles += foodResult.items.length;

      // Count meal photos
      Reference mealDir = _storage.ref().child('meal_photos').child(_currentUserId!);
      ListResult mealResult = await mealDir.listAll();
      totalFiles += mealResult.items.length;

      // Count custom food images
      Reference customDir = _storage.ref().child('custom_foods').child(_currentUserId!);
      ListResult customResult = await customDir.listAll();
      totalFiles += customResult.items.length;

      // Get metadata for size calculation (sample only, full calculation would be expensive)
      if (profileResult.items.isNotEmpty) {
        FullMetadata metadata = await profileResult.items.first.getMetadata();
        totalSize = metadata.size ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'estimatedSize': totalSize,
        'profilePictures': profileResult.items.length,
        'foodImages': foodResult.items.length,
        'mealPhotos': mealResult.items.length,
        'customFoodImages': customResult.items.length,
      };
    } catch (e) {
      throw 'Failed to get storage usage: $e';
    }
  }

  // ==================== UTILITIES ====================

  // Check if file exists
  Future<bool> fileExists(String downloadUrl) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get file metadata
  Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      return null;
    }
  }

  // Clean up old files (call this periodically)
  Future<void> cleanupOldFiles({int daysOld = 30}) async {
    try {
      if (_currentUserId == null) return;

      DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // This is a basic cleanup - in production, you'd want more sophisticated cleanup
      // based on metadata timestamps and user preferences

      Reference userRoot = _storage.ref().child('temp').child(_currentUserId!);
      ListResult result = await userRoot.listAll();

      for (Reference ref in result.items) {
        try {
          FullMetadata metadata = await ref.getMetadata();
          if (metadata.timeCreated != null &&
              metadata.timeCreated!.isBefore(cutoffDate)) {
            await ref.delete();
          }
        } catch (e) {
          // Continue with next file if error
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup: $e');
      }
    }
  }

  // ==================== PROGRESS TRACKING ====================

  // Upload with progress tracking
  Future<String> uploadWithProgress(
      File file,
      String path,
      Function(double)? onProgress,
      ) async {
    try {
      if (_currentUserId == null) throw 'User not authenticated';

      Reference ref = _storage.ref().child(path);

      UploadTask uploadTask = ref.putFile(file);

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred.toDouble() /
              snapshot.totalBytes.toDouble();
          onProgress(progress);
        });
      }

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  // Batch delete files
  Future<void> batchDeleteFiles(List<String> downloadUrls) async {
    try {
      List<Future<void>> deleteTasks = downloadUrls.map((url) async {
        try {
          Reference ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Continue with other files if one fails
          if (kDebugMode) {
            print('Error deleting file $url: $e');
          }
        }
      }).toList();

      await Future.wait(deleteTasks);
    } catch (e) {
      if (kDebugMode) {
        print('Error in batch delete: $e');
      }
    }
  }
}