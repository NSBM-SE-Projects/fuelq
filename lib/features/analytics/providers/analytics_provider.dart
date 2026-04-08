import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_summary_model.dart';

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  // TODO: Replace with real Firestore aggregation queries
  // Simulating network delay for realistic loading state
  await Future.delayed(const Duration(milliseconds: 800));

  return const AnalyticsSummary(
    todayLitresDispensed: 12450.5,
    totalUsers: 3842,
    totalVehicles: 5216,
    totalStations: 47,
    todayTransactions: 387,
    weeklyLitresDispensed: 78320.0,
    monthlyLitresDispensed: 312840.0,
    petrolLitres: 7470.3,
    dieselLitres: 4980.2,
  );
});

final nationalAnalyticsProvider = FutureProvider<NationalAnalytics>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return const NationalAnalytics(
    avgConsumptionPerVehicle: 14.7,
    monthlyGrowthPercent: 8.4,
    last7Days: [
      DailyConsumption('Mon', 11200),
      DailyConsumption('Tue', 12800),
      DailyConsumption('Wed', 10500),
      DailyConsumption('Thu', 13900),
      DailyConsumption('Fri', 15600),
      DailyConsumption('Sat', 14200),
      DailyConsumption('Sun', 9100),
    ],
    hourlyToday: [
      HourlyConsumption(6, 320),
      HourlyConsumption(7, 780),
      HourlyConsumption(8, 1450),
      HourlyConsumption(9, 1280),
      HourlyConsumption(10, 920),
      HourlyConsumption(11, 760),
      HourlyConsumption(12, 1100),
      HourlyConsumption(13, 1380),
      HourlyConsumption(14, 1050),
      HourlyConsumption(15, 870),
      HourlyConsumption(16, 1240),
      HourlyConsumption(17, 1620),
      HourlyConsumption(18, 1480),
    ],
    last6Months: [
      MonthlyConsumption('Nov', 264500),
      MonthlyConsumption('Dec', 278300),
      MonthlyConsumption('Jan', 285900),
      MonthlyConsumption('Feb', 292400),
      MonthlyConsumption('Mar', 305600),
      MonthlyConsumption('Apr', 312840),
    ],
    totalPetrolMonthly: 187700,
    totalDieselMonthly: 125140,
  );
});

final stationAnalyticsProvider =
    FutureProvider<List<StationAnalytics>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return const [
    StationAnalytics(
      id: 's1',
      name: 'Ceypetco Colombo 03',
      region: 'Colombo',
      monthlyLitres: 28400,
      petrolLitres: 17200,
      dieselLitres: 11200,
      monthlyTransactions: 1820,
      capacity: 1500,
      currentDemand: 1620,
      dispensedToday: 1340,
      noShowRate: 0.06,
      avgWaitMinutes: 8,
    ),
    StationAnalytics(
      id: 's2',
      name: 'IOC Nugegoda',
      region: 'Colombo',
      monthlyLitres: 25100,
      petrolLitres: 16800,
      dieselLitres: 8300,
      monthlyTransactions: 1650,
      capacity: 1400,
      currentDemand: 1380,
      dispensedToday: 1210,
      noShowRate: 0.09,
      avgWaitMinutes: 12,
    ),
    StationAnalytics(
      id: 's3',
      name: 'Lanka IOC Kandy',
      region: 'Kandy',
      monthlyLitres: 22600,
      petrolLitres: 14500,
      dieselLitres: 8100,
      monthlyTransactions: 1480,
      capacity: 1200,
      currentDemand: 1100,
      dispensedToday: 980,
      noShowRate: 0.08,
      avgWaitMinutes: 10,
    ),
    StationAnalytics(
      id: 's4',
      name: 'Ceypetco Galle',
      region: 'Galle',
      monthlyLitres: 19800,
      petrolLitres: 11200,
      dieselLitres: 8600,
      monthlyTransactions: 1290,
      capacity: 1100,
      currentDemand: 1300,
      dispensedToday: 1080,
      noShowRate: 0.11,
      avgWaitMinutes: 18,
    ),
    StationAnalytics(
      id: 's5',
      name: 'IOC Negombo',
      region: 'Gampaha',
      monthlyLitres: 18400,
      petrolLitres: 12100,
      dieselLitres: 6300,
      monthlyTransactions: 1210,
      capacity: 1000,
      currentDemand: 880,
      dispensedToday: 760,
      noShowRate: 0.07,
      avgWaitMinutes: 9,
    ),
    StationAnalytics(
      id: 's6',
      name: 'Ceypetco Matara',
      region: 'Matara',
      monthlyLitres: 14200,
      petrolLitres: 8800,
      dieselLitres: 5400,
      monthlyTransactions: 920,
      capacity: 900,
      currentDemand: 540,
      dispensedToday: 480,
      noShowRate: 0.05,
      avgWaitMinutes: 6,
    ),
    StationAnalytics(
      id: 's7',
      name: 'Lanka IOC Jaffna',
      region: 'Jaffna',
      monthlyLitres: 12100,
      petrolLitres: 7400,
      dieselLitres: 4700,
      monthlyTransactions: 780,
      capacity: 800,
      currentDemand: 920,
      dispensedToday: 720,
      noShowRate: 0.13,
      avgWaitMinutes: 22,
    ),
    StationAnalytics(
      id: 's8',
      name: 'Ceypetco Anuradhapura',
      region: 'Anuradhapura',
      monthlyLitres: 9800,
      petrolLitres: 5600,
      dieselLitres: 4200,
      monthlyTransactions: 640,
      capacity: 700,
      currentDemand: 410,
      dispensedToday: 380,
      noShowRate: 0.04,
      avgWaitMinutes: 5,
    ),
  ];
});

final regionAnalyticsProvider =
    FutureProvider<List<RegionAnalytics>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return const [
    RegionAnalytics(
      name: 'Colombo',
      monthlyLitres: 53500,
      stationCount: 12,
      registeredVehicles: 1840,
      demandSatisfaction: 0.78,
      avgWaitMinutes: 14,
    ),
    RegionAnalytics(
      name: 'Gampaha',
      monthlyLitres: 38200,
      stationCount: 9,
      registeredVehicles: 1320,
      demandSatisfaction: 0.91,
      avgWaitMinutes: 9,
    ),
    RegionAnalytics(
      name: 'Kandy',
      monthlyLitres: 32600,
      stationCount: 7,
      registeredVehicles: 1080,
      demandSatisfaction: 0.88,
      avgWaitMinutes: 11,
    ),
    RegionAnalytics(
      name: 'Galle',
      monthlyLitres: 26800,
      stationCount: 5,
      registeredVehicles: 820,
      demandSatisfaction: 0.72,
      avgWaitMinutes: 18,
    ),
    RegionAnalytics(
      name: 'Matara',
      monthlyLitres: 18400,
      stationCount: 4,
      registeredVehicles: 560,
      demandSatisfaction: 0.94,
      avgWaitMinutes: 6,
    ),
    RegionAnalytics(
      name: 'Jaffna',
      monthlyLitres: 16200,
      stationCount: 3,
      registeredVehicles: 480,
      demandSatisfaction: 0.68,
      avgWaitMinutes: 22,
    ),
    RegionAnalytics(
      name: 'Anuradhapura',
      monthlyLitres: 12100,
      stationCount: 3,
      registeredVehicles: 360,
      demandSatisfaction: 0.96,
      avgWaitMinutes: 5,
    ),
    RegionAnalytics(
      name: 'Kurunegala',
      monthlyLitres: 21500,
      stationCount: 4,
      registeredVehicles: 690,
      demandSatisfaction: 0.82,
      avgWaitMinutes: 13,
    ),
    RegionAnalytics(
      name: 'Batticaloa',
      monthlyLitres: 9800,
      stationCount: 2,
      registeredVehicles: 290,
      demandSatisfaction: 0.74,
      avgWaitMinutes: 17,
    ),
  ];
});

final userInsightsProvider = FutureProvider<UserInsights>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return const UserInsights(
    newUsersThisWeek: 142,
    newUsersThisMonth: 587,
    weeklyGrowthPercent: 12.4,
    registrationTrend: [
      RegistrationPoint('Wk 1', 98),
      RegistrationPoint('Wk 2', 116),
      RegistrationPoint('Wk 3', 124),
      RegistrationPoint('Wk 4', 107),
      RegistrationPoint('Wk 5', 132),
      RegistrationPoint('Wk 6', 142),
    ],
    vehicleCategories: [
      VehicleCategory(
        name: 'Motorcycles',
        count: 2180,
        monthlyLitres: 78400,
        fuelType: 'petrol',
      ),
      VehicleCategory(
        name: 'Cars',
        count: 1890,
        monthlyLitres: 142300,
        fuelType: 'mixed',
      ),
      VehicleCategory(
        name: 'Vans / SUVs',
        count: 720,
        monthlyLitres: 56800,
        fuelType: 'mixed',
      ),
      VehicleCategory(
        name: 'Heavy Vehicles',
        count: 426,
        monthlyLitres: 35340,
        fuelType: 'diesel',
      ),
    ],
    topCustomers: [
      TopCustomer(
        name: 'Nimal Perera',
        vehicleNumber: 'CBA-4521',
        monthlyLitres: 64.0,
        refuelCount: 4,
        favoriteStation: 'Ceypetco Colombo 03',
        estimatedKm: 832,
      ),
      TopCustomer(
        name: 'Saman Fernando',
        vehicleNumber: 'WP-CAR-7821',
        monthlyLitres: 58.5,
        refuelCount: 4,
        favoriteStation: 'IOC Nugegoda',
        estimatedKm: 760,
      ),
      TopCustomer(
        name: 'Kasun Jayasuriya',
        vehicleNumber: 'NB-9912',
        monthlyLitres: 56.0,
        refuelCount: 4,
        favoriteStation: 'Lanka IOC Kandy',
        estimatedKm: 728,
      ),
      TopCustomer(
        name: 'Ruwan Silva',
        vehicleNumber: 'GA-3344',
        monthlyLitres: 52.0,
        refuelCount: 3,
        favoriteStation: 'Ceypetco Galle',
        estimatedKm: 624,
      ),
      TopCustomer(
        name: 'Tharindu Bandara',
        vehicleNumber: 'KU-5567',
        monthlyLitres: 48.0,
        refuelCount: 3,
        favoriteStation: 'Ceypetco Kurunegala',
        estimatedKm: 600,
      ),
    ],
  );
});

final quotaForecastProvider = FutureProvider<QuotaForecast>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));

  return const QuotaForecast(
    allocatedWeekly: 104320,
    usedWeekly: 78320,
    fullyUtilizedUsers: 1420,
    partialUsers: 1908,
    unusedUsers: 514,
    estimatedKmTotal: 4068920,
    last4Weeks: [
      QuotaTrendPoint('Wk 1', 102400, 71800),
      QuotaTrendPoint('Wk 2', 103200, 74600),
      QuotaTrendPoint('Wk 3', 104100, 76900),
      QuotaTrendPoint('Wk 4', 104320, 78320),
    ],
  );
});
