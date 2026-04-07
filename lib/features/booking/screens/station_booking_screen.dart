import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/vehicle_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../map/models/station_model.dart';
import '../providers/booking_provider.dart';

class StationBookingScreen extends ConsumerStatefulWidget {
  final StationModel station;
  const StationBookingScreen({super.key, required this.station});

  @override
  ConsumerState<StationBookingScreen> createState() => _StationBookingScreenState();
}

class _StationBookingScreenState extends ConsumerState<StationBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  VehicleModel? _selectedVehicle;

  List<DateTime> get _dates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  List<String> _generateSlots(int durationMinutes) {
    final open = _parseTime(widget.station.openTime);
    final close = _parseTime(widget.station.closeTime);
    final slots = <String>[];
    var current = open;
    while (current + durationMinutes <= close) {
      final h = (current ~/ 60).toString().padLeft(2, '0');
      final m = (current % 60).toString().padLeft(2, '0');
      slots.add('$h:$m');
      current += durationMinutes;
    }
    return slots;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _goToPayment() {
    if (_selectedVehicle == null || _selectedSlot == null) return;

    final parts = _selectedSlot!.split(':');
    final slotStart = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    final litres = _selectedVehicle!.fuelType.name == 'diesel' ? 30.0 : 16.0;
    context.push('/payment', extra: {
      'stationId': widget.station.id,
      'stationName': widget.station.name,
      'vehicleId': _selectedVehicle!.id,
      'vehicleNumber': _selectedVehicle!.vehicleNumber,
      'fuelType': _selectedVehicle!.fuelType.name,
      'slotStart': slotStart,
      'litresBooked': litres,
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(bookingConfigProvider);
    final vehicles = ref.watch(vehiclesProvider);
    final slotCounts = ref.watch(slotCountsProvider(
      (stationId: widget.station.id, date: _selectedDate),
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cfg) {
          final slots = _generateSlots(cfg.slotDurationMinutes);
          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 20, left: 24, right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.station.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.station.address,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date selector
                      const Text(
                        'Select Date',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _dates.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final date = _dates[i];
                            final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _selectedSlot = null;
                              }),
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Time slots
                      const Text(
                        'Select Time Slot',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      slotCounts.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                        data: (counts) => Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: slots.map((slot) {
                            final count = counts[slot] ?? 0;
                            final isFull = count >= cfg.maxVehiclesPerSlot;
                            final isSelected = _selectedSlot == slot;
                            final slotParts = slot.split(':');
                            final slotDateTime = DateTime(
                              _selectedDate.year, _selectedDate.month, _selectedDate.day,
                              int.parse(slotParts[0]), int.parse(slotParts[1]),
                            );
                            final isPast = slotDateTime.isBefore(DateTime.now());
                            final isDisabled = isFull || isPast;
                            return GestureDetector(
                              onTap: isDisabled ? null : () => setState(() => _selectedSlot = slot),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? AppColors.divider.withValues(alpha: 0.5)
                                      : isFull
                                          ? AppColors.error.withValues(alpha: 0.1)
                                          : isSelected ? AppColors.primary : AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPast
                                        ? AppColors.divider
                                        : isFull
                                            ? AppColors.error
                                            : isSelected ? AppColors.primary : AppColors.success,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: isPast
                                            ? AppColors.textLight
                                            : isFull
                                                ? AppColors.error
                                                : isSelected ? Colors.white : AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      isPast ? 'Passed' : isFull ? 'Full' : '${cfg.maxVehiclesPerSlot - count} left',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPast
                                            ? AppColors.textLight
                                            : isFull
                                                ? AppColors.error
                                                : isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Vehicle selector
                      const Text(
                        'Select Vehicle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      vehicles.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                        data: (list) => Column(
                          children: list.map((v) {
                            final isSelected = _selectedVehicle?.id == v.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedVehicle = v),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car_rounded,
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.nickname.isNotEmpty ? v.nickname : v.vehicleNumber,
                                            style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w700,
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${v.vehicleNumber} · ${v.fuelType.name[0].toUpperCase()}${v.fuelType.name.substring(1)}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Book button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_selectedSlot != null && _selectedVehicle != null)
                        ? _goToPayment : null,
                    child: const Text('Continue to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
