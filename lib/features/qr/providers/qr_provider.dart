import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';

// Active (upcoming) bookings for the current user — used on QR display screen
final activeBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('userId', isEqualTo: user.uid)
      .where('status', isEqualTo: BookingStatus.upcoming.name)
      .orderBy('slotStart')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList());
});

class QrService {
  final FirebaseFirestore _firestore;

  QrService(this._firestore);

  // Generate a QR payload string from a booking
  static String generatePayload(BookingModel booking) {
    return jsonEncode({
      'bookingId': booking.id,
      'vehicleNumber': booking.vehicleNumber,
      'stationId': booking.stationId,
      'qrToken': booking.qrToken,
    });
  }

  // Parse a QR payload string — returns null if invalid
  static Map<String, dynamic>? parsePayload(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!data.containsKey('bookingId') || !data.containsKey('qrToken')) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  // Validate a QR code without marking it used — for showing confirmation before completing
  Future<BookingModel> validate({
    required String qrPayload,
    required String attendantStationId,
  }) async {
    final data = parsePayload(qrPayload);
    if (data == null) throw Exception('Invalid QR code format');

    final bookingId = data['bookingId'] as String;
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');

    final booking = BookingModel.fromMap(doc.id, doc.data()!);

    if (booking.qrUsed) throw Exception('This QR code has already been used');
    if (booking.status != BookingStatus.upcoming) {
      throw Exception('Booking is ${booking.status.name}');
    }
    if (booking.stationId != attendantStationId) {
      throw Exception('This booking is for a different station');
    }
    if (booking.qrToken != data['qrToken']) {
      throw Exception('Invalid QR token');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(booking.slotStart.year, booking.slotStart.month, booking.slotStart.day);
    if (bookingDay != today) {
      throw Exception('This booking is not for today');
    }

    final configDoc = await _firestore.collection('config').doc('booking').get();
    final arrivalMins = (configDoc.data()?['arrivalWindowMinutes'] as num?)?.toInt() ?? 15;
    final slotMins = (configDoc.data()?['slotDurationMinutes'] as num?)?.toInt() ?? 30;
    final windowStart = booking.slotStart.subtract(Duration(minutes: arrivalMins));
    final windowEnd = booking.slotStart.add(Duration(minutes: slotMins + arrivalMins));

    if (now.isBefore(windowStart)) {
      throw Exception('Too early — this slot starts at ${booking.slotStart.hour.toString().padLeft(2, '0')}:${booking.slotStart.minute.toString().padLeft(2, '0')}');
    }
    if (now.isAfter(windowEnd)) {
      throw Exception('This time slot has expired');
    }

    return booking;
  }

  // Validate and complete — scans the booking, marks QR used, updates status
  Future<BookingModel> scanAndComplete({
    required String qrPayload,
    required String attendantUid,
    required String attendantStationId,
  }) async {
    final booking = await validate(
      qrPayload: qrPayload,
      attendantStationId: attendantStationId,
    );

    await _firestore.collection('bookings').doc(booking.id).update({
      'qrUsed': true,
      'scannedBy': attendantUid,
      'scannedAt': Timestamp.fromDate(DateTime.now()),
      'status': BookingStatus.completed.name,
    });

    return booking;
  }
}

final qrServiceProvider = Provider((ref) {
  return QrService(ref.watch(firestoreProvider));
});
