import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking_model.dart';

final activeBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final all = snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
            .toList();
        final active = all
            .where((b) => b.status == BookingStatus.confirmed)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return active;
      });
});

final pastBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final all = snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
            .toList();
        final past = all
            .where((b) =>
                b.status == BookingStatus.completed ||
                b.status == BookingStatus.expired ||
                b.status == BookingStatus.cancelled)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return past.take(20).toList();
      });
});

class QrService {
  final FirebaseFirestore _firestore;

  QrService(this._firestore);

  Future<BookingModel> createBooking({
    required String userId,
    required String vehicleNumber,
    required String vehicleId,
    required String stationId,
    required String stationName,
    required String fuelType,
    required double litresBooked,
    required String slotDate,
    required String slotTime,
  }) async {
    final docRef = _firestore.collection('bookings').doc();

    final qrPayload = BookingModel.generateQrPayload(
      bookingId: docRef.id,
      vehicleNumber: vehicleNumber,
      litres: litresBooked,
      fuelType: fuelType,
      stationId: stationId,
      slotDate: slotDate,
      slotTime: slotTime,
      userId: userId,
    );

    final booking = BookingModel(
      bookingId: docRef.id,
      userId: userId,
      vehicleNumber: vehicleNumber,
      vehicleId: vehicleId,
      stationId: stationId,
      stationName: stationName,
      fuelType: fuelType,
      litresBooked: litresBooked,
      slotDate: slotDate,
      slotTime: slotTime,
      qrCode: qrPayload,
      createdAt: DateTime.now(),
    );

    await docRef.set(booking.toMap());
    return booking;
  }

  Future<BookingModel> scanAndValidate({
    required String qrPayload,
    required String attendantUid,
    required String attendantStationId,
  }) async {
    final data = BookingModel.parseQrPayload(qrPayload);
    if (data == null) {
      throw Exception('Invalid QR code format');
    }

    final bookingId = data['bookingId'] as String;
    final docRef = _firestore.collection('bookings').doc(bookingId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = BookingModel.fromMap(doc.id, doc.data()!);

    if (booking.qrUsed) {
      throw Exception('This QR code has already been used');
    }
    if (booking.status != BookingStatus.confirmed) {
      throw Exception('Booking is ${booking.status.name}');
    }
    if (booking.stationId != attendantStationId) {
      throw Exception('This booking is for a different station');
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (booking.slotDate != todayStr) {
      throw Exception('This booking is for ${booking.slotDate}, not today');
    }

    await docRef.update({
      'qrUsed': true,
      'scannedBy': attendantUid,
      'scannedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    return booking;
  }
}

final qrServiceProvider = Provider((ref) {
  return QrService(ref.watch(firestoreProvider));
});
