import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Starts the OTP flow for a full E.164 phone number (e.g. +919999999999).
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(UserCredential credential) onAutoVerified,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await _auth.signInWithCredential(credential);
        onAutoVerified(userCred);
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op: user can still enter the code manually.
      },
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Future<void> createUserProfile({
    required String uid,
    required String phone,
    required String name,
    required UserRole role,
  }) async {
    final model = UserModel(uid: uid, phone: phone, name: name, role: role);
    await _firestore.collection('users').doc(uid).set(model.toMap());
  }

  /// Validates a teacher signup code against config/roles.teacherAccessCode.
  Future<bool> validateTeacherCode(String enteredCode) async {
    final doc = await _firestore.collection('config').doc('roles').get();
    if (!doc.exists) return false;
    final storedCode = doc.data()?['teacherAccessCode'] as String?;
    return storedCode != null && storedCode == enteredCode;
  }

  Future<void> signOut() => _auth.signOut();
}