import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../notifications/providers/geofence_provider.dart';
import '../models/booking_model.dart';
import '../providers/station_attendant_provider.dart';

class BookingCard extends ConsumerWidget {
  const BookingCard({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingsNotifierProvider.notifier);
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
        onTap: () => _showDetailSheet(context, notifier),
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
                      color: booking.fuelType == 'Petrol'
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
                            _FuelChip(booking.fuelType),
                            const Spacer(),
                            _StatusBadge(booking.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.ownerName,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.local_gas_station,
                                size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.litres.toStringAsFixed(0)}L',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              booking.isPrepaid
                                  ? Icons.credit_card
                                  : Icons.payments_outlined,
                              size: 14,
                              color: booking.isPrepaid
                                  ? AppColors.primary
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.isPrepaid ? 'Prepaid' : 'Cash',
                              style: TextStyle(
                                fontSize: 12,
                                color: booking.isPrepaid
                                    ? AppColors.primary
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons — only for active bookings
            if (!isDone)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    if (booking.status == BookingStatus.confirmed)
                      _ActionButton(
                        label: 'Mark Arrived',
                        icon: Icons.directions_car,
                        color: Colors.orange,
                        onTap: () => notifier.markArrived(booking.id),
                      ),
                    if (booking.status == BookingStatus.arrived)
                      _ActionButton(
                        label: 'Complete',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        onTap: () => notifier.markCompleted(booking.id),
                      ),
                    _ActionButton(
                      label: 'No-Show',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      onTap: () => _confirmNoShow(context, notifier),
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

  void _showDetailSheet(BuildContext context, BookingsNotifier notifier) {
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
                width: 40, height: 4,
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
                      Text(booking.ownerName,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                _StatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _DetailRow('Fuel Type', booking.fuelType),
            _DetailRow('Litres', '${booking.litres.toStringAsFixed(0)} L'),
            _DetailRow('Payment',
                booking.isPrepaid ? 'Prepaid' : 'Cash at pump'),
            _DetailRow('Booking ID', booking.id),
            _DetailRow('Slot Time',
                '${booking.slotTime.hour.toString().padLeft(2, '0')}:00 – ${(booking.slotTime.hour + 1).toString().padLeft(2, '0')}:00'),
            if (!isDone) ...[
              const SizedBox(height: 20),
              const Text('Manual Override',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (booking.status == BookingStatus.confirmed)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          notifier.markArrived(booking.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.directions_car, size: 16),
                        label: const Text('Mark Arrived'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange),
                      ),
                    ),
                  if (booking.status == BookingStatus.arrived) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          notifier.markCompleted(booking.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            size: 16),
                        label: const Text('Complete'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmNoShow(context, notifier);
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('No-Show'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmNoShow(BuildContext context, BookingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as No-Show?'),
        content: Text(
            '${booking.vehicleNumber} will be marked as a no-show. The slot will be released.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.markNoShow(booking.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
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
        color: (isPetrol ? Colors.orange : Colors.green).withValues(alpha: 0.12),
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
      BookingStatus.confirmed => ('Confirmed', Colors.blue),
      BookingStatus.arrived => ('Arrived', Colors.orange),
      BookingStatus.completed => ('Completed', Colors.green),
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
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
