import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/providers/booking_provider.dart';
import '../../notifications/providers/geofence_provider.dart';

class BookingCard extends ConsumerWidget {
  const BookingCard({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.noShow;
    final highlightedVehicle = ref.watch(highlightedVehicleProvider);
    final isHighlighted = highlightedVehicle == booking.vehicleNumber;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isHighlighted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isHighlighted
            ? const BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetailSheet(context, ref),
        child: Opacity(
          opacity: isDone ? 0.6 : 1.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 54,
                      decoration: BoxDecoration(
                        color: booking.fuelType == 'petrol'
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                booking.vehicleNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FuelChip('${booking.fuelType[0].toUpperCase()}${booking.fuelType.substring(1)}'),
                              const Spacer(),
                              _StatusBadge(booking.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm').format(booking.slotStart),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.local_gas_station,
                                  size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                booking.stationName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons — only for upcoming bookings
              if (!isDone && booking.status == BookingStatus.upcoming)
                Container(
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      _ActionButton(
                        label: 'Complete',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        onTap: () => _markCompleted(context, ref),
                      ),
                      _ActionButton(
                        label: 'No-Show',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                        onTap: () => _confirmNoShow(context, ref),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _markCompleted(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispense Fuel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${booking.vehicleNumber} — ${booking.fuelType[0].toUpperCase()}${booking.fuelType.substring(1)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Litres to dispense',
                suffixText: 'L',
                prefixIcon: const Icon(Icons.water_drop_rounded, color: AppColors.primarySoft),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final litres = double.tryParse(controller.text.trim()) ?? 0;
              if (litres <= 0) return;
              Navigator.pop(ctx);
              final user = ref.read(userProvider).valueOrNull;
              if (user == null) return;
              try {
                await ref.read(bookingServiceProvider).scanBooking(
                      bookingId: booking.id,
                      attendantId: user.uid,
                      litresDispensed: litres,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Dispense', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _markNoShow(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(firestoreProvider)
          .collection('bookings')
          .doc(booking.id)
          .update({'status': BookingStatus.noShow.name});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _revertToUpcoming(WidgetRef ref) async {
    await ref
        .read(firestoreProvider)
        .collection('bookings')
        .doc(booking.id)
        .update({
      'status': BookingStatus.upcoming.name,
      'qrUsed': false,
      'scannedBy': null,
      'scannedAt': null,
    });
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    final isDone = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.noShow;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.vehicleNumber,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(booking.stationName,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _StatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _DetailRow('Fuel Type', '${booking.fuelType[0].toUpperCase()}${booking.fuelType.substring(1)}'),
            _DetailRow('Station', booking.stationName),
            _DetailRow('Booking ID', booking.id),
            _DetailRow(
                'Slot Time',
                '${booking.slotStart.hour.toString().padLeft(2, '0')}:${booking.slotStart.minute.toString().padLeft(2, '0')}'),
            _DetailRow('QR Used', booking.qrUsed ? 'Yes' : 'No'),
            if (booking.status == BookingStatus.upcoming) ...[
              const SizedBox(height: 20),
              const Text('Manual Override',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _markCompleted(context, ref);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Complete'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmNoShow(context, ref);
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('No-Show'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
            if (isDone) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _revertToUpcoming(ref);
                  },
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Revert to Upcoming'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmNoShow(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as No-Show?'),
        content: Text(
            '${booking.vehicleNumber} will be marked as a no-show. The slot will be released.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markNoShow(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(foregroundColor: color),
      ),
    );
  }
}

class _FuelChip extends StatelessWidget {
  const _FuelChip(this.fuelType);
  final String fuelType;

  @override
  Widget build(BuildContext context) {
    final isPetrol = fuelType == 'Petrol';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            (isPetrol ? Colors.orange : Colors.green).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        fuelType,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPetrol ? Colors.orange.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.upcoming => ('Upcoming', Colors.blue),
      BookingStatus.completed => ('Completed', Colors.green),
      BookingStatus.cancelled => ('Cancelled', Colors.grey),
      BookingStatus.expired => ('Expired', Colors.grey),
      BookingStatus.noShow => ('No-Show', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
