import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';

// Today's bookings for the attendant's station
final stationBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userProvider).valueOrNull;
  if (user == null || user.stationId == null) return Stream.value([]);

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  return ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('stationId', isEqualTo: user.stationId)
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
      .where('slotStart', isLessThan: Timestamp.fromDate(dayEnd))
      .orderBy('slotStart')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList());
});

// Filter and search state
enum BookingFilter { all, completed, pending, noShow }

final bookingFilterProvider = StateProvider<BookingFilter>((_) => BookingFilter.all);
final bookingSearchProvider = StateProvider<String>((_) => '');

// Filtered + searched + grouped bookings
final groupedBookingsProvider = Provider<Map<String, List<BookingModel>>>((ref) {
  final filter = ref.watch(bookingFilterProvider);
  final search = ref.watch(bookingSearchProvider).trim().toLowerCase();
  final allBookings = ref.watch(stationBookingsProvider).valueOrNull ?? [];

  var bookings = switch (filter) {
    BookingFilter.all => allBookings,
    BookingFilter.completed =>
      allBookings.where((b) => b.status == BookingStatus.completed).toList(),
    BookingFilter.pending =>
      allBookings.where((b) => b.status == BookingStatus.upcoming).toList(),
    BookingFilter.noShow =>
      allBookings.where((b) => b.status == BookingStatus.noShow).toList(),
  };

  if (search.isNotEmpty) {
    bookings = bookings
        .where((b) => b.vehicleNumber.toLowerCase().contains(search))
        .toList();
  }

  final Map<String, List<BookingModel>> grouped = {};
  for (final b in bookings) {
    grouped.putIfAbsent(_slotLabel(b.slotStart), () => []).add(b);
  }
  return Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
});

// Stats for the dashboard
final bookingStatsProvider = Provider<({int total, int completed, int pending, int noShow})>((ref) {
  final bookings = ref.watch(stationBookingsProvider).valueOrNull ?? [];
  return (
    total: bookings.length,
    completed: bookings.where((b) => b.status == BookingStatus.completed).length,
    pending: bookings.where((b) => b.status == BookingStatus.upcoming).length,
    noShow: bookings.where((b) => b.status == BookingStatus.noShow).length,
  );
});

String _slotLabel(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final nextH = ((t.hour + 1) % 24).toString().padLeft(2, '0');
  return '$h:00 \u2013 $nextH:00';
}
