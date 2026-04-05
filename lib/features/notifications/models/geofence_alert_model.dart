class GeofenceAlertModel {
  final String bookingId;
  final String vehicleNumber;
  final String ownerName;
  final String fuelType;
  final double litres;
  final DateTime triggeredAt;
  final double distanceMetres;

  const GeofenceAlertModel({
    required this.bookingId,
    required this.vehicleNumber,
    required this.ownerName,
    required this.fuelType,
    required this.litres,
    required this.triggeredAt,
    required this.distanceMetres,
  });

  factory GeofenceAlertModel.fromMap(Map<String, dynamic> map) {
    return GeofenceAlertModel(
      bookingId: map['bookingId'] as String,
      vehicleNumber: map['vehicleNumber'] as String,
      ownerName: map['ownerName'] as String,
      fuelType: map['fuelType'] as String,
      litres: (map['litres'] as num).toDouble(),
      triggeredAt: DateTime.parse(map['triggeredAt'] as String),
      distanceMetres: (map['distanceMetres'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'vehicleNumber': vehicleNumber,
        'ownerName': ownerName,
        'fuelType': fuelType,
        'litres': litres,
        'triggeredAt': triggeredAt.toIso8601String(),
        'distanceMetres': distanceMetres,
      };
}
