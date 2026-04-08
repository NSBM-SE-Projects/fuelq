import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/analytics_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final analyticsAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return Column(
            children: [
              // Header
              _AdminHeader(userName: user.name),
              // Content
              Expanded(
                child: analyticsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (summary) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Fuel Meter
                        _LiveFuelMeterCard(
                          todayLitres: summary.todayLitresDispensed,
                          transactions: summary.todayTransactions,
                          petrolPercent: summary.todayPetrolPercent,
                        ),
                        const SizedBox(height: 20),

                        // Key Metrics
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MetricCard(
                              icon: Icons.people_rounded,
                              label: 'Users',
                              value: _formatNumber(summary.totalUsers),
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              icon: Icons.directions_car_rounded,
                              label: 'Vehicles',
                              value: _formatNumber(summary.totalVehicles),
                              color: AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MetricCard(
                              icon: Icons.local_gas_station_rounded,
                              label: 'Stations',
                              value: summary.totalStations.toString(),
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              icon: Icons.receipt_long_rounded,
                              label: 'Today\'s Txns',
                              value: summary.todayTransactions.toString(),
                              color: AppColors.primarySoft,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Consumption Summary
                        _ConsumptionCard(
                          weekly: summary.weeklyLitresDispensed,
                          monthly: summary.monthlyLitresDispensed,
                          petrol: summary.petrolLitres,
                          diesel: summary.dieselLitres,
                        ),
                        const SizedBox(height: 20),

                        // Quick Navigation
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _NavTile(
                          icon: Icons.bar_chart_rounded,
                          title: 'National Analytics',
                          subtitle: 'Consumption trends, demand periods',
                          onTap: () => context.push('/analytics/national'),
                        ),
                        _NavTile(
                          icon: Icons.store_rounded,
                          title: 'Station Analytics',
                          subtitle: 'Performance, efficiency, supply vs demand',
                          onTap: () => context.push('/analytics/stations'),
                        ),
                        _NavTile(
                          icon: Icons.map_rounded,
                          title: 'Regional View',
                          subtitle: 'Heatmap, under-served areas',
                          onTap: () => context.push('/analytics/regional'),
                        ),
                        _NavTile(
                          icon: Icons.group_rounded,
                          title: 'User Insights',
                          subtitle: 'Registrations, vehicle types, patterns',
                          onTap: () => context.push('/analytics/users'),
                        ),
                        _NavTile(
                          icon: Icons.trending_up_rounded,
                          title: 'Quota & Forecasting',
                          subtitle: 'Utilization, predictions, carbon footprint',
                          onTap: () => context.push('/analytics/quota'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// ─── Header ──────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String userName;

  const _AdminHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/admin-profile'),
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
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Government Admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ─── Live Fuel Meter ─────────────────────────────────────

class _LiveFuelMeterCard extends StatelessWidget {
  final double todayLitres;
  final int transactions;
  final double petrolPercent;

  const _LiveFuelMeterCard({
    required this.todayLitres,
    required this.transactions,
    required this.petrolPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B3A), Color(0xFF27AE60)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF7BF1A8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE FUEL METER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatLitres(todayLitres)} L',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'dispensed today across $transactions transactions',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // Petrol vs Diesel bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (petrolPercent * 100).round(),
                    child: Container(color: const Color(0xFF7BF1A8)),
                  ),
                  Expanded(
                    flex: ((1 - petrolPercent) * 100).round(),
                    child: Container(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FuelLabel(
                color: const Color(0xFF7BF1A8),
                label: 'Petrol ${(petrolPercent * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 16),
              _FuelLabel(
                color: Colors.white38,
                label: 'Diesel ${((1 - petrolPercent) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLitres(double litres) {
    if (litres >= 1000) {
      return '${(litres / 1000).toStringAsFixed(1)}K';
    }
    return litres.toStringAsFixed(0);
  }
}

class _FuelLabel extends StatelessWidget {
  final Color color;
  final String label;

  const _FuelLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Consumption Card ────────────────────────────────────

class _ConsumptionCard extends StatelessWidget {
  final double weekly;
  final double monthly;
  final double petrol;
  final double diesel;

  const _ConsumptionCard({
    required this.weekly,
    required this.monthly,
    required this.petrol,
    required this.diesel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel Consumption',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ConsumptionItem(
                label: 'This Week',
                value: '${(weekly / 1000).toStringAsFixed(1)}K L',
                icon: Icons.calendar_view_week_rounded,
              ),
              const SizedBox(width: 20),
              _ConsumptionItem(
                label: 'This Month',
                value: '${(monthly / 1000).toStringAsFixed(1)}K L',
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FuelTypeRow(
                  label: 'Petrol',
                  litres: petrol,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FuelTypeRow(
                  label: 'Diesel',
                  litres: diesel,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsumptionItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ConsumptionItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuelTypeRow extends StatelessWidget {
  final String label;
  final double litres;
  final Color color;

  const _FuelTypeRow({
    required this.label,
    required this.litres,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(litres / 1000).toStringAsFixed(1)}K L',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Navigation Tile ─────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
