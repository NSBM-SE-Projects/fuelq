import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/analytics_stat_card.dart';

class NationalAnalyticsScreen extends ConsumerWidget {
  const NationalAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final nationalAsync = ref.watch(nationalAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('National Analytics'),
        backgroundColor: AppColors.background,
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summary) => nationalAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (national) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top stats row
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Today',
                      value: '${_k(summary.todayLitresDispensed)} L',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.calendar_view_week_rounded,
                      label: 'This Week',
                      value: '${_k(summary.weeklyLitresDispensed)} L',
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'This Month',
                      value: '${_k(summary.monthlyLitresDispensed)} L',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.directions_car_rounded,
                      label: 'Avg / Vehicle',
                      value: '${national.avgConsumptionPerVehicle.toStringAsFixed(1)} L',
                      color: AppColors.primarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Daily consumption (last 7 days)
                AnalyticsChartCard(
                  title: 'Last 7 Days',
                  subtitle: 'Daily fuel dispensed',
                  child: AnalyticsBarChart(
                    bars: national.last7Days
                        .map((d) => BarData(d.day, d.litres))
                        .toList(),
                    color: AppColors.accent,
                    valueFormatter: (v) => '${(v / 1000).toStringAsFixed(1)}K',
                  ),
                ),
                const SizedBox(height: 16),

                // Peak demand row
                Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.event_rounded,
                        label: 'Peak Day',
                        value: national.peakDay,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.access_time_rounded,
                        label: 'Peak Hour',
                        value: national.peakHour,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hourly consumption today
                AnalyticsChartCard(
                  title: 'Today by Hour',
                  subtitle: 'Live demand throughout the day',
                  child: AnalyticsBarChart(
                    bars: national.hourlyToday
                        .map((h) => BarData('${h.hour}', h.litres))
                        .toList(),
                    color: AppColors.success,
                    valueFormatter: (v) => v.toStringAsFixed(0),
                    compact: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly trend
                AnalyticsChartCard(
                  title: 'Monthly Trend',
                  subtitle:
                      '${national.monthlyGrowthPercent >= 0 ? "+" : ""}${national.monthlyGrowthPercent.toStringAsFixed(1)}% vs last month',
                  child: AnalyticsBarChart(
                    bars: national.last6Months
                        .map((m) => BarData(m.month, m.litres))
                        .toList(),
                    color: AppColors.primary,
                    valueFormatter: (v) => '${(v / 1000).toStringAsFixed(0)}K',
                  ),
                ),
                const SizedBox(height: 24),

                // Petrol vs Diesel
                _PetrolDieselCard(
                  petrol: national.totalPetrolMonthly,
                  diesel: national.totalDieselMonthly,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _k(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Stat Card ──────────────────────────────────────────


// ─── Insight Card ──────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card Wrapper ────────────────────────────────


// ─── Bar Chart ─────────────────────────────────────────



// ─── Petrol vs Diesel Card ─────────────────────────────

class _PetrolDieselCard extends StatelessWidget {
  final double petrol;
  final double diesel;

  const _PetrolDieselCard({required this.petrol, required this.diesel});

  @override
  Widget build(BuildContext context) {
    final total = petrol + diesel;
    final petrolPct = total > 0 ? petrol / total : 0.0;
    final dieselPct = 1 - petrolPct;

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
            'Petrol vs Diesel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Monthly distribution',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    flex: (petrolPct * 1000).round(),
                    child: Container(color: AppColors.accent),
                  ),
                  Expanded(
                    flex: (dieselPct * 1000).round(),
                    child: Container(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: AppColors.accent,
                  label: 'Petrol',
                  value: '${(petrol / 1000).toStringAsFixed(1)}K L',
                  percent: '${(petrolPct * 100).toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.warning,
                  label: 'Diesel',
                  value: '${(diesel / 1000).toStringAsFixed(1)}K L',
                  percent: '${(dieselPct * 100).toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
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
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
