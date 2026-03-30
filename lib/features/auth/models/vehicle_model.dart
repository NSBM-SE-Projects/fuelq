import 'package:cloud_firestore/cloud_firestore.dart';

enum FuelType {
  petrol,
  diesel,
}

class VehicleModel {
  final String id;
  final String vehicleNumber;
  final String chassisNumber;
  final FuelType fuelType;
  final String nickname;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.vehicleNumber,
    required this.chassisNumber,
    required this.fuelType,
    this.nickname = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleNumber': vehicleNumber,
      'chassisNumber': chassisNumber,
      'fuelType': fuelType.name,
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VehicleModel.fromMap(String id, Map<String, dynamic> map) {
    return VehicleModel(
      id: id,
      vehicleNumber: map['vehicleNumber'] as String,
      chassisNumber: map['chassisNumber'] as String,
      fuelType: FuelType.values.firstWhere(
        (e) => e.name == map['fuelType'],
        orElse: () => FuelType.petrol,
      ),
      nickname: map['nickname'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
