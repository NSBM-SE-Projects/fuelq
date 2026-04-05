import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';

class _VehicleQuotaInfo {
  final String vehicleNumber;
  final String ownerName;
  final String fuelType;
  final double weeklyLimit;
  final double used;

  const _VehicleQuotaInfo({
    required this.vehicleNumber,
    required this.ownerName,
    required this.fuelType,
    required this.weeklyLimit,
    required this.used,
  });

  double get remaining => (weeklyLimit - used).clamp(0, weeklyLimit);
  double get usagePercent =>
      weeklyLimit > 0 ? (used / weeklyLimit).clamp(0, 1) : 0;
  bool get isExhausted => remaining <= 0;
}

// Derive mock quota from sample bookings
List<_VehicleQuotaInfo> _buildMockQuotas() {
  final bookings = BookingModel.sampleData;
  final Map<String, _VehicleQuotaInfo> map = {};
  for (final b in bookings) {
    if (map.containsKey(b.vehicleNumber)) continue;
    final limit = b.fuelType == 'Diesel' ? 32.0 : 16.0;
    final used = b.status == BookingStatus.completed ? b.litres : 0.0;
    map[b.vehicleNumber] = _VehicleQuotaInfo(
      vehicleNumber: b.vehicleNumber,
      ownerName: b.ownerName,
      fuelType: b.fuelType,
      weeklyLimit: limit,
      used: used,
    );
  }
  return map.values.toList();
}

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _vehicleResultsProvider = Provider<List<_VehicleQuotaInfo>>((ref) {
  final query = ref.watch(_searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return [];
  return _buildMockQuotas()
      .where((v) =>
          v.vehicleNumber.toLowerCase().contains(query) ||
          v.ownerName.toLowerCase().contains(query))
      .toList();
});

class VehicleLookupScreen extends ConsumerStatefulWidget {
  const VehicleLookupScreen({super.key});

  @override
  ConsumerState<VehicleLookupScreen> createState() =>
      _VehicleLookupScreenState();
}

class _VehicleLookupScreenState extends ConsumerState<VehicleLookupScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_vehicleResultsProvider);
    final query = ref.watch(_searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Vehicle Lookup',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by vehicle number or owner name',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _controller.clear();
                          ref
                              .read(_searchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? _EmptyPrompt()
                : results.isEmpty
                    ? _NoResults(query: query)
                    : ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        itemBuilder: (_, i) =>
                            _VehicleQuotaCard(info: results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Enter a vehicle number or owner name',
            style: TextStyle(fontSize: 15, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No vehicle found for "$query"',
            style: const TextStyle(fontSize: 15, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _VehicleQuotaCard extends StatelessWidget {
  final _VehicleQuotaInfo info;
  const _VehicleQuotaCard({required this.info});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    if (info.isExhausted) {
      statusColor = AppColors.error;
      statusLabel = 'Exhausted';
    } else if (info.usagePercent >= 0.7) {
      statusColor = AppColors.warning;
      statusLabel = 'Low';
    } else {
      statusColor = AppColors.success;
      statusLabel = 'Available';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.vehicleNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.ownerName} \u00B7 ${info.fuelType}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.usagePercent,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                label: 'Weekly Limit',
                value: '${info.weeklyLimit.toStringAsFixed(0)}L',
                color: AppColors.textSecondary,
              ),
              _Stat(
                label: 'Used',
                value: '${info.used.toStringAsFixed(1)}L',
                color: AppColors.textSecondary,
              ),
              _Stat(
                label: 'Remaining',
                value: '${info.remaining.toStringAsFixed(1)}L',
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }
}
