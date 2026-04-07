import 'package:cloud_firestore/cloud_firestore.dart';

class QuotaModel {
  final String vehicleId;
  final String vehicleNumber;
  final String nickname;
  final String fuelType;
  final double weeklyLimit;
  final double used;
  final DateTime weekStart;
  final DateTime weekEnd;

  QuotaModel({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.nickname,
    required this.fuelType,
    required this.weeklyLimit,
    required this.used,
    required this.weekStart,
    required this.weekEnd,
  });

  double get remaining => (weeklyLimit - used).clamp(0, weeklyLimit);
  double get usagePercent =>
      weeklyLimit > 0 ? (used / weeklyLimit).clamp(0, 1) : 0;
  bool get isExhausted => remaining <= 0;

  factory QuotaModel.fromMap(String vehicleId, Map<String, dynamic> map) {
    return QuotaModel(
      vehicleId: vehicleId,
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      fuelType: map['fuelType'] as String? ?? 'petrol',
      weeklyLimit:
          (map['weeklyLimit'] as num?)?.toDouble() ??
          _defaultLimit(map['fuelType'] as String? ?? 'petrol'),
      used: (map['used'] as num?)?.toDouble() ?? 0,
      weekStart:
          (map['weekStart'] as Timestamp?)?.toDate() ?? _currentWeekStart(),
      weekEnd: (map['weekEnd'] as Timestamp?)?.toDate() ?? _currentWeekEnd(),
    );
  }

  factory QuotaModel.fromVehicleDoc(String vehicleId, Map<String, dynamic> map) {
    final fuelType = map['fuelType'] as String? ?? 'petrol';
    return QuotaModel(
      vehicleId: vehicleId,
      vehicleNumber: map['vehicleNumber'] as String? ?? ' ',
      nickname: map['nickname'] as String? ?? ' ',
      fuelType: fuelType,
      weeklyLimit: (map['weeklyLimit'] as num?)?.toDouble() ?? _defaultLimit(fuelType),
      used: (map['used'] as num?)?.toDouble()  ?? 0,
      weekStart: (map['weekStart'] as Timestamp?)?.toDate() ?? _currentWeekStart(),
      weekEnd: (map['weekEnd'] as Timestamp?)?.toDate() ?? _currentWeekEnd(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleNumber': vehicleNumber,
      'nickname': nickname,
      'fuelType': fuelType,
      'weeklyLimit': weeklyLimit,
      'used': used,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
    };
  }

  static double _defaultLimit(String fuelType) {
    return fuelType == 'diesel' ? 32.0 : 16.0;
  }

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static DateTime _currentWeekEnd() {
    final now = DateTime.now();
    return now.add(Duration(days: 7 - now.weekday));
  }

  factory QuotaModel.defaultForVehicle({
    required String vehicleId,
    required String vehicleNumber,
    required String nickname,
    required String fuelType,
  }) {
    return QuotaModel(
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      nickname: nickname,
      fuelType: fuelType,
      weeklyLimit: _defaultLimit(fuelType),
      used: 0,
      weekStart: _currentWeekStart(),
      weekEnd: _currentWeekEnd(),
    );
  }
}
