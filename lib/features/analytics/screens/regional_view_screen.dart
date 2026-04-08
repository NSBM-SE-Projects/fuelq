import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/analytics_summary_model.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/analytics_stat_card.dart';

class RegionalViewScreen extends ConsumerWidget {
  const RegionalViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(regionAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Regional View'),
        backgroundColor: AppColors.background,
      ),
      body: regionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (regions) {
          if (regions.isEmpty) {
            return const Center(child: Text('No regional data available.'));
          }

          // Sorted lists
          final byVolume = [...regions]
            ..sort((a, b) => b.monthlyLitres.compareTo(a.monthlyLitres));
          final underServed = regions.where((r) => r.isUnderServed).toList()
            ..sort((a, b) =>
                a.demandSatisfaction.compareTo(b.demandSatisfaction));

          final maxLitres = regions
              .map((r) => r.monthlyLitres)
              .reduce((a, b) => a > b ? a : b);
          final totalLitres =
              regions.fold<double>(0, (sum, r) => sum + r.monthlyLitres);
          final totalStations =
              regions.fold<int>(0, (sum, r) => sum + r.stationCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top stats
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.public_rounded,
                      label: 'Regions',
                      value: regions.length.toString(),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Stations',
                      value: totalStations.toString(),
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.water_drop_rounded,
                      label: 'Total Volume',
                      value: '${(totalLitres / 1000).toStringAsFixed(0)}K L',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Under-served',
                      value: underServed.length.toString(),
                      color: AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Heatmap section
                AnalyticsSectionHeader(
                  title: 'Consumption Heatmap',
                  subtitle: 'Monthly volume by region',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                _HeatmapGrid(regions: byVolume, maxLitres: maxLitres),
                const SizedBox(height: 24),

                // Under-served areas
                if (underServed.isNotEmpty) ...[
                  AnalyticsSectionHeader(
                    title: 'Under-served Areas',
                    subtitle: 'Regions where demand exceeds supply',
                    icon: Icons.priority_high_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  ...underServed.map((r) => _UnderServedCard(region: r)),
                  const SizedBox(height: 24),
                ],

                // All regions list
                AnalyticsSectionHeader(
                  title: 'All Regions',
                  subtitle: 'Detailed regional breakdown',
                  icon: Icons.format_list_bulleted_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                ...byVolume.map((r) => _RegionListItem(region: r)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────


// ─── Section Header ─────────────────────────────────────


// ─── Heatmap Grid ───────────────────────────────────────

class _HeatmapGrid extends StatelessWidget {
  final List<RegionAnalytics> regions;
  final double maxLitres;

  const _HeatmapGrid({required this.regions, required this.maxLitres});

  /// Returns a color from green→yellow→orange→red based on intensity 0..1
  Color _heatColor(double intensity) {
    if (intensity < 0.25) {
      return Color.lerp(
        const Color(0xFFD1FAE5),
        const Color(0xFF6EE7B7),
        intensity / 0.25,
      )!;
    } else if (intensity < 0.5) {
      return Color.lerp(
        const Color(0xFF6EE7B7),
        const Color(0xFFFCD34D),
        (intensity - 0.25) / 0.25,
      )!;
    } else if (intensity < 0.75) {
      return Color.lerp(
        const Color(0xFFFCD34D),
        const Color(0xFFFB923C),
        (intensity - 0.5) / 0.25,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFB923C),
        const Color(0xFFDC2626),
        (intensity - 0.75) / 0.25,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: regions.map((r) {
              final intensity = maxLitres > 0 ? r.monthlyLitres / maxLitres : 0.0;
              final color = _heatColor(intensity);
              final isDark = intensity > 0.55;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(r.monthlyLitres / 1000).toStringAsFixed(1)}K',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'litres',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Legend
          Row(
            children: [
              const Text(
                'Low',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFD1FAE5),
                          Color(0xFF6EE7B7),
                          Color(0xFFFCD34D),
                          Color(0xFFFB923C),
                          Color(0xFFDC2626),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'High',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Under-served Card ──────────────────────────────────

class _UnderServedCard extends StatelessWidget {
  final RegionAnalytics region;

  const _UnderServedCard({required this.region});

  @override
  Widget build(BuildContext context) {
    final shortfall =
        ((1 - region.demandSatisfaction) * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
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
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${region.stationCount} stations \u00B7 ${region.avgWaitMinutes.toStringAsFixed(0)} min wait',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-$shortfall%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Demand satisfaction bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Demand met',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(region.demandSatisfaction * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.divider),
                FractionallySizedBox(
                  widthFactor: region.demandSatisfaction,
                  child: Container(height: 6, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Region List Item ───────────────────────────────────

class _RegionListItem extends StatelessWidget {
  final RegionAnalytics region;

  const _RegionListItem({required this.region});

  Color get _statusColor {
    if (region.demandSatisfaction >= 0.9) return AppColors.success;
    if (region.demandSatisfaction >= 0.8) return AppColors.warning;
    return AppColors.error;
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${region.stationCount} stations \u00B7 ${region.registeredVehicles} vehicles',
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
                    '${(region.monthlyLitres / 1000).toStringAsFixed(1)}K L',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${region.litresPerVehicle.toStringAsFixed(1)} L/veh',
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(region.demandSatisfaction * 100).toStringAsFixed(0)}% demand met',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${region.avgWaitMinutes.toStringAsFixed(0)} min avg wait',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
