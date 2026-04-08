import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/analytics_summary_model.dart';

double _getLitres(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  return (data?['litresDispensed'] as num?)?.toDouble() ?? 0;
}

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final fs = ref.read(firestoreProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final todayBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .where('slotStart', isLessThan: Timestamp.fromDate(todayStart.add(const Duration(days: 1))))
      .where('status', isEqualTo: 'completed')
      .get();

  final weekBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
      .where('status', isEqualTo: 'completed')
      .get();

  final monthBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
      .where('status', isEqualTo: 'completed')
      .get();

  final users = await fs.collection('users').get();
  final stations = await fs.collection('stations').get();

  double todayLitres = 0, petrol = 0, diesel = 0, weekLitres = 0, monthLitres = 0;
  int vehicleCount = 0;

  for (final doc in todayBookings.docs) {
    final amount = _getLitres(doc);
    todayLitres += amount;
    if ((doc['fuelType'] as String?) == 'diesel') {
      diesel += amount;
    } else {
      petrol += amount;
    }
  }

  for (final doc in weekBookings.docs) {
    weekLitres += _getLitres(doc);
  }
  for (final doc in monthBookings.docs) {
    monthLitres += _getLitres(doc);
  }

  for (final user in users.docs) {
    final vehicles = await fs.collection('users').doc(user.id).collection('vehicles').get();
    vehicleCount += vehicles.size;
  }

  return AnalyticsSummary(
    todayLitresDispensed: todayLitres,
    totalUsers: users.size,
    totalVehicles: vehicleCount,
    totalStations: stations.size,
    todayTransactions: todayBookings.size,
    weeklyLitresDispensed: weekLitres,
    monthlyLitresDispensed: monthLitres,
    petrolLitres: petrol,
    dieselLitres: diesel,
  );
});

final nationalAnalyticsProvider = FutureProvider<NationalAnalytics>((ref) async {
  final fs = ref.read(firestoreProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final prevMonthStart = DateTime(now.year, now.month - 1, 1);

  final monthBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
      .where('status', isEqualTo: 'completed')
      .get();

  final prevMonthBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(prevMonthStart))
      .where('slotStart', isLessThan: Timestamp.fromDate(monthStart))
      .where('status', isEqualTo: 'completed')
      .get();

  double monthTotal = 0, prevTotal = 0, monthPetrol = 0, monthDiesel = 0;
  final dailyMap = <String, double>{};
  final hourlyMap = <int, double>{};

  for (final doc in monthBookings.docs) {
    final amount = _getLitres(doc);
    monthTotal += amount;
    final slot = (doc['slotStart'] as Timestamp).toDate();
    if ((doc['fuelType'] as String?) == 'diesel') {
      monthDiesel += amount;
    } else {
      monthPetrol += amount;
    }
    if (slot.isAfter(now.subtract(const Duration(days: 7)))) {
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][slot.weekday - 1];
      dailyMap[dayName] = (dailyMap[dayName] ?? 0) + amount;
    }
    if (slot.day == now.day && slot.month == now.month) {
      hourlyMap[slot.hour] = (hourlyMap[slot.hour] ?? 0) + amount;
    }
  }

  for (final doc in prevMonthBookings.docs) {
    prevTotal += _getLitres(doc);
  }

  final vehicles = await fs.collection('users').get();
  int totalVehicles = 0;
  for (final u in vehicles.docs) {
    final v = await fs.collection('users').doc(u.id).collection('vehicles').get();
    totalVehicles += v.size;
  }

  final growth = prevTotal > 0 ? ((monthTotal - prevTotal) / prevTotal * 100) : 0.0;

  final last7Days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      .map((d) => DailyConsumption(d, dailyMap[d] ?? 0))
      .toList();

  final hourlyToday = hourlyMap.entries
      .map((e) => HourlyConsumption(e.key, e.value))
      .toList()
    ..sort((a, b) => a.hour.compareTo(b.hour));

  return NationalAnalytics(
    avgConsumptionPerVehicle: totalVehicles > 0 ? monthTotal / totalVehicles : 0,
    monthlyGrowthPercent: growth,
    last7Days: last7Days,
    hourlyToday: hourlyToday,
    last6Months: const [],
    totalPetrolMonthly: monthPetrol,
    totalDieselMonthly: monthDiesel,
  );
});

final stationAnalyticsProvider = FutureProvider<List<StationAnalytics>>((ref) async {
  final fs = ref.read(firestoreProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);

  final stations = await fs.collection('stations').get();
  final monthBookings = await fs.collection('bookings')
      .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
      .get();

  final result = <StationAnalytics>[];

  for (final station in stations.docs) {
    final sId = station.id;
    final sData = station.data();
    final stationBookings = monthBookings.docs.where((b) => b['stationId'] == sId).toList();
    final todayStationBookings = stationBookings.where((b) {
      final slot = (b['slotStart'] as Timestamp).toDate();
      return slot.isAfter(todayStart);
    }).toList();

    double monthLitres = 0, petrol = 0, diesel = 0, todayDispensed = 0;
    int noShow = 0;

    for (final b in stationBookings) {
      final amount = _getLitres(b);
      monthLitres += amount;
      if (b['status'] == 'noShow') noShow++;
      if ((b['fuelType'] as String?) == 'diesel') {
        diesel += amount;
      } else {
        petrol += amount;
      }
    }

    for (final b in todayStationBookings) {
      if (b['status'] == 'completed') {
        todayDispensed += _getLitres(b);
      }
    }

    final total = stationBookings.length;

    result.add(StationAnalytics(
      id: sId,
      name: sData['name'] as String? ?? '',
      region: (sData['address'] as String? ?? '').split(',').last.trim(),
      monthlyLitres: monthLitres,
      petrolLitres: petrol,
      dieselLitres: diesel,
      monthlyTransactions: total,
      capacity: (sData['maxQueue'] as num?)?.toInt() ?? 50,
      currentDemand: todayStationBookings.length,
      dispensedToday: todayDispensed.toInt(),
      noShowRate: total > 0 ? noShow / total : 0,
      avgWaitMinutes: 0,
    ));
  }

  result.sort((a, b) => b.monthlyLitres.compareTo(a.monthlyLitres));
  return result;
});

final regionAnalyticsProvider = FutureProvider<List<RegionAnalytics>>((ref) async {
  final stationData = await ref.watch(stationAnalyticsProvider.future);
  final regionMap = <String, List<StationAnalytics>>{};

  for (final s in stationData) {
    regionMap.putIfAbsent(s.region, () => []).add(s);
  }

  return regionMap.entries.map((e) {
    final stations = e.value;
    final totalLitres = stations.fold<double>(0, (acc, s) => acc + s.monthlyLitres);
    final totalTx = stations.fold<int>(0, (acc, s) => acc + s.monthlyTransactions);
    final avgWait = stations.isEmpty ? 0.0 : stations.fold<double>(0, (acc, s) => acc + s.avgWaitMinutes) / stations.length;
    final totalCapacity = stations.fold<int>(0, (acc, s) => acc + s.capacity);
    final totalDemand = stations.fold<int>(0, (acc, s) => acc + s.currentDemand);

    return RegionAnalytics(
      name: e.key,
      monthlyLitres: totalLitres,
      stationCount: stations.length,
      registeredVehicles: totalTx,
      demandSatisfaction: totalCapacity > 0 ? (totalDemand / totalCapacity).clamp(0.0, 1.0) : 0,
      avgWaitMinutes: avgWait,
    );
  }).toList()
    ..sort((a, b) => b.monthlyLitres.compareTo(a.monthlyLitres));
});

final userInsightsProvider = FutureProvider<UserInsights>((ref) async {
  final fs = ref.read(firestoreProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final users = await fs.collection('users').where('role', isEqualTo: 'vehicleOwner').get();
  final weekUsers = users.docs.where((u) {
    final created = (u['createdAt'] as Timestamp).toDate();
    return created.isAfter(weekStart);
  }).length;
  final monthUsers = users.docs.where((u) {
    final created = (u['createdAt'] as Timestamp).toDate();
    return created.isAfter(monthStart);
  }).length;

  final prevWeekStart = weekStart.subtract(const Duration(days: 7));
  final prevWeekUsers = users.docs.where((u) {
    final created = (u['createdAt'] as Timestamp).toDate();
    return created.isAfter(prevWeekStart) && created.isBefore(weekStart);
  }).length;

  final growth = prevWeekUsers > 0 ? ((weekUsers - prevWeekUsers) / prevWeekUsers * 100) : 0.0;

  final bookings = await fs.collection('bookings').where('status', isEqualTo: 'completed').get();
  final userBookingMap = <String, List<QueryDocumentSnapshot>>{};
  for (final b in bookings.docs) {
    final uid = b['userId'] as String;
    userBookingMap.putIfAbsent(uid, () => []).add(b);
  }

  final topCustomers = <TopCustomer>[];
  for (final entry in userBookingMap.entries) {
    double totalAmount = 0;
    String? favStation;
    final stationCounts = <String, int>{};
    for (final b in entry.value) {
      totalAmount += _getLitres(b);
      final sName = b['stationName'] as String? ?? '';
      stationCounts[sName] = (stationCounts[sName] ?? 0) + 1;
    }
    if (stationCounts.isNotEmpty) {
      favStation = stationCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final userDoc = users.docs.where((u) => u.id == entry.key).firstOrNull;
    topCustomers.add(TopCustomer(
      name: userDoc?['name'] as String? ?? 'Unknown',
      vehicleNumber: entry.value.first['vehicleNumber'] as String? ?? '',
      monthlyLitres: totalAmount,
      refuelCount: entry.value.length,
      favoriteStation: favStation ?? '',
      estimatedKm: totalAmount * 13,
    ));
  }

  topCustomers.sort((a, b) => b.monthlyLitres.compareTo(a.monthlyLitres));

  return UserInsights(
    newUsersThisWeek: weekUsers,
    newUsersThisMonth: monthUsers,
    weeklyGrowthPercent: growth,
    registrationTrend: const [],
    vehicleCategories: const [],
    topCustomers: topCustomers.take(5).toList(),
  );
});

final quotaForecastProvider = FutureProvider<QuotaForecast>((ref) async {
  final fs = ref.read(firestoreProvider);
  final users = await fs.collection('users').where('role', isEqualTo: 'vehicleOwner').get();

  double totalAllocated = 0, totalUsed = 0;
  int fully = 0, partial = 0, unused = 0;

  for (final user in users.docs) {
    final vehicles = await fs.collection('users').doc(user.id).collection('vehicles').get();
    for (final v in vehicles.docs) {
      final vData = v.data() as Map<String, dynamic>?;
      final fuelType = vData?['fuelType'] as String? ?? 'petrol';
      final limit = (vData?['weeklyLimit'] as num?)?.toDouble() ?? (fuelType == 'diesel' ? 32.0 : 16.0);
      final used = (vData?['used'] as num?)?.toDouble() ?? 0;
      totalAllocated += limit;
      totalUsed += used;
      final ratio = limit > 0 ? used / limit : 0;
      if (ratio >= 0.95) {
        fully++;
      } else if (ratio > 0) {
        partial++;
      } else {
        unused++;
      }
    }
  }

  return QuotaForecast(
    allocatedWeekly: totalAllocated,
    usedWeekly: totalUsed,
    fullyUtilizedUsers: fully,
    partialUsers: partial,
    unusedUsers: unused,
    estimatedKmTotal: totalUsed * 13,
    last4Weeks: const [],
  );
});
