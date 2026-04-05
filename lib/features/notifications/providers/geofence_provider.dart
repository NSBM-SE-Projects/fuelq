import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/geofence_alert_model.dart';
import '../services/geofence_service.dart';
import '../services/notification_service.dart';
import '../../station_attendant/models/booking_model.dart';
import '../../station_attendant/providers/station_attendant_provider.dart';


final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final geofenceRadiusProvider = StateProvider<double>((ref) => 100.0);


final geofenceAlertsProvider =
    StateProvider<List<GeofenceAlertModel>>((ref) => []);


final geofenceHistoryProvider =
    StateProvider<List<GeofenceAlertModel>>((ref) => []);


final highlightedVehicleProvider = StateProvider<String?>((ref) => null);


final liveDistanceProvider = StreamProvider<double?>((ref) {
  return GeofenceService.instance.distanceStream;
});


final geofenceMonitorProvider = Provider<void>((ref) {
  final radius = ref.watch(geofenceRadiusProvider);
  final enabled = ref.watch(notificationsEnabledProvider);

  if (!enabled) {
    GeofenceService.instance.stopMonitoring();
    return;
  }

  GeofenceService.instance.startMonitoring(radius: radius);
  GeofenceService.instance.updateRadius(radius);

  GeofenceService.instance.onGeofenceEntered.listen((distance) async {
    if (!ref.read(notificationsEnabledProvider)) return;

    GeofenceAlertModel alert;
    if (useMockData) {
      alert = GeofenceAlertModel(
        bookingId: 'mock_booking',
        vehicleNumber: 'CAB-1234',
        ownerName: 'Ashen Perera',
        fuelType: 'Petrol',
        litres: 14.0,
        triggeredAt: DateTime.now(),
        distanceMetres: distance,
      );
    } else {
      // Look up the nearest confirmed/arrived booking as the arriving vehicle.
      final bookings = ref.read(todayBookingsProvider);
      final booking = bookings.firstWhere(
        (b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.arrived,
        orElse: () => bookings.first,
      );
      alert = GeofenceAlertModel(
        bookingId: booking.id,
        vehicleNumber: booking.vehicleNumber,
        ownerName: booking.ownerName,
        fuelType: booking.fuelType,
        litres: booking.litres,
        triggeredAt: DateTime.now(),
        distanceMetres: distance,
      );
      // Write to Firestore so the station attendant's device is notified.
      await FirebaseFirestore.instance.collection('geofence_alerts').add({
        ...alert.toMap(),
        'stationId': booking.stationId,
      });
    }

    _addAlert(ref, alert);
  });

  ref.onDispose(GeofenceService.instance.stopMonitoring);
});


void _addAlert(dynamic ref, GeofenceAlertModel alert) {
  final current = List<GeofenceAlertModel>.from(
      ref.read(geofenceAlertsProvider));
  if (!current.any((a) => a.vehicleNumber == alert.vehicleNumber)) {
    ref.read(geofenceAlertsProvider.notifier).state = [alert, ...current];
  }

  final history = List<GeofenceAlertModel>.from(
      ref.read(geofenceHistoryProvider))
    ..removeWhere((a) => a.vehicleNumber == alert.vehicleNumber);
  history.insert(0, alert);
  if (history.length > 20) history.removeLast();
  ref.read(geofenceHistoryProvider.notifier).state = history;

  ref.read(highlightedVehicleProvider.notifier).state = alert.vehicleNumber;

  if (ref.read(notificationsEnabledProvider)) {
    NotificationService.instance.showVehicleNearbyNotification(
      vehicleNumber: alert.vehicleNumber,
      ownerName: alert.ownerName,
      distanceMetres: alert.distanceMetres,
    );
  }
}

void dismissAlert(WidgetRef ref, String vehicleNumber) {
  final current = List<GeofenceAlertModel>.from(
      ref.read(geofenceAlertsProvider));
  ref.read(geofenceAlertsProvider.notifier).state =
      current.where((a) => a.vehicleNumber != vehicleNumber).toList();

  if (ref.read(highlightedVehicleProvider) == vehicleNumber) {
    ref.read(highlightedVehicleProvider.notifier).state = null;
  }
}

void dismissAllAlerts(WidgetRef ref) {
  ref.read(geofenceAlertsProvider.notifier).state = [];
  ref.read(highlightedVehicleProvider.notifier).state = null;
}

final firestoreAlertsWatcherProvider = Provider.autoDispose<void>((ref) {
  if (useMockData) return;

  final startOfDay =
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

  final sub = FirebaseFirestore.instance
      .collection('geofence_alerts')
      .where('stationId', isEqualTo: kStationId)
      .where('triggeredAt',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String())
      .snapshots()
      .listen((snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      if (!ref.read(notificationsEnabledProvider)) continue;
      final alert = GeofenceAlertModel.fromMap(change.doc.data()!);
      _addAlert(ref, alert);
    }
  });

  ref.onDispose(sub.cancel);
});

final _mockVehicles = [
  ('CAB-1234', 'Ashen Perera', 'Petrol', 14.0, 'mock_b1'),
  ('ABC-5678', 'Nuwan Silva', 'Petrol', 8.0, 'mock_b2'),
  ('XYZ-9012', 'Kamal Dias', 'Diesel', 20.0, 'mock_b3'),
];
void simulateVehicleArrival(WidgetRef ref) {
  for (int i = 0; i < _mockVehicles.length; i++) {
    final v = _mockVehicles[i];
    final alert = GeofenceAlertModel(
      bookingId: v.$5,
      vehicleNumber: v.$1,
      ownerName: v.$2,
      fuelType: v.$3,
      litres: v.$4,
      triggeredAt: DateTime.now(),
      distanceMetres: 45.0 + (i * 15.0),
    );
    _addAlert(ref, alert);
  }
}
