import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';
import '../models/geofence_alert_model.dart';
import '../services/notification_service.dart';

final notificationsEnabledProvider = StateProvider<bool>((_) => true);
final geofenceRadiusProvider = StateProvider<double>((_) => 100.0);
final geofenceHistoryProvider = StateProvider<List<GeofenceAlertModel>>((_) => []);
final highlightedVehicleProvider = StateProvider<String?>((_) => null);

final customerLocationBroadcaster = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;

  final sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
  ).listen((pos) async {
    final snap = await ref.read(firestoreProvider)
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: BookingStatus.upcoming.name)
        .orderBy('slotStart')
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      snap.docs.first.reference.update({
        'ownerLat': pos.latitude,
        'ownerLng': pos.longitude,
      });
    }
  });

  ref.onDispose(sub.cancel);
});

final geofenceMonitorProvider = Provider.autoDispose<void>((ref) {
  final enabled = ref.watch(notificationsEnabledProvider);
  if (!enabled) return;

  final radius = ref.watch(geofenceRadiusProvider);
  final user = ref.watch(userProvider).valueOrNull;
  if (user == null || user.stationId == null) return;

  NotificationService.instance.init();

  ref.read(firestoreProvider)
      .collection('stations')
      .doc(user.stationId)
      .get()
      .then((stationDoc) {
    if (!stationDoc.exists) return;
    final geoPoint = stationDoc.data()?['location'] as GeoPoint?;
    if (geoPoint == null) return;

    final stationLat = geoPoint.latitude;
    final stationLng = geoPoint.longitude;

    final sub = ref.read(firestoreProvider)
        .collection('bookings')
        .where('stationId', isEqualTo: user.stationId)
        .where('status', isEqualTo: BookingStatus.upcoming.name)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final ownerLat = (data['ownerLat'] as num?)?.toDouble();
        final ownerLng = (data['ownerLng'] as num?)?.toDouble();
        if (ownerLat == null || ownerLng == null) continue;

        final distance = Geolocator.distanceBetween(ownerLat, ownerLng, stationLat, stationLng);
        if (distance <= radius) {
          final booking = BookingModel.fromMap(doc.id, data);
          _onVehicleNearby(ref, booking, distance);
        }
      }
    });

    ref.onDispose(sub.cancel);
  });
});

void _onVehicleNearby(Ref ref, BookingModel booking, double distance) {
  final history = List<GeofenceAlertModel>.from(ref.read(geofenceHistoryProvider));
  if (history.any((a) => a.vehicleNumber == booking.vehicleNumber)) return;

  final alert = GeofenceAlertModel(
    bookingId: booking.id,
    vehicleNumber: booking.vehicleNumber,
    ownerName: '',
    fuelType: booking.fuelType,
    litres: 0,
    triggeredAt: DateTime.now(),
    distanceMetres: distance,
  );

  history.insert(0, alert);
  if (history.length > 20) history.removeLast();
  ref.read(geofenceHistoryProvider.notifier).state = history;
  ref.read(highlightedVehicleProvider.notifier).state = booking.vehicleNumber;

  if (ref.read(notificationsEnabledProvider)) {
    NotificationService.instance.showVehicleNearbyNotification(
      vehicleNumber: booking.vehicleNumber,
      ownerName: '',
      distanceMetres: distance,
    );
  }
}
