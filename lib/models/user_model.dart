import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, classrep, teacher }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.classrep:
        return 'classrep';
      case UserRole.teacher:
        return 'teacher';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.classrep:
        return 'Class Representative';
      case UserRole.teacher:
        return 'Teacher / Admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'classrep':
        return UserRole.classrep;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final UserRole role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      phone: data['phone'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRoleX.fromString(data['role'] as String? ?? 'student'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'role': role.value,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}