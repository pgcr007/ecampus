// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Admin-only user management operations, used only from ManageUsersScreen
/// (which is itself gated behind RoleUtils.isTeacher in the drawer).
/// The real enforcement layer is the Firestore security rules — see the
/// "Manage Users" rule block added to firestore.rules.
class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  /// Changes another user's role. Firestore rules only allow this write
  /// when the caller's own profile has role == 'teacher'.
  Future<void> updateRole({
    required String uid,
    required UserRole newRole,
  }) {
    return _users.doc(uid).update({'role': newRole.value});
  }

  /// Removes a user's Firestore profile document. This does NOT delete
  /// their Firebase Auth account — deleting another user's Auth account
  /// requires the Admin SDK (a Cloud Function), which isn't available
  /// from a client-only app. What this does instead: it clears their
  /// app profile, so if they ever sign in again, AuthGate routes them
  /// back to CompleteProfileScreen instead of straight into the app.
  Future<void> removeUserProfile(String uid) {
    return _users.doc(uid).delete();
  }
}