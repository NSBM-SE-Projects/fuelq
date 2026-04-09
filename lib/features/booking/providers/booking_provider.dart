import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking_model.dart';

final bookingConfigProvider = FutureProvider<BookingConfig>((ref) async {
  final doc = await ref.watch(firestoreProvider).collection('config').doc('booking').get();
  if (!doc.exists) {
    return const BookingConfig(
      slotDurationMinutes: 30,
      maxVehiclesPerSlot: 15,
      cancelWindowMinutes: 30,
      arrivalWindowMinutes: 15,
      maxBookingsPerVehiclePerDay: 1,
      petrolPricePerLiter: 366.0,
      dieselPricePerLiter: 336.0,
    );
  }
  return BookingConfig.fromMap(doc.data()!);
});

final userBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
  .watch(firestoreProvider)
  .collection('bookings')
  .where('userId', isEqualTo: user.uid)
  .orderBy('slotStart', descending: true)
  .snapshots()
  .map((snap) => snap.docs
    .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
    .toList());
});

final slotCountsProvider = FutureProvider.family.autoDispose<Map<String, int>, ({String stationId, DateTime date})>(
  (ref,params) async {
    final dayStart = DateTime(params.date.year, params.date.month, params.date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snap = await ref
    .watch(firestoreProvider)
    .collection('bookings')
    .where('stationId', isEqualTo: params.stationId)
    .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
    .where('slotStart', isLessThan: Timestamp.fromDate(dayEnd))
    .where('status', isEqualTo: BookingStatus.upcoming.name)
    .get();

    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final slotStart = (doc['slotStart'] as Timestamp).toDate();
      final key = '${slotStart.hour.toString().padLeft(2, '0')}:${slotStart.minute.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  },
);

class BookingService {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  BookingService(this._firestore);

  Future<BookingModel> createBooking({
    required String userId,
    required String stationId,
    required String stationName,
    required String vehicleId,
    required String vehicleNumber,
    required String fuelType,
    required DateTime slotStart,
    required String paymentMethod,
    required String paymentStatus,
    required double amount,
    String? cardLast4,
  }) async {
    // Check if vehicle already has a booking this day
    final dayStart = DateTime(slotStart.year, slotStart.month, slotStart.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final existing = await _firestore
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('slotStart', isLessThan: Timestamp.fromDate(dayEnd))
        .where('status', isEqualTo: BookingStatus.upcoming.name)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('This vehicle already has a booking today');
    }

    final docRef = _firestore.collection('bookings').doc();
    final booking = BookingModel(
      id: docRef.id,
      userId: userId,
      stationId: stationId,
      stationName: stationName,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      fuelType: fuelType,
      slotStart: slotStart,
      status: BookingStatus.upcoming,
      qrToken: _uuid.v4(),
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      amount: amount,
      cardLast4: cardLast4,
    );
    await docRef.set(booking.toMap());
    return booking;
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
    });
  }

  Future<void> scanBooking({
    required String bookingId,
    required String attendantId,
    double litresDispensed = 0,
  }) async {
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    await _firestore.collection('bookings').doc(bookingId).update({
      'qrUsed': true,
      'scannedBy': attendantId,
      'scannedAt': Timestamp.fromDate(DateTime.now()),
      'status': BookingStatus.completed.name,
      'litresDispensed': litresDispensed,
    });

    if (litresDispensed > 0 && bookingDoc.exists) {
      final data = bookingDoc.data()!;
      final userId = data['userId'] as String;
      final vehicleId = data['vehicleId'] as String;
      final vehicleRef = _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId);
      final vehicleDoc = await vehicleRef.get();
      if (vehicleDoc.exists) {
        final currentUsed = (vehicleDoc.data()?['used'] as num?)?.toDouble() ?? 0;
        await vehicleRef.update({'used': currentUsed + litresDispensed});
      }
    }
  }

  Future<BookingModel?> findByQrToken(String qrToken) async {
    final snap = await _firestore
      .collection('bookings')
      .where('qrToken', isEqualTo: qrToken)
      .limit(1)
      .get();
    if (snap.docs.isEmpty) return null;
    return BookingModel.fromMap(snap.docs.first.id, snap.docs.first.data());
  }
}

final bookingServiceProvider = Provider((ref) {
  return BookingService(ref.watch(firestoreProvider));
});
