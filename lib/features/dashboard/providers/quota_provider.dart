import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

import '../models/quota_model.dart';

/// Builds quota data from the user's registered vehicles.
/// Uses default weekly limits (14L petrol, 20L diesel) with 0L used.
/// When backend is ready, replace this with Firestore reads.
final quotasProvider = Provider<List<QuotaModel>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesProvider);
  final vehicles = vehiclesAsync.valueOrNull ?? [];

  return vehicles
      .map((v) => QuotaModel.defaultForVehicle(
            vehicleId: v.id,
            vehicleNumber: v.vehicleNumber,
            nickname: v.nickname,
            fuelType: v.fuelType.name,
          ))
      .toList();
});

/// Aggregated quota summary across all vehicles.
final quotaSummaryProvider = Provider<QuotaSummary>((ref) {
  final quotas = ref.watch(quotasProvider);

  double totalLimit = 0;
  double totalUsed = 0;

  for (final q in quotas) {
    totalLimit += q.weeklyLimit;
    totalUsed += q.used;
  }

  return QuotaSummary(
    totalLimit: totalLimit,
    totalUsed: totalUsed,
    vehicleCount: quotas.length,
  );
});

class QuotaSummary {
  final double totalLimit;
  final double totalUsed;
  final int vehicleCount;

  QuotaSummary({
    required this.totalLimit,
    required this.totalUsed,
    required this.vehicleCount,
  });

  double get totalRemaining => (totalLimit - totalUsed).clamp(0, totalLimit);
  double get usagePercent => totalLimit > 0 ? (totalUsed / totalLimit).clamp(0, 1) : 0;
}
