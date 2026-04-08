class AnalyticsSummary {
  final double todayLitresDispensed;
  final int totalUsers;
  final int totalVehicles;
  final int totalStations;
  final int todayTransactions;
  final double weeklyLitresDispensed;
  final double monthlyLitresDispensed;
  final double petrolLitres;
  final double dieselLitres;

  const AnalyticsSummary({
    required this.todayLitresDispensed,
    required this.totalUsers,
    required this.totalVehicles,
    required this.totalStations,
    required this.todayTransactions,
    required this.weeklyLitresDispensed,
    required this.monthlyLitresDispensed,
    required this.petrolLitres,
    required this.dieselLitres,
  });

  double get todayPetrolPercent =>
      (petrolLitres + dieselLitres) > 0
          ? petrolLitres / (petrolLitres + dieselLitres)
          : 0;

  double get todayDieselPercent => 1 - todayPetrolPercent;
}

class NationalAnalytics {
  final double avgConsumptionPerVehicle;
  final double monthlyGrowthPercent;
  final List<DailyConsumption> last7Days;
  final List<HourlyConsumption> hourlyToday;
  final List<MonthlyConsumption> last6Months;
  final double totalPetrolMonthly;
  final double totalDieselMonthly;

  const NationalAnalytics({
    required this.avgConsumptionPerVehicle,
    required this.monthlyGrowthPercent,
    required this.last7Days,
    required this.hourlyToday,
    required this.last6Months,
    required this.totalPetrolMonthly,
    required this.totalDieselMonthly,
  });

  String get peakDay {
    if (last7Days.isEmpty) return '-';
    final peak = last7Days.reduce((a, b) => a.litres > b.litres ? a : b);
    return peak.day;
  }

  String get peakHour {
    if (hourlyToday.isEmpty) return '-';
    final peak = hourlyToday.reduce((a, b) => a.litres > b.litres ? a : b);
    final h = peak.hour;
    final next = (h + 1) % 24;
    return '${_fmt(h)}:00 - ${_fmt(next)}:00';
  }

  static String _fmt(int h) => h.toString().padLeft(2, '0');
}

class DailyConsumption {
  final String day;
  final double litres;
  const DailyConsumption(this.day, this.litres);
}

class HourlyConsumption {
  final int hour;
  final double litres;
  const HourlyConsumption(this.hour, this.litres);
}

class MonthlyConsumption {
  final String month;
  final double litres;
  const MonthlyConsumption(this.month, this.litres);
}

class StationAnalytics {
  final String id;
  final String name;
  final String region;
  final double monthlyLitres;
  final double petrolLitres;
  final double dieselLitres;
  final int monthlyTransactions;
  final int capacity; // max litres station can dispense per day
  final int currentDemand; // litres requested in bookings today
  final int dispensedToday; // litres actually dispensed today
  final double noShowRate; // 0..1
  final double avgWaitMinutes;

  const StationAnalytics({
    required this.id,
    required this.name,
    required this.region,
    required this.monthlyLitres,
    required this.petrolLitres,
    required this.dieselLitres,
    required this.monthlyTransactions,
    required this.capacity,
    required this.currentDemand,
    required this.dispensedToday,
    required this.noShowRate,
    required this.avgWaitMinutes,
  });

  /// Efficiency: combination of low wait time, low no-shows, high utilization
  /// Returns 0..100
  double get efficiencyScore {
    final waitScore = (1 - (avgWaitMinutes / 60).clamp(0.0, 1.0)) * 100;
    final showScore = (1 - noShowRate) * 100;
    final utilization = capacity > 0
        ? (dispensedToday / capacity).clamp(0.0, 1.0)
        : 0.0;
    final utilScore = utilization * 100;
    return (waitScore * 0.4 + showScore * 0.3 + utilScore * 0.3);
  }

  /// 1.0 = at full demand, > 1 means demand exceeds capacity
  double get demandRatio => capacity > 0 ? currentDemand / capacity : 0;

  bool get isOverbooked => demandRatio > 1.0;
}

class RegionAnalytics {
  final String name;
  final double monthlyLitres;
  final int stationCount;
  final int registeredVehicles;
  final double demandSatisfaction; // 0..1, how much demand is met by capacity
  final double avgWaitMinutes;

  const RegionAnalytics({
    required this.name,
    required this.monthlyLitres,
    required this.stationCount,
    required this.registeredVehicles,
    required this.demandSatisfaction,
    required this.avgWaitMinutes,
  });

  /// Litres per registered vehicle (rough indicator of regional intensity)
  double get litresPerVehicle =>
      registeredVehicles > 0 ? monthlyLitres / registeredVehicles : 0;

  bool get isUnderServed => demandSatisfaction < 0.85;
}

class UserInsights {
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final double weeklyGrowthPercent;
  final List<RegistrationPoint> registrationTrend;
  final List<VehicleCategory> vehicleCategories;
  final List<TopCustomer> topCustomers;

  const UserInsights({
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.weeklyGrowthPercent,
    required this.registrationTrend,
    required this.vehicleCategories,
    required this.topCustomers,
  });
}

class RegistrationPoint {
  final String label;
  final int users;
  const RegistrationPoint(this.label, this.users);
}

class VehicleCategory {
  final String name;
  final int count;
  final double monthlyLitres;
  final String fuelType; // 'petrol' | 'diesel' | 'mixed'

  const VehicleCategory({
    required this.name,
    required this.count,
    required this.monthlyLitres,
    required this.fuelType,
  });
}

class TopCustomer {
  final String name;
  final String vehicleNumber;
  final double monthlyLitres;
  final int refuelCount;
  final String favoriteStation;
  final double estimatedKm; // calculated from fuel consumption rate

  const TopCustomer({
    required this.name,
    required this.vehicleNumber,
    required this.monthlyLitres,
    required this.refuelCount,
    required this.favoriteStation,
    required this.estimatedKm,
  });
}

class QuotaForecast {
  final double allocatedWeekly;
  final double usedWeekly;
  final int fullyUtilizedUsers;
  final int partialUsers;
  final int unusedUsers;
  final double estimatedKmTotal;
  final List<QuotaTrendPoint> last4Weeks;

  const QuotaForecast({
    required this.allocatedWeekly,
    required this.usedWeekly,
    required this.fullyUtilizedUsers,
    required this.partialUsers,
    required this.unusedUsers,
    required this.estimatedKmTotal,
    required this.last4Weeks,
  });

  double get utilizationRate =>
      allocatedWeekly > 0 ? (usedWeekly / allocatedWeekly).clamp(0.0, 1.0) : 0;

  double get wastedLitres => (allocatedWeekly - usedWeekly).clamp(0, double.infinity);

  int get totalUsers => fullyUtilizedUsers + partialUsers + unusedUsers;

  double get fullyUtilizedPercent =>
      totalUsers > 0 ? fullyUtilizedUsers / totalUsers : 0;
  double get partialPercent => totalUsers > 0 ? partialUsers / totalUsers : 0;
  double get unusedPercent => totalUsers > 0 ? unusedUsers / totalUsers : 0;
}

class QuotaTrendPoint {
  final String label;
  final double allocated;
  final double used;
  const QuotaTrendPoint(this.label, this.allocated, this.used);
}
