import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  vehicleOwner,
  stationAttendant,
  governmentAdmin,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String nic;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.nic,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'nic': nic,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      nic: map['nic'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.vehicleOwner,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
