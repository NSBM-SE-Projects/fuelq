import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/providers/booking_provider.dart';
import 'booking_card.dart';

class TimeSlotSection extends ConsumerStatefulWidget {
  const TimeSlotSection({
    super.key,
    required this.slotLabel,
    required this.bookings,
  });

  final String slotLabel;
  final List<BookingModel> bookings;

  @override
  ConsumerState<TimeSlotSection> createState() => _TimeSlotSectionState();
}

class _TimeSlotSectionState extends ConsumerState<TimeSlotSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdownLabel() {
    if (widget.bookings.isEmpty) return '';
    final slotTime = widget.bookings.first.slotStart;
    final slotStart =
        DateTime(slotTime.year, slotTime.month, slotTime.day, slotTime.hour);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final now = DateTime.now();

    if (now.isBefore(slotStart)) {
      final diff = slotStart.difference(now);
      final mins = diff.inMinutes;
      return mins < 60 ? 'in ${mins}m' : 'in ${diff.inHours}h';
    } else if (now.isBefore(slotEnd)) {
      return 'Active now';
    } else {
      return 'Ended';
    }
  }

  Future<void> _showLitresDialog(BuildContext context, WidgetRef ref, BookingModel b, String attendantId) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispense Fuel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${b.vehicleNumber} — ${b.fuelType[0].toUpperCase()}${b.fuelType.substring(1)}',
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
              await ref.read(bookingServiceProvider).scanBooking(
                    bookingId: b.id,
                    attendantId: attendantId,
                    litresDispensed: litres,
                  );
            },
            child: const Text('Dispense', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmNoShow(BuildContext context, BookingModel booking) {
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
              ref
                  .read(firestoreProvider)
                  .collection('bookings')
                  .doc(booking.id)
                  .update({'status': BookingStatus.noShow.name});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${booking.vehicleNumber} marked as no-show'),
                  backgroundColor: AppColors.warning,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () => ref
                        .read(firestoreProvider)
                        .collection('bookings')
                        .doc(booking.id)
                        .update({
                      'status': BookingStatus.upcoming.name,
                      'qrUsed': false,
                      'scannedBy': null,
                      'scannedAt': null,
                    }),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = widget.bookings;
    final petrolCount =
        bookings.where((b) => b.fuelType == 'petrol').length;
    final dieselCount =
        bookings.where((b) => b.fuelType == 'diesel').length;
    final completedCount =
        bookings.where((b) => b.status == BookingStatus.completed).length;
    final countdown = _countdownLabel();
    final isActive = countdown == 'Active now';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary.withValues(alpha: 0.08),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.schedule,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                widget.slotLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              if (countdown.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    countdown,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              const Spacer(),
              _SlotTag('${bookings.length} vehicles'),
              if (petrolCount > 0) ...[
                const SizedBox(width: 6),
                _SlotTag('P:$petrolCount',
                    color: Colors.orange.shade700),
              ],
              if (dieselCount > 0) ...[
                const SizedBox(width: 6),
                _SlotTag('D:$dieselCount',
                    color: AppColors.success),
              ],
            ],
          ),
        ),
        LinearProgressIndicator(
          value: bookings.isEmpty
              ? 0
              : completedCount / bookings.length,
          backgroundColor: AppColors.divider,
          color: AppColors.success,
          minHeight: 3,
        ),
        ...bookings.map((b) {
          final isDone = b.status == BookingStatus.completed ||
              b.status == BookingStatus.noShow;

          return Dismissible(
            key: Key('${b.id}_${b.status.name}'),
            direction: isDone
                ? DismissDirection.none
                : DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                HapticFeedback.mediumImpact();
                final user = ref.read(userProvider).valueOrNull;
                if (user != null && b.status == BookingStatus.upcoming) {
                  await _showLitresDialog(context, ref, b, user.uid);
                }
              } else {
                _confirmNoShow(context, b);
              }
              return false;
            },
            background: _SwipeBackground(
              alignment: Alignment.centerLeft,
              color: AppColors.success,
              icon: Icons.check_circle_outline,
              label: 'Complete',
              padding: const EdgeInsets.only(left: 28),
            ),
            secondaryBackground: const _SwipeBackground(
              alignment: Alignment.centerRight,
              color: Colors.red,
              icon: Icons.cancel_outlined,
              label: 'No-Show',
              padding: EdgeInsets.only(right: 28),
            ),
            child: BookingCard(booking: b),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
    required this.padding,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTag extends StatelessWidget {
  const _SlotTag(this.text, {this.color = Colors.black54});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
