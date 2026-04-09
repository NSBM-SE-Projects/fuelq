import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// One bar's worth of data.
class BarData {
  final String label;
  final double value;
  const BarData(this.label, this.value);
}

/// Custom bar chart shared by the admin analytics screens.
/// - [valueFormatter] formats the small label above each bar.
/// - [compact] tightens spacing and hides the per-bar value labels.
class AnalyticsBarChart extends StatelessWidget {
  final List<BarData> bars;
  final Color color;
  final String Function(double) valueFormatter;
  final bool compact;

  const AnalyticsBarChart({
    super.key,
    required this.bars,
    required this.color,
    required this.valueFormatter,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final ratio = maxVal > 0 ? bar.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!compact)
                    Text(
                      valueFormatter(bar.value),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: (140 * ratio).clamp(4.0, 140.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          color,
                          color.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bar.label,
                    style: TextStyle(
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
