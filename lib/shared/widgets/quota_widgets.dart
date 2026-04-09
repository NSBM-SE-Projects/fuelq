import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/dashboard/models/quota_model.dart';

class QuotaRing extends StatelessWidget {
  final double usagePercent;
  final double remaining;

  const QuotaRing({super.key, required this.usagePercent, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140, height: 140,
      child: CustomPaint(
        painter: _RingPainter(usagePercent: usagePercent),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${remaining.toStringAsFixed(0)}L', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('remaining', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double usagePercent;

  _RingPainter({required this.usagePercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (usagePercent >= 0.9) {
      progressPaint.color = AppColors.error;
    } else if (usagePercent >= 0.7) {
      progressPaint.color = AppColors.warning;
    } else {
      progressPaint.color = AppColors.success;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * (1 - usagePercent),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.usagePercent != usagePercent;
}

class HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const HeaderStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }
}

class WeekInfoCard extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeekInfoCard({super.key, required this.weekStart, required this.weekEnd});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final startStr = '${weekStart.day} ${months[weekStart.month - 1]}';
    final endStr = '${weekEnd.day} ${months[weekEnd.month - 1]}';
    final daysLeft = weekEnd.difference(DateTime.now()).inDays.clamp(0, 7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$startStr - $endStr', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                const Text('Current quota week', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: daysLeft <= 1 ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysLeft days left',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: daysLeft <= 1 ? AppColors.warning : AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleQuotaCard extends StatelessWidget {
  final QuotaModel quota;

  const VehicleQuotaCard({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final displayName = quota.nickname.isNotEmpty ? quota.nickname : quota.vehicleNumber;
    final fuelLabel = quota.fuelType[0].toUpperCase() + quota.fuelType.substring(1);

    Color statusColor;
    String statusLabel;
    if (quota.isExhausted) {
      statusColor = AppColors.error;
      statusLabel = 'Exhausted';
    } else if (quota.usagePercent >= 0.7) {
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
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${quota.vehicleNumber} \u00B7 $fuelLabel', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: quota.usagePercent,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuotaStat(icon: Icons.local_gas_station_rounded, label: 'Used', value: '${quota.used.toStringAsFixed(1)}L', color: AppColors.textSecondary),
              _QuotaStat(icon: Icons.water_drop_outlined, label: 'Remaining', value: '${quota.remaining.toStringAsFixed(1)}L', color: statusColor),
              _QuotaStat(icon: Icons.speed_rounded, label: 'Limit', value: '${quota.weeklyLimit.toStringAsFixed(0)}L', color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuotaStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ],
    );
  }
}
