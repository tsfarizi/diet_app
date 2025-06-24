// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up with Email & Password
  Future<UserCredential?> signUp({
  required String email,
  required String password,
  required String name,
  required int age,
  required double weight,
  required double height,
  required String gender,
  required String activityLevel,
  required String goal,
}) async {
  try {
    print('🔵 DEBUG: Starting signup process...');
    print('🔵 Email: $email');
    print('🔵 Password length: ${password.length}');
    
    // Create user account
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    print('✅ Firebase Auth Success! UID: ${result.user!.uid}');

    // Update display name
    await result.user!.updateDisplayName(name);
    print('✅ Display name updated');

    // Create user profile in Firestore
    UserModel userModel = UserModel(
      id: result.user!.uid,
      email: email,
      name: name,
      age: age,
      weight: weight,
      height: height,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      targetWeight: weight,
      dailyCalorieTarget: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('🔵 Creating Firestore document...');
    await _firestore
        .collection('users')
        .doc(result.user!.uid)
        .set(userModel.toFirestore());
    
    print('✅ Firestore document created successfully!');

    return result;
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException caught!');
    print('❌ Error code: ${e.code}');
    print('❌ Error message: ${e.message}');
    throw _handleAuthException(e);
  } catch (e) {
    print('❌ General exception caught!');
    print('❌ Error type: ${e.runtimeType}');
    print('❌ Error: $e');
    throw 'An unexpected error occurred: $e';
  }
}

  // Sign In with Email & Password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 DEBUG: Starting signin process...');
      print('🔵 Email: $email');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful! UID: ${result.user!.uid}');
      return result;
      
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException caught!');
      print('❌ Error code: ${e.code}');
      print('❌ Error message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ General exception caught!');
      print('❌ Error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile.';
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      if (currentUser == null) throw 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw 'Failed to update profile.';
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) throw 'User not authenticated';

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      
      // Delete user account
      await currentUser!.delete();
    } catch (e) {
      throw 'Failed to delete account.';
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'requires-recent-login':
        return 'Please log out and log in again to perform this action.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Check if email is already registered - UPDATED TO USE verifyBeforeUpdateEmail
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Since fetchSignInMethodsForEmail is deprecated, we'll use a different approach
      // Try to create a temporary user and catch the specific error
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update email - UPDATED TO USE verifyBeforeUpdateEmail
  Future<void> updateEmail(String newEmail) async {
    try {
      if (currentUser == null) throw 'User not authenticated';
      
      // Use the new recommended method
      await currentUser!.verifyBeforeUpdateEmail(newEmail);
      
      // Update email in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'email': newEmail, 'updatedAt': DateTime.now()});
    } catch (e) {
      throw 'Failed to update email.';
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser == null) throw 'User not authenticated';
      
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw 'Failed to update password.';
    }
  }

  // Re-authenticate user (needed for sensitive operations)
  Future<void> reauthenticate(String password) async {
    try {
      if (currentUser == null) throw 'User not authenticated';
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw 'Re-authentication failed. Please check your password.';
    }
  }
}