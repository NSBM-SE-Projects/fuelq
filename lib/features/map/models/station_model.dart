import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum StationAvailability { available, busy, full, closed }

enum FuelType { petrol92, petrol95, diesel, superDiesel }

class StationModel {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final List<FuelType> fuelTypes;
  final StationAvailability availability;
  final int currentQueue;
  final int maxQueue;
  final String openTime;
  final String closeTime;
  final bool isOpen; 

const StationModel({
  required this.id,
  required this.name,
  required this.address,
  required this.location,
  required this.fuelTypes,
  required this.availability,
  required this.currentQueue,
  required this.maxQueue,
  required this.openTime,
  required this.closeTime,
  required this.isOpen,
});

factory StationModel.fromMap(String id, Map<String, dynamic> map) {
  final GeoPoint geoPoint = map ['location'] as GeoPoint;
  final rawFuelTypes = (map['fuelTypes'] as List<dynamic>?)
          ?.map((e) => _parseFuelType(e as String))
          .whereType<FuelType>()
          .toList() ??
      [];

    return StationModel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      fuelTypes: rawFuelTypes,
      availability: _parseAvailability(map['availabilty'] as String?),
      currentQueue: (map['currentQueue'] as num?)?.toInt() ?? 0,
      maxQueue: (map['maxQueue'] as num?)?.toInt() ?? 50,
      openTime: map['openTime'] as String? ?? '06:00',
      closeTime: map['closeTime'] as String? ?? '22:00',
      isOpen: map['isOpen'] as bool? ?? true,
    );
}

Map<String, dynamic> toMap() => {
  'name': name,
  'address': address,
  'location': GeoPoint(location.latitude, location.longitude),
  'fuelTypes': fuelTypes.map((e) => e.name).toList(),
  'availability': availability.name,
  'currentQueue': currentQueue,
  'maxQueue': maxQueue,
  'openTime': openTime,
  'closeTime': closeTime,
  'isOpen': isOpen,
};

static StationAvailability _parseAvailability(String? value) =>
  StationAvailability.values.firstWhere((e) => e.name == value,
  orElse: () => StationAvailability.available,
  );

static FuelType? _parseFuelType(String value) {
  try {
    return FuelType.values.firstWhere((e) => e.name == value);
  }
  catch (_) {
    return null;
  }
}

String get availabilityLabel {
  if (!isOpen) return 'Closed';
  switch (availability) {
    case StationAvailability.available: return 'Available';
    case StationAvailability.busy: return 'Busy';
    case StationAvailability.full: return 'Full';
    case StationAvailability.closed: return 'Closed';
  }
}

String get fuelTypesLabel => fuelTypes.map(fuelTypeLabel).join(' . ');

static String fuelTypeLabel(FuelType type) {
  switch (type) {
    case FuelType.petrol92: return 'Petrol 92';
    case FuelType.petrol95: return 'Petrol 95';
    case FuelType.diesel: return 'Diesel';
    case FuelType.superDiesel: return 'Super Diesel';
  }
}
}