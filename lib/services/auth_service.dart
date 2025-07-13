import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required double targetWeight,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user!.updateDisplayName(name);

      UserModel userModel = UserModel(
        id: result.user!.uid,
        email: email,
        name: name,
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        goal: 'lose_weight', // App fokus weight loss
        targetWeight: targetWeight,
        dailyCalorieTarget: 2000, // Legacy field, actual akan pakai calculatedCalorieTarget
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userModel.toFirestore());

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan tak terduga: $e';
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result;
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Login dibatalkan';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.additionalUserInfo?.isNewUser == true) {
        UserModel userModel = UserModel(
          id: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'User Google',
          age: 0, // Akan diisi di CompleteProfileScreen
          weight: 0.0, // Akan diisi di CompleteProfileScreen
          height: 0.0, // Akan diisi di CompleteProfileScreen
          gender: 'male', // Default, akan diubah di CompleteProfileScreen
          activityLevel: 'moderate', // Default reasonable
          goal: 'lose_weight', // App fokus weight loss
          targetWeight: 0.0, // Akan diisi di CompleteProfileScreen
          dailyCalorieTarget: 2000, // Legacy field
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toFirestore());
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal login dengan Google: $e';
    }
  }

  Future<UserCredential?> signUpWithGoogle() async {
    return await signInWithGoogle();
  }

  Future<bool> isProfileComplete() async {
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null) return false;
      
      return userProfile.isDataComplete; // Menggunakan method dari UserModel
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Gagal keluar. Silakan coba lagi.';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim email reset. Silakan coba lagi.';
    }
  }

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
      throw 'Gagal mendapatkan profil pengguna.';
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      if (currentUser == null) throw 'Pengguna tidak terautentikasi';

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw 'Gagal memperbarui profil.';
    }
  }

  Future<void> updateWeight(double newWeight) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) throw 'Profil tidak ditemukan';

      final updatedProfile = currentProfile.copyWith(
        weight: newWeight,
        updatedAt: DateTime.now(),
      );

      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw 'Gagal memperbarui berat badan: $e';
    }
  }

  Future<void> updateActivityLevel(String newActivityLevel) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) throw 'Profil tidak ditemukan';

      final updatedProfile = currentProfile.copyWith(
        activityLevel: newActivityLevel,
        updatedAt: DateTime.now(),
      );

      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw 'Gagal memperbarui tingkat aktivitas: $e';
    }
  }

  Future<void> updateTargetWeight(double newTargetWeight) async {
    try {
      final currentProfile = await getUserProfile();
      if (currentProfile == null) throw 'Profil tidak ditemukan';

      final updatedProfile = currentProfile.copyWith(
        targetWeight: newTargetWeight,
        updatedAt: DateTime.now(),
      );

      await updateUserProfile(updatedProfile);
    } catch (e) {
      throw 'Gagal memperbarui target berat: $e';
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) throw 'Pengguna tidak terautentikasi';

      await _firestore.collection('users').doc(currentUser!.uid).delete();
      
      await currentUser!.delete();
    } catch (e) {
      throw 'Gagal menghapus akun.';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Akun dengan email ini sudah ada.';
      case 'user-not-found':
        return 'Tidak ada pengguna dengan email ini.';
      case 'wrong-password':
        return 'Password yang dimasukkan salah.';
      case 'invalid-email':
        return 'Alamat email tidak valid.';
      case 'user-disabled':
        return 'Akun pengguna ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak permintaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Akun email/password tidak diaktifkan.';
      case 'requires-recent-login':
        return 'Silakan keluar dan masuk lagi untuk melakukan tindakan ini.';
      case 'account-exists-with-different-credential':
        return 'Email sudah terdaftar dengan metode login lain.';
      case 'invalid-credential':
        return 'Kredensial login tidak valid.';
      default:
        return 'Autentikasi gagal. Silakan coba lagi.';
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'temporary_password_check_123',
      );
      
      await _auth.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      if (currentUser == null) throw 'Pengguna tidak terautentikasi';
      
      await currentUser!.verifyBeforeUpdateEmail(newEmail);
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'email': newEmail, 'updatedAt': DateTime.now()});
    } catch (e) {
      throw 'Gagal memperbarui email.';
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser == null) throw 'Pengguna tidak terautentikasi';
      
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw 'Gagal memperbarui password.';
    }
  }

  Future<void> reauthenticate(String password) async {
    try {
      if (currentUser == null) throw 'Pengguna tidak terautentikasi';
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw 'Otentikasi ulang gagal. Silakan periksa password Anda.';
    }
  }
}