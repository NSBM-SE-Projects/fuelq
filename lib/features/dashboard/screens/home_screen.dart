import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/quota_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/geofence_provider.dart';
import '../providers/quota_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final quotas = ref.watch(quotasProvider);
    final summary = ref.watch(quotaSummaryProvider);

    ref.watch(customerLocationBroadcaster);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('User profile not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with greeting + quota ring
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 28,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(user.role.name),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quota ring
                    Center(
                      child: QuotaRing(
                        usagePercent: summary.usagePercent,
                        remaining: summary.totalRemaining,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Summary stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        HeaderStat(label: 'Weekly Limit', value: '${summary.totalLimit.toStringAsFixed(0)}L'),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        HeaderStat(label: 'Used', value: '${summary.totalUsed.toStringAsFixed(1)}L'),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        HeaderStat(label: 'Vehicles', value: '${summary.vehicleCount}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Vehicle quota cards
              Expanded(
                child: quotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_gas_station_outlined, size: 32, color: AppColors.primaryLight),
                            ),
                            const SizedBox(height: 16),
                            const Text('No quota data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Register a vehicle to view your fuel quota', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => context.push('/add-vehicle', extra: {'uid': user.uid, 'isFirstTime': false}),
                              child: const Text('Register a Vehicle'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (quotas.isNotEmpty)
                              WeekInfoCard(
                                weekStart: quotas.first.weekStart,
                                weekEnd: quotas.first.weekEnd,
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Vehicle Quotas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 14),
                            ...quotas.map((q) => VehicleQuotaCard(quota: q)),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'vehicleOwner': return 'Vehicle Owner';
      case 'stationAttendant': return 'Station Attendant';
      case 'governmentAdmin': return 'Government Admin';
      default: return role;
    }
  }
}
