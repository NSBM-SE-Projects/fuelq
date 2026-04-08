import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// White rounded container with a title + subtitle and arbitrary [child] body.
/// Used to wrap charts on the admin analytics screens.
class AnalyticsChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
