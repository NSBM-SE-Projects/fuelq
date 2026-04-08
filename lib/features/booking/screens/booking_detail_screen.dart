import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../../qr/providers/qr_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(bookingConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (cfg) => Column(
          children: [
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
              child: Row(
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
                  const SizedBox(width: 16),
                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // QR section
                    if (booking.status == BookingStatus.upcoming)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Show this QR at the station',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            QrImageView(
                              data: QrService.generatePayload(booking),
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(color: AppColors.primaryDark, eyeShape: QrEyeShape.circle),
                              dataModuleStyle: const QrDataModuleStyle(color: AppColors.primary, dataModuleShape: QrDataModuleShape.circle),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              booking.qrUsed ? 'QR Already Used' : 'Valid for this booking only',
                              style: TextStyle(
                                fontSize: 12,
                                color: booking.qrUsed ? AppColors.error : AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (booking.status == BookingStatus.upcoming)
                      const SizedBox(height: 20),

                    // Booking info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(icon: Icons.local_gas_station_rounded, label: 'Station', value: booking.stationName),
                          _InfoRow(icon: Icons.calendar_today_rounded, label: 'Date', value: _formatDate(booking.slotStart)),
                          _InfoRow(icon: Icons.access_time_rounded, label: 'Time Slot', value: booking.slotTimeLabel(cfg.slotDuration)),
                          _InfoRow(icon: Icons.directions_car_rounded, label: 'Vehicle', value: booking.vehicleNumber),
                          _InfoRow(icon: Icons.water_drop_rounded, label: 'Fuel Type', value: '${booking.fuelType[0].toUpperCase()}${booking.fuelType.substring(1)}'),
                          _InfoRow(
                            icon: Icons.info_outline_rounded,
                            label: 'Status',
                            value: _statusLabel(booking.status),
                            valueColor: _statusColor(booking.status),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cancel button for upcoming bookings
                    if (booking.status == BookingStatus.upcoming)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('This action cannot be undone. Your time slot will be released for others.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(bookingServiceProvider).cancelBooking(booking.id);
              if (context.mounted) context.pop();
            },
            child: const Text('Cancel Booking', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.expired: return 'Expired';
      case BookingStatus.noShow: return 'No Show';
    }
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.upcoming: return AppColors.primary;
      case BookingStatus.completed: return AppColors.success;
      case BookingStatus.cancelled: return AppColors.textLight;
      case BookingStatus.expired: return AppColors.warning;
      case BookingStatus.noShow: return AppColors.error;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
