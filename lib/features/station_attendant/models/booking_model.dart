import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, arrived, completed, noShow }

class BookingModel {
  final String id;
  final String vehicleNumber;
  final String ownerName;
  final String fuelType;
  final double litres;
  final DateTime slotTime;
  final BookingStatus status;
  final bool isPrepaid;
  final String stationId;

  const BookingModel({
    required this.id,
    required this.vehicleNumber,
    required this.ownerName,
    required this.fuelType,
    required this.litres,
    required this.slotTime,
    required this.status,
    required this.isPrepaid,
    required this.stationId,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      fuelType: data['fuelType'] as String? ?? 'Petrol',
      litres: (data['litres'] as num?)?.toDouble() ?? 0.0,
      slotTime: (data['slotTime'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] as String?),
      isPrepaid: data['isPrepaid'] as bool? ?? false,
      stationId: data['stationId'] as String? ?? '',
    );
  }

  BookingModel copyWith({BookingStatus? status}) => BookingModel(
        id: id,
        vehicleNumber: vehicleNumber,
        ownerName: ownerName,
        fuelType: fuelType,
        litres: litres,
        slotTime: slotTime,
        status: status ?? this.status,
        isPrepaid: isPrepaid,
        stationId: stationId,
      );

  Map<String, dynamic> toFirestore() => {
        'vehicleNumber': vehicleNumber,
        'ownerName': ownerName,
        'fuelType': fuelType,
        'litres': litres,
        'slotTime': Timestamp.fromDate(slotTime),
        'status': status.name,
        'isPrepaid': isPrepaid,
        'stationId': stationId,
      };

  static BookingStatus _statusFromString(String? s) => switch (s) {
        'arrived' => BookingStatus.arrived,
        'completed' => BookingStatus.completed,
        'noShow' => BookingStatus.noShow,
        _ => BookingStatus.confirmed,
      };

  static List<BookingModel> get sampleData {
    final today = DateTime.now();
    DateTime d(int h) => DateTime(today.year, today.month, today.day, h);
    return [
      BookingModel(id: 'b1', vehicleNumber: 'CAB-1234', ownerName: 'Ashen Perera', fuelType: 'Petrol', litres: 14.0, slotTime: d(8), status: BookingStatus.completed, isPrepaid: true, stationId: 'station_01'),
      BookingModel(id: 'b2', vehicleNumber: 'ABC-5678', ownerName: 'Nuwan Silva', fuelType: 'Petrol', litres: 8.0, slotTime: d(8), status: BookingStatus.arrived, isPrepaid: false, stationId: 'station_01'),
      BookingModel(id: 'b3', vehicleNumber: 'XYZ-9012', ownerName: 'Kamal Dias', fuelType: 'Diesel', litres: 20.0, slotTime: d(8), status: BookingStatus.confirmed, isPrepaid: true, stationId: 'station_01'),
      BookingModel(id: 'b4', vehicleNumber: 'WP-CAR-456', ownerName: 'Saman Fernando', fuelType: 'Petrol', litres: 10.0, slotTime: d(9), status: BookingStatus.confirmed, isPrepaid: true, stationId: 'station_01'),
      BookingModel(id: 'b5', vehicleNumber: 'NB-2345', ownerName: 'Priya Rathnayake', fuelType: 'Diesel', litres: 15.0, slotTime: d(9), status: BookingStatus.noShow, isPrepaid: false, stationId: 'station_01'),
      BookingModel(id: 'b6', vehicleNumber: 'KL-7890', ownerName: 'Chamara Wickrama', fuelType: 'Petrol', litres: 12.0, slotTime: d(10), status: BookingStatus.confirmed, isPrepaid: true, stationId: 'station_01'),
      BookingModel(id: 'b7', vehicleNumber: 'PQ-3456', ownerName: 'Dilshan Gunawardena', fuelType: 'Petrol', litres: 18.0, slotTime: d(10), status: BookingStatus.confirmed, isPrepaid: false, stationId: 'station_01'),
      BookingModel(id: 'b8', vehicleNumber: 'SG-0011', ownerName: 'Tharushi Mendis', fuelType: 'Diesel', litres: 25.0, slotTime: d(11), status: BookingStatus.confirmed, isPrepaid: true, stationId: 'station_01'),
    ];
  }
}
