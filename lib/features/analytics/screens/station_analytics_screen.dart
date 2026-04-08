import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/analytics_summary_model.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/analytics_stat_card.dart';

enum _StationSort { volume, efficiency, wait, transactions }
enum _StationStatus { all, overbookedOnly, healthyOnly }

class StationAnalyticsScreen extends ConsumerStatefulWidget {
  const StationAnalyticsScreen({super.key});

  @override
  ConsumerState<StationAnalyticsScreen> createState() =>
      _StationAnalyticsScreenState();
}

class _StationAnalyticsScreenState
    extends ConsumerState<StationAnalyticsScreen> {
  String _region = 'All';
  _StationSort _sort = _StationSort.volume;
  _StationStatus _status = _StationStatus.all;

  bool get _hasFilter =>
      _region != 'All' ||
      _sort != _StationSort.volume ||
      _status != _StationStatus.all;

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Station Analytics'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (_hasFilter)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _openFilterSheet(stationsAsync.valueOrNull ?? []),
          ),
        ],
      ),
      body: stationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stations) {
          if (stations.isEmpty) {
            return const Center(child: Text('No station data available.'));
          }

          // Apply filters
          Iterable<StationAnalytics> filtered = stations;
          if (_region != 'All') {
            filtered = filtered.where((s) => s.region == _region);
          }
          if (_status == _StationStatus.overbookedOnly) {
            filtered = filtered.where((s) => s.isOverbooked);
          } else if (_status == _StationStatus.healthyOnly) {
            filtered = filtered.where((s) => !s.isOverbooked);
          }
          final filteredList = filtered.toList();

          if (filteredList.isEmpty) {
            return _EmptyFilterState(onClear: _clearFilters);
          }

          // Sorted lists
          final byEfficiency = [...filteredList]
            ..sort((a, b) => b.efficiencyScore.compareTo(a.efficiencyScore));
          final overbooked = filteredList.where((s) => s.isOverbooked).toList()
            ..sort((a, b) => b.demandRatio.compareTo(a.demandRatio));

          final sorted = [...filteredList];
          switch (_sort) {
            case _StationSort.volume:
              sorted.sort((a, b) => b.monthlyLitres.compareTo(a.monthlyLitres));
              break;
            case _StationSort.efficiency:
              sorted.sort(
                (a, b) => b.efficiencyScore.compareTo(a.efficiencyScore),
              );
              break;
            case _StationSort.wait:
              sorted.sort(
                (a, b) => a.avgWaitMinutes.compareTo(b.avgWaitMinutes),
              );
              break;
            case _StationSort.transactions:
              sorted.sort(
                (a, b) =>
                    b.monthlyTransactions.compareTo(a.monthlyTransactions),
              );
              break;
          }
          final byVolume = sorted;
          final stationsForStats = filteredList;
          final stationsList = stationsForStats; // alias for stats below

          final totalMonthly =
              stationsList.fold<double>(0, (sum, s) => sum + s.monthlyLitres);
          final totalTransactions = stationsList.fold<int>(
            0,
            (sum, s) => sum + s.monthlyTransactions,
          );
          final avgEfficiency = stationsList.isEmpty
              ? 0.0
              : stationsList.fold<double>(
                    0,
                    (sum, s) => sum + s.efficiencyScore,
                  ) /
                  stationsList.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasFilter) ...[
                  _ActiveFilterBar(
                    region: _region,
                    sort: _sortLabel(_sort),
                    status: _statusLabel(_status),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                ],
                // Top stats
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Active Stations',
                      value: stationsList.length.toString(),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.water_drop_rounded,
                      label: 'Monthly Volume',
                      value: '${(totalMonthly / 1000).toStringAsFixed(0)}K L',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnalyticsStatCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transactions',
                      value: _formatNumber(totalTransactions),
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    AnalyticsStatCard(
                      icon: Icons.speed_rounded,
                      label: 'Avg Efficiency',
                      value: '${avgEfficiency.toStringAsFixed(0)}%',
                      color: AppColors.primarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Overbooked alert
                if (overbooked.isNotEmpty) ...[
                  AnalyticsSectionHeader(
                    title: 'Overbooked Stations',
                    subtitle: '${overbooked.length} stations exceed capacity',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  ...overbooked.map(
                    (s) => _OverbookedCard(station: s),
                  ),
                  const SizedBox(height: 24),
                ],

                // Top by efficiency
                AnalyticsSectionHeader(
                  title: 'Top Performers',
                  subtitle: 'Ranked by efficiency score',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                ...byEfficiency.take(3).toList().asMap().entries.map(
                      (e) => _RankedCard(rank: e.key + 1, station: e.value),
                    ),
                const SizedBox(height: 24),

                // All stations by volume
                AnalyticsSectionHeader(
                  title: 'All Stations',
                  subtitle: 'By ${_sortLabel(_sort).toLowerCase()}',
                  icon: Icons.format_list_numbered_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                ...byVolume.map((s) => _StationListItem(station: s)),
              ],
            ),
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

  String _sortLabel(_StationSort s) {
    switch (s) {
      case _StationSort.volume:
        return 'Monthly volume';
      case _StationSort.efficiency:
        return 'Efficiency score';
      case _StationSort.wait:
        return 'Shortest wait';
      case _StationSort.transactions:
        return 'Transactions';
    }
  }

  String _statusLabel(_StationStatus s) {
    switch (s) {
      case _StationStatus.all:
        return 'All';
      case _StationStatus.overbookedOnly:
        return 'Overbooked';
      case _StationStatus.healthyOnly:
        return 'Healthy';
    }
  }

  void _clearFilters() {
    setState(() {
      _region = 'All';
      _sort = _StationSort.volume;
      _status = _StationStatus.all;
    });
  }

  void _openFilterSheet(List<StationAnalytics> all) {
    final regions = <String>{'All', ...all.map((s) => s.region)}.toList();
    String tempRegion = _region;
    _StationSort tempSort = _sort;
    _StationStatus tempStatus = _status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _FilterLabel('Region'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: regions
                        .map(
                          (r) => _ChipButton(
                            label: r,
                            selected: tempRegion == r,
                            onTap: () => setSheetState(() => tempRegion = r),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const _FilterLabel('Status'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipButton(
                        label: 'All',
                        selected: tempStatus == _StationStatus.all,
                        onTap: () => setSheetState(
                          () => tempStatus = _StationStatus.all,
                        ),
                      ),
                      _ChipButton(
                        label: 'Overbooked only',
                        selected: tempStatus == _StationStatus.overbookedOnly,
                        onTap: () => setSheetState(
                          () => tempStatus = _StationStatus.overbookedOnly,
                        ),
                      ),
                      _ChipButton(
                        label: 'Healthy only',
                        selected: tempStatus == _StationStatus.healthyOnly,
                        onTap: () => setSheetState(
                          () => tempStatus = _StationStatus.healthyOnly,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _FilterLabel('Sort by'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _StationSort.values
                        .map(
                          (s) => _ChipButton(
                            label: _sortLabel(s),
                            selected: tempSort == s,
                            onTap: () => setSheetState(() => tempSort = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              tempRegion = 'All';
                              tempSort = _StationSort.volume;
                              tempStatus = _StationStatus.all;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _region = tempRegion;
                              _sort = tempSort;
                              _status = tempStatus;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Filter UI helpers ──────────────────────────────────

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      );
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  final String region;
  final String sort;
  final String status;
  final VoidCallback onClear;
  const _ActiveFilterBar({
    required this.region,
    required this.sort,
    required this.status,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$region · $status · $sort',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyFilterState({required this.onClear});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No stations match the filters',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────


// ─── Section Header ─────────────────────────────────────


// ─── Overbooked Card ────────────────────────────────────

class _OverbookedCard extends StatelessWidget {
  final StationAnalytics station;

  const _OverbookedCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final overload = ((station.demandRatio - 1) * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
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
                  station.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${station.region} \u00B7 ${station.currentDemand}L demand / ${station.capacity}L capacity',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$overload%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ranked Card ────────────────────────────────────────

class _RankedCard extends StatelessWidget {
  final int rank;
  final StationAnalytics station;

  const _RankedCard({required this.rank, required this.station});

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
      child: Row(
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
                  station.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${station.region} \u00B7 ${station.avgWaitMinutes.toStringAsFixed(0)} min wait \u00B7 ${(station.noShowRate * 100).toStringAsFixed(0)}% no-show',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${station.efficiencyScore.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Station List Item ──────────────────────────────────

class _StationListItem extends StatelessWidget {
  final StationAnalytics station;

  const _StationListItem({required this.station});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
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
                    Icons.local_gas_station_rounded,
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
                        station.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.region,
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
                      '${(station.monthlyLitres / 1000).toStringAsFixed(1)}K L',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${station.monthlyTransactions} txns',
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
            // Capacity bar
            _CapacityBar(
              dispensed: station.dispensedToday,
              capacity: station.capacity,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              station.region,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(
              label: 'Monthly Volume',
              value: '${(station.monthlyLitres / 1000).toStringAsFixed(1)}K L',
            ),
            _DetailRow(
              label: 'Petrol',
              value: '${(station.petrolLitres / 1000).toStringAsFixed(1)}K L',
            ),
            _DetailRow(
              label: 'Diesel',
              value: '${(station.dieselLitres / 1000).toStringAsFixed(1)}K L',
            ),
            _DetailRow(
              label: 'Monthly Transactions',
              value: station.monthlyTransactions.toString(),
            ),
            _DetailRow(
              label: 'Avg Wait Time',
              value: '${station.avgWaitMinutes.toStringAsFixed(0)} min',
            ),
            _DetailRow(
              label: 'No-Show Rate',
              value: '${(station.noShowRate * 100).toStringAsFixed(1)}%',
            ),
            _DetailRow(
              label: 'Efficiency Score',
              value: '${station.efficiencyScore.toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final int dispensed;
  final int capacity;

  const _CapacityBar({required this.dispensed, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio =
        capacity > 0 ? (dispensed / capacity).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (ratio < 0.6) {
      barColor = AppColors.success;
    } else if (ratio < 0.85) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Capacity used today',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$dispensed / $capacity L',
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
              Container(
                height: 6,
                color: AppColors.divider,
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
      ),
    );
  }
}
