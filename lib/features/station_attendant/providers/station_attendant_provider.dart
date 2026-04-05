import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

const bool useMockData = true;
const String kStationId = 'station_01';

class BookingsNotifier extends StateNotifier<List<BookingModel>> {
  BookingsNotifier() : super(BookingModel.sampleData) {
    _loadPersistedStatuses();
  }

  static const _prefsKey = 'mock_booking_statuses';

  Future<void> _loadPersistedStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved == null) return;
    // Format: "id:statusName"
    final statusMap = {
      for (final entry in saved)
        entry.split(':')[0]: entry.split(':')[1],
    };
    state = [
      for (final b in state)
        statusMap.containsKey(b.id)
            ? b.copyWith(
                status: BookingStatus.values.firstWhere(
                  (s) => s.name == statusMap[b.id],
                  orElse: () => b.status,
                ),
              )
            : b,
    ];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((b) => '${b.id}:${b.status.name}').toList(),
    );
  }

  void markArrived(String id) => _updateStatus(id, BookingStatus.arrived);
  void markCompleted(String id) => _updateStatus(id, BookingStatus.completed);
  void markNoShow(String id) => _updateStatus(id, BookingStatus.noShow);

  void _updateStatus(String id, BookingStatus status) {
    state = [
      for (final b in state) b.id == id ? b.copyWith(status: status) : b,
    ];
    _persist();
    if (!useMockData) {
      FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({'status': status.name});
    }
  }
}

final bookingsNotifierProvider =
    StateNotifierProvider<BookingsNotifier, List<BookingModel>>(
  (_) => BookingsNotifier(),
);

final _firestoreBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('stationId', isEqualTo: kStationId)
      .where('slotTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('slotTime', isLessThan: Timestamp.fromDate(end))
      .orderBy('slotTime')
      .snapshots()
      .map((s) => s.docs.map(BookingModel.fromFirestore).toList());
});

final todayBookingsProvider = Provider<List<BookingModel>>((ref) {
  if (useMockData) return ref.watch(bookingsNotifierProvider);
  return ref.watch(_firestoreBookingsProvider).value ?? [];
});

enum BookingFilter { all, completed, pending, noShow }

final bookingFilterProvider = StateProvider<BookingFilter>((ref) => BookingFilter.all);
final bookingSearchProvider = StateProvider<String>((ref) => '');
final groupedBookingsProvider = Provider<Map<String, List<BookingModel>>>((ref) {
  final filter = ref.watch(bookingFilterProvider);
  final search = ref.watch(bookingSearchProvider).trim().toLowerCase();
  final allBookings = ref.watch(todayBookingsProvider);

  var bookings = switch (filter) {
    BookingFilter.all => allBookings,
    BookingFilter.completed =>
      allBookings.where((b) => b.status == BookingStatus.completed).toList(),
    BookingFilter.pending => allBookings
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.arrived)
        .toList(),
    BookingFilter.noShow =>
      allBookings.where((b) => b.status == BookingStatus.noShow).toList(),
  };

  if (search.isNotEmpty) {
    bookings = bookings
        .where((b) =>
            b.vehicleNumber.toLowerCase().contains(search) ||
            b.ownerName.toLowerCase().contains(search))
        .toList();
  }
  final Map<String, List<BookingModel>> grouped = {};
  for (final b in bookings) {
    grouped.putIfAbsent(_slotLabel(b.slotTime), () => []).add(b);
  }
  final sorted = Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
});

final bookingStatsProvider = Provider<
    ({int total, int completed, int pending, int noShow})>((ref) {
  final bookings = ref.watch(todayBookingsProvider);
  return (
    total: bookings.length,
    completed:
        bookings.where((b) => b.status == BookingStatus.completed).length,
    pending: bookings
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.arrived)
        .length,
    noShow:
        bookings.where((b) => b.status == BookingStatus.noShow).length,
  );
});

String _slotLabel(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final e = (t.hour + 1).toString().padLeft(2, '0');
  return '$h:00 – $e:00';
}
