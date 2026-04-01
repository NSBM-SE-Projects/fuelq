import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/quota_model.dart';

final _quotasStreamProvider = StreamProvider<List<QuotaModel>>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield [];
    return;
  }

  final firestore = ref.watch(firestoreProvider);
  final stream = firestore
    .collection('users')
    .doc(user.uid)
    .collection('vehicles')
    .orderBy('createdAt', descending: true)
    .snapshots();

    await for (final snapshot in stream) {
      final now = DateTime.now();

      for(final doc in snapshot.docs) {
        final weekEnd = (doc.data()['weekEnd'] as Timestamp?)?.toDate();
        if (weekEnd != null && now.isAfter(weekEnd)) {
          final newWeekStart = now.subtract(Duration(days: now.weekday - 1));
          final newWeekEnd = now.add(Duration(days: 7 - now.weekday));
          doc.reference.update({
            'used': 0.0,
            'weekStart': Timestamp.fromDate(newWeekStart),
            'weekEnd': Timestamp.fromDate(newWeekEnd),
          });
        }
      }

      yield snapshot.docs
        .map((doc) => QuotaModel.fromVehicleDoc(doc.id, doc.data()))
        .toList();
    }
});

final quotasProvider = Provider<List<QuotaModel>>((ref) {
  return ref.watch(_quotasStreamProvider).valueOrNull ?? [];
});

final quotaSummaryProvider = Provider<QuotaSummary>((ref) {
  final quotas = ref.watch(quotasProvider);

  double totalLimit = 0;
  double totalUsed = 0;

  for(final q in quotas) {
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
