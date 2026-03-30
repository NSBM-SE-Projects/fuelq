import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, completed, expired, cancelled }

class BookingModel {
  final String bookingId;
  final String userId;
  final String vehicleNumber;
  final String vehicleId;
  final String stationId;
  final String stationName;
  final String fuelType;
  final double litresBooked;
  final String slotDate;
  final String slotTime;
  final String qrCode;
  final bool qrUsed;
  final String? scannedBy;
  final DateTime? scannedAt;
  final BookingStatus status;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.vehicleNumber,
    required this.vehicleId,
    required this.stationId,
    required this.stationName,
    required this.fuelType,
    required this.litresBooked,
    required this.slotDate,
    required this.slotTime,
    required this.qrCode,
    this.qrUsed = false,
    this.scannedBy,
    this.scannedAt,
    this.status = BookingStatus.confirmed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleNumber': vehicleNumber,
      'vehicleId': vehicleId,
      'stationId': stationId,
      'stationName': stationName,
      'fuelType': fuelType,
      'litresBooked': litresBooked,
      'slotDate': slotDate,
      'slotTime': slotTime,
      'qrCode': qrCode,
      'qrUsed': qrUsed,
      'scannedBy': scannedBy,
      'scannedAt': scannedAt != null ? Timestamp.fromDate(scannedAt!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      bookingId: id,
      userId: map['userId'] as String,
      vehicleNumber: map['vehicleNumber'] as String,
      vehicleId: map['vehicleId'] as String? ?? '',
      stationId: map['stationId'] as String,
      stationName: map['stationName'] as String,
      fuelType: map['fuelType'] as String,
      litresBooked: (map['litresBooked'] as num).toDouble(),
      slotDate: map['slotDate'] as String,
      slotTime: map['slotTime'] as String,
      qrCode: map['qrCode'] as String,
      qrUsed: map['qrUsed'] as bool? ?? false,
      scannedBy: map['scannedBy'] as String?,
      scannedAt: (map['scannedAt'] as Timestamp?)?.toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  static String generateQrPayload({
    required String bookingId,
    required String vehicleNumber,
    required double litres,
    required String fuelType,
    required String stationId,
    required String slotDate,
    required String slotTime,
    required String userId,
  }) {
    return jsonEncode({
      'bookingId': bookingId,
      'vehicleNumber': vehicleNumber,
      'litres': litres,
      'fuelType': fuelType,
      'stationId': stationId,
      'slotDate': slotDate,
      'slotTime': slotTime,
      'userId': userId,
    });
  }

  static Map<String, dynamic>? parseQrPayload(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data.containsKey('bookingId') && data.containsKey('vehicleNumber')) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
