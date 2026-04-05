import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../notifications/models/geofence_alert_model.dart';
import '../../notifications/providers/geofence_provider.dart';
import '../../notifications/services/geofence_service.dart';
import '../../notifications/services/notification_service.dart';
import '../models/booking_model.dart';
import '../providers/station_attendant_provider.dart';
import '../widgets/time_slot_section.dart';
import 'qr_scanner_screen.dart';
import 'vehicle_lookup_screen.dart';

class StationAttendantScreen extends ConsumerStatefulWidget {
  const StationAttendantScreen({super.key});

  @override
  ConsumerState<StationAttendantScreen> createState() =>
      _StationAttendantScreenState();
}

class _StationAttendantScreenState
    extends ConsumerState<StationAttendantScreen> {
  static const _primaryColor = AppColors.primary;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSummarySheet(
      BuildContext context,
      ({int total, int completed, int pending, int noShow}) stats,
      List<BookingModel> bookings) {
    final petrolLitres = bookings
        .where((b) =>
            b.fuelType == 'Petrol' && b.status == BookingStatus.completed)
        .fold<double>(0, (s, b) => s + b.litres);
    final dieselLitres = bookings
        .where((b) =>
            b.fuelType == 'Diesel' && b.status == BookingStatus.completed)
        .fold<double>(0, (s, b) => s + b.litres);
    final totalLitres = petrolLitres + dieselLitres;
    final completionRate = stats.total == 0
        ? 0.0
        : stats.completed / stats.total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            const SizedBox(height: 16),
            const Text(
              'End-of-Day Summary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _SummaryRow(
                icon: Icons.directions_car,
                label: 'Total Bookings',
                value: '${stats.total}',
                color: _primaryColor),
            _SummaryRow(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '${stats.completed}',
                color: AppColors.success),
            _SummaryRow(
                icon: Icons.hourglass_bottom,
                label: 'Pending',
                value: '${stats.pending}',
                color: AppColors.warning),
            _SummaryRow(
                icon: Icons.cancel_outlined,
                label: 'No-Show',
                value: '${stats.noShow}',
                color: AppColors.error),
            const Divider(height: 28),
            _SummaryRow(
                icon: Icons.local_gas_station,
                label: 'Petrol Dispensed',
                value: '${petrolLitres.toStringAsFixed(1)}L',
                color: Colors.orange),
            _SummaryRow(
                icon: Icons.local_gas_station,
                label: 'Diesel Dispensed',
                value: '${dieselLitres.toStringAsFixed(1)}L',
                color: Colors.green),
            _SummaryRow(
                icon: Icons.water_drop,
                label: 'Total Fuel Dispensed',
                value: '${totalLitres.toStringAsFixed(1)}L',
                color: _primaryColor),
            const Divider(height: 28),
            Row(
              children: [
                const Text('Completion Rate',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  '${(completionRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: completionRate >= 0.8
                        ? AppColors.success
                        : completionRate >= 0.5
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completionRate,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 0.8
                      ? AppColors.success
                      : completionRate >= 0.5
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertHistory(BuildContext context, WidgetRef ref) {
    final history = ref.read(geofenceHistoryProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alert History',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ref.read(geofenceHistoryProvider.notifier).state = [];
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No alerts yet',
                      style: TextStyle(color: Colors.black45)),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = history[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sensors,
                            color: AppColors.primary, size: 18),
                      ),
                      title: Text(a.vehicleNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                          '${a.ownerName} · ${a.distanceMetres.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        DateFormat('HH:mm').format(a.triggeredAt),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showGeofenceSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Geofence Settings',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Notifications',
                      style: TextStyle(fontSize: 15)),
                  Switch(
                    value: ref.read(notificationsEnabledProvider),
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      ref.read(notificationsEnabledProvider.notifier).state =
                          v;
                      setSheet(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Alert Radius',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [50.0, 100.0, 150.0, 200.0].map((r) {
                  final selected = ref.read(geofenceRadiusProvider) == r;
                  return GestureDetector(
                    onTap: () {
                      ref.read(geofenceRadiusProvider.notifier).state = r;
                      GeofenceService.instance.updateRadius(r);
                      setSheet(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        '${r.toStringAsFixed(0)}m',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (_, ref, child) {
                  final distAsync = ref.watch(liveDistanceProvider);
                  final distance = distAsync.valueOrNull;
                  if (distance == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Current distance to station: ${distance.toStringAsFixed(0)}m',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(firestoreAlertsWatcherProvider);
    final stats = ref.watch(bookingStatsProvider);
    final allBookings = ref.watch(todayBookingsProvider);
    final grouped = ref.watch(groupedBookingsProvider);
    final activeFilter = ref.watch(bookingFilterProvider);
    final filterNotifier = ref.read(bookingFilterProvider.notifier);
    final geofenceAlerts = ref.watch(geofenceAlertsProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(now);

    final petrolDispensed = allBookings
        .where((b) =>
            b.fuelType == 'Petrol' && b.status == BookingStatus.completed)
        .fold<double>(0, (s, b) => s + b.litres);
    final dieselDispensed = allBookings
        .where((b) =>
            b.fuelType == 'Diesel' && b.status == BookingStatus.completed)
        .fold<double>(0, (s, b) => s + b.litres);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Dashboard',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Lanka CPC — Colombo 03',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Vehicle Lookup',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleLookupScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'End-of-Day Summary',
            onPressed: () => _showSummarySheet(context, stats, allBookings),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Alert History',
                  onPressed: () => _showAlertHistory(context, ref),
                ),
                if (ref.watch(geofenceHistoryProvider).isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(notificationsEnabled
                ? Icons.sensors
                : Icons.sensors_off_outlined),
            tooltip: 'Geofence Settings',
            onPressed: () => _showGeofenceSettings(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('EEEE').format(now),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(now),
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (geofenceAlerts.isNotEmpty) ...[
            ...geofenceAlerts.map((alert) => _GeofenceAlertBanner(
                  alert: alert,
                  onDismiss: () => dismissAlert(ref, alert.vehicleNumber),
                )),
            if (geofenceAlerts.length > 1)
              GestureDetector(
                onTap: () {
                  dismissAllAlerts(ref);
                  NotificationService.instance.cancelAll();
                },
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.85),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const Center(
                    child: Text(
                      'Dismiss all alerts',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              children: [
                _StatTile(
                  label: 'Total',
                  value: stats.total,
                  color: _primaryColor,
                  isActive: activeFilter == BookingFilter.all,
                  onTap: () => filterNotifier.state = BookingFilter.all,
                ),
                _StatTile(
                  label: 'Completed',
                  value: stats.completed,
                  color: Colors.green,
                  isActive: activeFilter == BookingFilter.completed,
                  onTap: () => filterNotifier.state = BookingFilter.completed,
                ),
                _StatTile(
                  label: 'Pending',
                  value: stats.pending,
                  color: Colors.orange,
                  isActive: activeFilter == BookingFilter.pending,
                  onTap: () => filterNotifier.state = BookingFilter.pending,
                ),
                _StatTile(
                  label: 'No-Show',
                  value: stats.noShow,
                  color: Colors.red,
                  isActive: activeFilter == BookingFilter.noShow,
                  onTap: () => filterNotifier.state = BookingFilter.noShow,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S FUEL STOCK",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _FuelBar(
                  label: 'Petrol',
                  dispensed: petrolDispensed,
                  capacity: 500,
                  color: Colors.orange,
                ),
                const SizedBox(height: 6),
                _FuelBar(
                  label: 'Diesel',
                  dispensed: dieselDispensed,
                  capacity: 300,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by vehicle or owner...',
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: Colors.black45),
                suffixIcon: ref.watch(bookingSearchProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: Colors.black45),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bookingSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  ref.read(bookingSearchProvider.notifier).state = v,
            ),
          ),
          // Booking list
          Expanded(
            child: grouped.isEmpty
                ? _EmptyState(dateLabel: dateLabel)
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: grouped.length,
                    itemBuilder: (context, i) {
                      final slot = grouped.keys.elementAt(i);
                      return TimeSlotSection(
                        slotLabel: slot,
                        bookings: grouped[slot]!,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'simulate',
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            tooltip: 'Simulate Vehicle Arrival',
            onPressed: () => simulateVehicleArrival(ref),
            child: const Icon(Icons.sensors),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'scan',
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: color.withValues(alpha: 0.4))
                : null,
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeofenceAlertBanner extends StatelessWidget {
  const _GeofenceAlertBanner({
    required this.alert,
    required this.onDismiss,
  });

  final GeofenceAlertModel alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1B5E20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sensors, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.vehicleNumber} is nearby!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${alert.ownerName} · ${alert.distanceMetres.toStringAsFixed(0)}m away · ${alert.litres.toStringAsFixed(0)}L ${alert.fuelType}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _FuelBar extends StatelessWidget {
  const _FuelBar({
    required this.label,
    required this.dispensed,
    required this.capacity,
    required this.color,
  });

  final String label;
  final double dispensed;
  final double capacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final remaining = (capacity - dispensed).clamp(0.0, capacity);
    final progress = (dispensed / capacity).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: Text(
            '${remaining.toStringAsFixed(0)}L left',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.dateLabel});
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No bookings for today',
            style: TextStyle(
                fontSize: 16,
                color: Colors.black45,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
