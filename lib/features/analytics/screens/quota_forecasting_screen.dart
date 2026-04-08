import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../engines/co2_emissions_engine.dart';
import '../engines/quota_suggestion_engine.dart';
import '../models/analytics_summary_model.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/analytics_stat_card.dart';

class QuotaForecastingScreen extends ConsumerWidget {
  const QuotaForecastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(quotaForecastProvider);
    final nationalAsync = ref.watch(nationalAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quota & Forecasting'),
        backgroundColor: AppColors.background,
      ),
      body: forecastAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (forecast) {
          // Run the rule-based engines on whatever data is available.
          final history = forecast.last4Weeks
              .where((p) => p.allocated > 0)
              .map((p) => p.used / p.allocated)
              .toList();

          final suggestion = QuotaSuggestionEngine.compute(
            allocatedWeekly: forecast.allocatedWeekly,
            usedWeekly: forecast.usedWeekly,
            historicalUtilization: history,
          );

          final co2 = nationalAsync.when(
            data: (n) => Co2EmissionsEngine.compute(
              petrolLitres: n.totalPetrolMonthly,
              dieselLitres: n.totalDieselMonthly,
            ),
            loading: () => Co2Result.zero,
            error: (_, __) => Co2Result.zero,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UtilizationCard(forecast: forecast),
                const SizedBox(height: 20),

                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.water_drop_rounded,
                      label: 'Allocated',
                      value:
                          '${(forecast.allocatedWeekly / 1000).toStringAsFixed(0)}K L',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Used',
                      value:
                          '${(forecast.usedWeekly / 1000).toStringAsFixed(0)}K L',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.delete_outline_rounded,
                      label: 'Unused',
                      value:
                          '${(forecast.wastedLitres / 1000).toStringAsFixed(1)}K L',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.eco_rounded,
                      label: 'CO\u2082 / month',
                      value: '${co2.totalTonnes.toStringAsFixed(0)}t',
                      color: AppColors.primarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                AnalyticsSectionHeader(
                  title: 'User Segments',
                  subtitle: 'How users consume their quota',
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                _UserSegmentsCard(forecast: forecast),
                const SizedBox(height: 24),

                AnalyticsSectionHeader(
                  title: 'Allocated vs Used',
                  subtitle: 'Last 4 weeks',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _TrendCard(points: forecast.last4Weeks),
                const SizedBox(height: 24),

                AnalyticsSectionHeader(
                  title: 'Trend-Based Recommendation',
                  subtitle: 'Computed locally from 4-week utilization',
                  icon: Icons.lightbulb_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 12),
                _SuggestionCard(
                  suggestion: suggestion,
                  currentAllocation: forecast.allocatedWeekly,
                ),
                const SizedBox(height: 24),

                AnalyticsSectionHeader(
                  title: 'Environmental Impact',
                  subtitle: 'EPA emission factors (2.31 / 2.68 kg per L)',
                  icon: Icons.eco_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _CarbonCard(co2: co2, estimatedKmTotal: forecast.estimatedKmTotal),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Utilization Hero Card ─────────────────────────────

class _UtilizationCard extends StatelessWidget {
  final QuotaForecast forecast;

  const _UtilizationCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final pct = (forecast.utilizationRate * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY QUOTA UTILIZATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'of allocated',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.2)),
                  FractionallySizedBox(
                    widthFactor: forecast.utilizationRate,
                    child: Container(color: const Color(0xFF7BF1A8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(forecast.usedWeekly / 1000).toStringAsFixed(1)}K L used',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(forecast.allocatedWeekly / 1000).toStringAsFixed(1)}K L allocated',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────


// ─── Section Header ─────────────────────────────────────


// ─── User Segments Card ────────────────────────────────

class _UserSegmentsCard extends StatelessWidget {
  final QuotaForecast forecast;

  const _UserSegmentsCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    flex: (forecast.fullyUtilizedPercent * 1000).round(),
                    child: Container(color: AppColors.success),
                  ),
                  Expanded(
                    flex: (forecast.partialPercent * 1000).round(),
                    child: Container(color: AppColors.warning),
                  ),
                  Expanded(
                    flex: (forecast.unusedPercent * 1000).round(),
                    child: Container(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SegmentRow(
            color: AppColors.success,
            label: 'Fully Utilized',
            sublabel: 'Used 90%+ of weekly quota',
            count: forecast.fullyUtilizedUsers,
            percent: forecast.fullyUtilizedPercent,
          ),
          const SizedBox(height: 14),
          _SegmentRow(
            color: AppColors.warning,
            label: 'Partial Users',
            sublabel: 'Used between 10% and 90%',
            count: forecast.partialUsers,
            percent: forecast.partialPercent,
          ),
          const SizedBox(height: 14),
          _SegmentRow(
            color: AppColors.error,
            label: 'Unused Quota',
            sublabel: 'Used less than 10%',
            count: forecast.unusedUsers,
            percent: forecast.unusedPercent,
          ),
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final Color color;
  final String label;
  final String sublabel;
  final int count;
  final double percent;

  const _SegmentRow({
    required this.color,
    required this.label,
    required this.sublabel,
    required this.count,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 11,
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
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Trend Card ────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final List<QuotaTrendPoint> points;

  const _TrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final maxVal = points
        .map((p) => p.allocated)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final allocRatio = maxVal > 0 ? p.allocated / maxVal : 0.0;
                final usedRatio = maxVal > 0 ? p.used / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(p.used / 1000).toStringAsFixed(0)}/${(p.allocated / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: (140 * allocRatio).clamp(4.0, 140.0),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            Container(
                              height: (140 * usedRatio).clamp(4.0, 140.0),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.success,
                                    AppColors.success.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.success, label: 'Used'),
              const SizedBox(width: 20),
              _LegendDot(
                color: AppColors.accent.withValues(alpha: 0.4),
                label: 'Allocated',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Suggestion Card ───────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final QuotaSuggestion suggestion;
  final double currentAllocation;

  const _SuggestionCard({
    required this.suggestion,
    required this.currentAllocation,
  });

  Color get _accent {
    switch (suggestion.action) {
      case SuggestionAction.reduce:
        return AppColors.warning;
      case SuggestionAction.increase:
        return AppColors.error;
      case SuggestionAction.hold:
        return AppColors.success;
    }
  }

  IconData get _icon {
    switch (suggestion.action) {
      case SuggestionAction.reduce:
        return Icons.trending_down_rounded;
      case SuggestionAction.increase:
        return Icons.trending_up_rounded;
      case SuggestionAction.hold:
        return Icons.check_circle_rounded;
    }
  }

  String get _changeLabel {
    final pct = suggestion.changePercent;
    if (pct == 0) return '0%';
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.08),
            _accent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.headline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Confidence ${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(suggestion.suggestedWeeklyQuota / 1000).toStringAsFixed(1)}K L',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _changeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'vs current ${(currentAllocation / 1000).toStringAsFixed(1)}K L',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.reason,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carbon Card ───────────────────────────────────────

class _CarbonCard extends StatelessWidget {
  final Co2Result co2;
  final double estimatedKmTotal;

  const _CarbonCard({required this.co2, required this.estimatedKmTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${co2.totalTonnes.toStringAsFixed(1)} t',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'CO\u2082 emissions this month',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          _CarbonStat(
            icon: Icons.local_gas_station_rounded,
            label: 'From petrol',
            value: '${(co2.petrolKg / 1000).toStringAsFixed(1)} t',
          ),
          const SizedBox(height: 12),
          _CarbonStat(
            icon: Icons.local_shipping_rounded,
            label: 'From diesel',
            value: '${(co2.dieselKg / 1000).toStringAsFixed(1)} t',
          ),
          const SizedBox(height: 12),
          _CarbonStat(
            icon: Icons.route_rounded,
            label: 'Estimated total distance',
            value: '${(estimatedKmTotal / 1000000).toStringAsFixed(2)}M km',
          ),
          const SizedBox(height: 12),
          _CarbonStat(
            icon: Icons.park_rounded,
            label: 'Trees needed to offset (yearly)',
            value: '${(co2.equivalentTreesYearly / 1000).toStringAsFixed(1)}K',
          ),
          const SizedBox(height: 12),
          _CarbonStat(
            icon: Icons.flight_takeoff_rounded,
            label: 'Equivalent flights (CMB \u2192 LHR)',
            value: '~${co2.equivalentFlights}',
          ),
        ],
      ),
    );
  }
}

class _CarbonStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CarbonStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
