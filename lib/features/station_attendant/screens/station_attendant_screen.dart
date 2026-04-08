import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../notifications/providers/geofence_provider.dart';
import '../providers/station_attendant_provider.dart';
import '../widgets/time_slot_section.dart';

class StationAttendantScreen extends ConsumerStatefulWidget {
  const StationAttendantScreen({super.key});

  @override
  ConsumerState<StationAttendantScreen> createState() => _StationAttendantScreenState();
}

class _StationAttendantScreenState extends ConsumerState<StationAttendantScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _showSummarySheet(
      BuildContext context,
      ({int total, int completed, int pending, int noShow}) stats,
      List<BookingModel> bookings) {
    final completionRate = stats.total == 0 ? 0.0 : stats.completed / stats.total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('End-of-Day Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _SummaryRow(icon: Icons.directions_car_rounded, label: 'Total Bookings', value: '${stats.total}', color: AppColors.primary),
            _SummaryRow(icon: Icons.check_circle_rounded, label: 'Completed', value: '${stats.completed}', color: AppColors.success),
            _SummaryRow(icon: Icons.hourglass_bottom_rounded, label: 'Pending', value: '${stats.pending}', color: AppColors.warning),
            _SummaryRow(icon: Icons.cancel_rounded, label: 'No-Show', value: '${stats.noShow}', color: AppColors.error),
            const Divider(height: 28),
            Row(
              children: [
                const Text('Completion Rate', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  '${(completionRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: completionRate >= 0.8 ? AppColors.success : completionRate >= 0.5 ? AppColors.warning : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completionRate, minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 0.8 ? AppColors.success : completionRate >= 0.5 ? AppColors.warning : AppColors.error,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alert History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                child: Center(child: Text('No alerts yet', style: TextStyle(color: AppColors.textLight))),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = history[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sensors, color: AppColors.primary, size: 18),
                      ),
                      title: Text(a.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${a.fuelType} · ${a.distanceMetres.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: Text(DateFormat('HH:mm').format(a.triggeredAt), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Geofence Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Notifications', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                  Switch(
                    value: ref.read(notificationsEnabledProvider),
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      ref.read(notificationsEnabledProvider.notifier).state = v;
                      setSheet(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Alert Radius', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [50.0, 100.0, 150.0, 200.0].map((r) {
                  final selected = ref.read(geofenceRadiusProvider) == r;
                  return GestureDetector(
                    onTap: () {
                      ref.read(geofenceRadiusProvider.notifier).state = r;
                      setSheet(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(
                        '${r.toStringAsFixed(0)}m',
                        style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final stats = ref.watch(bookingStatsProvider);
    final bookingsAsync = ref.watch(stationBookingsProvider);
    final allBookings = bookingsAsync.valueOrNull ?? [];
    final grouped = ref.watch(groupedBookingsProvider);
    final activeFilter = ref.watch(bookingFilterProvider);
    final filterNotifier = ref.read(bookingFilterProvider.notifier);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    ref.watch(geofenceMonitorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 24, left: 24, right: 24,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          userAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (user) => Text(
                              user?.name ?? 'Attendant',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAlertHistory(context, ref),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                                if (ref.watch(geofenceHistoryProvider).isNotEmpty)
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showGeofenceSettings(context, ref),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              notificationsEnabled ? Icons.sensors : Icons.sensors_off_outlined,
                              color: Colors.white, size: 20,
                            ),
                          ),
                        ),
                      ],
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
                    DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  children: [
                    _StatCard(label: 'Total', value: stats.total, color: AppColors.primary, isActive: activeFilter == BookingFilter.all, onTap: () => filterNotifier.state = BookingFilter.all),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Done', value: stats.completed, color: AppColors.success, isActive: activeFilter == BookingFilter.completed, onTap: () => filterNotifier.state = BookingFilter.completed),
                    const SizedBox(width: 8),
                    _StatCard(label: 'Pending', value: stats.pending, color: AppColors.warning, isActive: activeFilter == BookingFilter.pending, onTap: () => filterNotifier.state = BookingFilter.pending),
                    const SizedBox(width: 8),
                    _StatCard(label: 'No-Show', value: stats.noShow, color: AppColors.error, isActive: activeFilter == BookingFilter.noShow, onTap: () => filterNotifier.state = BookingFilter.noShow),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by vehicle number...',
                      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
                      suffixIcon: ref.watch(bookingSearchProvider).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textLight),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(bookingSearchProvider.notifier).state = '';
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                    onChanged: (v) => ref.read(bookingSearchProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => context.push('/vehicle-lookup'),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showSummarySheet(context, stats, allBookings),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Booking list
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
              data: (_) => grouped.isEmpty
                  ? _EmptyState(dateLabel: dateLabel)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final slot = grouped.keys.elementAt(i);
                        return TimeSlotSection(slotLabel: slot, bookings: grouped[slot]!);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.value, required this.color, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: isActive ? Border.all(color: Colors.white.withValues(alpha: 0.4)) : null,
          ),
          child: Column(
            children: [
              Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String dateLabel;
  const _EmptyState({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.event_available_rounded, size: 32, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 16),
          const Text('No bookings for today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(dateLabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
