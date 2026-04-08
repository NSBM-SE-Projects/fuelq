import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { upcoming, completed, cancelled, expired, noShow }

class BookingConfig {
  final int slotDurationMinutes;
  final int maxVehiclesPerSlot;
  final int cancelWindowMinutes;
  final int arrivalWindowMinutes;
  final int maxBookingsPerVehiclePerDay;

  const BookingConfig({
    required this.slotDurationMinutes,
    required this.maxVehiclesPerSlot,
    required this.cancelWindowMinutes,
    required this.arrivalWindowMinutes,
    required this.maxBookingsPerVehiclePerDay,
  });

  Duration get slotDuration => Duration(minutes: slotDurationMinutes);
  Duration get cancelWindow => Duration(minutes: cancelWindowMinutes);
  Duration get arrivalWindow => Duration(minutes: arrivalWindowMinutes);

  factory BookingConfig.fromMap(Map<String, dynamic> map) {
    return BookingConfig(
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      maxVehiclesPerSlot: (map['maxVehiclesPerSlot'] as num?)?.toInt() ?? 15,
      cancelWindowMinutes: (map['cancelWindowMinutes'] as num?)?.toInt() ?? 30,
      arrivalWindowMinutes: (map['arrivalWindowMinutes'] as num?)?.toInt() ?? 15,
      maxBookingsPerVehiclePerDay: (map['maxBookingsPerVehiclePerDay'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'slotDurationMinutes': slotDurationMinutes,
    'maxVehiclesPerSlot': maxVehiclesPerSlot,
    'cancelWindowMinutes': cancelWindowMinutes,
    'arrivalWindowMinutes': arrivalWindowMinutes,
    'maxBookingsPerVehiclePerDay': maxBookingsPerVehiclePerDay,
  };
}

class BookingModel {
  final String id;
  final String userId;
  final String stationId;
  final String stationName;
  final String vehicleId;
  final String vehicleNumber;
  final String fuelType;
  final DateTime slotStart;
  final BookingStatus status;
  final String qrToken;
  final bool qrUsed;
  final String? scannedBy;
  final DateTime? scannedAt;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.stationName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.fuelType,
    required this.slotStart,
    required this.status,
    required this.qrToken,
    this.qrUsed = false,
    this.scannedBy,
    this.scannedAt,
    required this.createdAt,
  });

  DateTime slotEnd(Duration slotDuration) => slotStart.add(slotDuration);

  String slotTimeLabel(Duration slotDuration) =>
    '${_formatTime(slotStart)} - ${_formatTime(slotEnd(slotDuration))}';

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      stationId: map['stationId'] as String? ?? '',
      stationName: map['stationName'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      fuelType: map['fuelType'] as String? ?? '',
      slotStart: (map['slotStart'] as Timestamp).toDate(),
      status: _parseStatus(map['status'] as String?),
      qrToken: map['qrToken'] as String? ?? '',
      qrUsed: map['qrUsed'] as bool? ?? false,
      scannedBy: map['scannedBy'] as String?,
      scannedAt: (map['scannedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'stationId': stationId,
    'stationName': stationName,
    'vehicleId': vehicleId,
    'vehicleNumber': vehicleNumber,
    'fuelType': fuelType,
    'slotStart': Timestamp.fromDate(slotStart),
    'status': status.name,
    'qrToken': qrToken,
    'qrUsed': qrUsed,
    'scannedBy': scannedBy,
    'scannedAt': scannedAt != null ? Timestamp.fromDate(scannedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  BookingModel copyWith({
    BookingStatus? status,
    bool? qrUsed,
    String? scannedBy,
    DateTime? scannedAt,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      stationId: stationId,
      stationName: stationName,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      fuelType: fuelType,
      slotStart: slotStart,
      status: status ?? this.status,
      qrToken: qrToken,
      qrUsed: qrUsed ?? this.qrUsed,
      scannedBy: scannedBy ?? this.scannedBy,  // ignore: unnecessary_this
      scannedAt: scannedAt ?? this.scannedAt,
      createdAt: createdAt,
    );
  }

  static BookingStatus _parseStatus(String? value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.upcoming,
    );
  }

  static String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
