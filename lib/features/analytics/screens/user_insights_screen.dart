import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/analytics_summary_model.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/analytics_stat_card.dart';

class UserInsightsScreen extends ConsumerWidget {
  const UserInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final insightsAsync = ref.watch(userInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Insights'),
        backgroundColor: AppColors.background,
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summary) => insightsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (insights) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top stats
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.people_rounded,
                      label: 'Total Users',
                      value: _formatNumber(summary.totalUsers),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.directions_car_rounded,
                      label: 'Total Vehicles',
                      value: _formatNumber(summary.totalVehicles),
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.person_add_rounded,
                      label: 'New This Week',
                      value: insights.newUsersThisWeek.toString(),
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Weekly Growth',
                      value:
                          '${insights.weeklyGrowthPercent >= 0 ? "+" : ""}${insights.weeklyGrowthPercent.toStringAsFixed(1)}%',
                      color: AppColors.primarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Registration trend chart
                AnalyticsChartCard(
                  title: 'Registration Trend',
                  subtitle: 'New users per week (last 6 weeks)',
                  child: AnalyticsBarChart(
                    bars: insights.registrationTrend
                        .map((p) => BarData(p.label, p.users.toDouble()))
                        .toList(),
                    color: AppColors.accent,
                    valueFormatter: (v) => v.toStringAsFixed(0),
                  ),
                ),
                const SizedBox(height: 24),

                // Vehicle category breakdown
                AnalyticsSectionHeader(
                  title: 'Vehicle Categories',
                  subtitle: 'Distribution by type',
                  icon: Icons.category_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _CategoryBreakdown(categories: insights.vehicleCategories),
                const SizedBox(height: 24),

                // Top customers
                AnalyticsSectionHeader(
                  title: 'Top Consumers',
                  subtitle: 'Highest fuel collection patterns',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 12),
                ...insights.topCustomers.asMap().entries.map(
                      (e) => _TopCustomerCard(
                        rank: e.key + 1,
                        customer: e.value,
                      ),
                    ),
              ],
            ),
          ),
        ),
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

// ─── Stat Card ──────────────────────────────────────────


// ─── Section Header ─────────────────────────────────────


// ─── Chart Card Wrapper ────────────────────────────────


// ─── Bar Chart ─────────────────────────────────────────



// ─── Vehicle Category Breakdown ────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<VehicleCategory> categories;

  const _CategoryBreakdown({required this.categories});

  IconData _iconFor(String name) {
    switch (name) {
      case 'Motorcycles':
        return Icons.two_wheeler_rounded;
      case 'Cars':
        return Icons.directions_car_rounded;
      case 'Vans / SUVs':
        return Icons.airport_shuttle_rounded;
      case 'Heavy Vehicles':
        return Icons.local_shipping_rounded;
      default:
        return Icons.commute_rounded;
    }
  }

  Color _colorFor(int index) {
    const palette = [
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.primarySoft,
    ];
    return palette[index % palette.length];
  }

  String _fuelLabel(String type) {
    switch (type) {
      case 'petrol':
        return 'Petrol';
      case 'diesel':
        return 'Diesel';
      default:
        return 'Petrol & Diesel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = categories.fold<int>(0, (sum, c) => sum + c.count);
    final totalLitres =
        categories.fold<double>(0, (sum, c) => sum + c.monthlyLitres);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: categories.asMap().entries.map((e) {
                  final pct = totalCount > 0 ? e.value.count / totalCount : 0.0;
                  return Expanded(
                    flex: (pct * 1000).round(),
                    child: Container(color: _colorFor(e.key)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...categories.asMap().entries.map((e) {
            final cat = e.value;
            final color = _colorFor(e.key);
            final pctOfFleet =
                totalCount > 0 ? (cat.count / totalCount) * 100 : 0.0;
            final pctOfFuel = totalLitres > 0
                ? (cat.monthlyLitres / totalLitres) * 100
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFor(cat.name), color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${(cat.monthlyLitres / 1000).toStringAsFixed(1)}K L',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.count} vehicles \u00B7 ${pctOfFleet.toStringAsFixed(0)}% of fleet \u00B7 ${pctOfFuel.toStringAsFixed(0)}% of fuel \u00B7 ${_fuelLabel(cat.fuelType)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Top Customer Card ─────────────────────────────────

class _TopCustomerCard extends StatelessWidget {
  final int rank;
  final TopCustomer customer;

  const _TopCustomerCard({required this.rank, required this.customer});

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _rankColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${customer.monthlyLitres.toStringAsFixed(0)} L',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${customer.refuelCount} refuels',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Favorite Station',
                  value: customer.favoriteStation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  icon: Icons.route_rounded,
                  label: 'Est. Distance',
                  value: '~${customer.estimatedKm.toStringAsFixed(0)} km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
