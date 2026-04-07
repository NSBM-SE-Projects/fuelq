import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/quota_model.dart';
import '../providers/quota_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final quotas = ref.watch(quotasProvider);
    final summary = ref.watch(quotaSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('User profile not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with greeting + quota ring
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 28,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
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
                        _roleLabel(user.role.name),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quota ring
                    Center(
                      child: _QuotaRing(
                        usagePercent: summary.usagePercent,
                        remaining: summary.totalRemaining,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Summary stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HeaderStat(label: 'Weekly Limit', value: '${summary.totalLimit.toStringAsFixed(0)}L'),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        _HeaderStat(label: 'Used', value: '${summary.totalUsed.toStringAsFixed(1)}L'),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        _HeaderStat(label: 'Vehicles', value: '${summary.vehicleCount}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Vehicle quota cards
              Expanded(
                child: quotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_gas_station_outlined, size: 32, color: AppColors.primaryLight),
                            ),
                            const SizedBox(height: 16),
                            const Text('No quota data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Register a vehicle to view your fuel quota', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => context.push('/add-vehicle', extra: {'uid': user.uid, 'isFirstTime': false}),
                              child: const Text('Register a Vehicle'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (quotas.isNotEmpty)
                              _WeekInfoCard(
                                weekStart: quotas.first.weekStart,
                                weekEnd: quotas.first.weekEnd,
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Vehicle Quotas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 14),
                            ...quotas.map((q) => _VehicleQuotaCard(quota: q)),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'vehicleOwner': return 'Vehicle Owner';
      case 'stationAttendant': return 'Station Attendant';
      case 'governmentAdmin': return 'Government Admin';
      default: return role;
    }
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

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

class _QuotaRing extends StatelessWidget {
  final double usagePercent;
  final double remaining;

  const _QuotaRing({required this.usagePercent, required this.remaining});

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
              Text(
                '${remaining.toStringAsFixed(0)}L',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                'remaining',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
              ),
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

    final sweepAngle = 2 * pi * (1 - usagePercent);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.usagePercent != usagePercent;
}

class _WeekInfoCard extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const _WeekInfoCard({required this.weekStart, required this.weekEnd});

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
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
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

class _VehicleQuotaCard extends StatelessWidget {
  final QuotaModel quota;

  const _VehicleQuotaCard({required this.quota});

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
