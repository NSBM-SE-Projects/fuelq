import 'dart:math' as math;

/// Recommended action for the national fuel quota.
enum SuggestionAction { reduce, hold, increase }

class QuotaSuggestion {
  final SuggestionAction action;
  final double suggestedWeeklyQuota; // litres
  final double changePercent; // signed; negative = reduce
  final String headline;
  final String reason;
  final double confidence; // 0..1

  const QuotaSuggestion({
    required this.action,
    required this.suggestedWeeklyQuota,
    required this.changePercent,
    required this.headline,
    required this.reason,
    required this.confidence,
  });
}

/// Pure rule-based engine. Same call works on mock or real Firestore data —
/// it only needs three numeric inputs.
class QuotaSuggestionEngine {
  /// Below this average utilization, recommend reducing.
  static const double _reduceThreshold = 0.85;

  /// Above this average utilization, recommend increasing.
  static const double _increaseThreshold = 0.95;

  /// Headroom kept when reducing (never cut all the way to current demand).
  static const double _safetyBuffer = 0.05;

  /// Maximum cut allowed in a single recommendation.
  static const double _maxCut = 0.30;

  /// Standard deviation considered "fully unstable" (caps confidence to 0).
  static const double _stdCeiling = 0.10;

  static QuotaSuggestion compute({
    required double allocatedWeekly,
    required double usedWeekly,
    required List<double> historicalUtilization,
  }) {
    if (allocatedWeekly <= 0) {
      return const QuotaSuggestion(
        action: SuggestionAction.hold,
        suggestedWeeklyQuota: 0,
        changePercent: 0,
        headline: 'Insufficient data',
        reason: 'No allocation data is available to compute a recommendation.',
        confidence: 0,
      );
    }

    final currentUtil = (usedWeekly / allocatedWeekly).clamp(0.0, 2.0);
    final history = historicalUtilization.isEmpty
        ? <double>[currentUtil]
        : historicalUtilization;

    final avgUtil = history.reduce((a, b) => a + b) / history.length;

    // Stability via population standard deviation.
    double stability = 1.0;
    if (history.length >= 2) {
      final mean = avgUtil;
      final variance =
          history.map((u) => (u - mean) * (u - mean)).reduce((a, b) => a + b) /
              history.length;
      final std = math.sqrt(variance);
      stability = (1 - (std / _stdCeiling)).clamp(0.0, 1.0);
    }

    if (avgUtil < _reduceThreshold) {
      final surplusRate = 1 - avgUtil;
      final cut = (surplusRate - _safetyBuffer).clamp(0.0, _maxCut);
      final newQuota = allocatedWeekly * (1 - cut);
      return QuotaSuggestion(
        action: SuggestionAction.reduce,
        suggestedWeeklyQuota: newQuota,
        changePercent: -cut * 100,
        headline: 'Reduce allocation',
        reason:
            '4-week average utilization is ${(avgUtil * 100).toStringAsFixed(1)}%, '
            'leaving a ${(surplusRate * 100).toStringAsFixed(1)}% surplus. '
            'Reducing by ${(cut * 100).toStringAsFixed(1)}% keeps a 5% safety '
            'buffer while still meeting demand.',
        confidence: stability,
      );
    }

    if (avgUtil > _increaseThreshold) {
      const increase = 0.10;
      final newQuota = allocatedWeekly * (1 + increase);
      return QuotaSuggestion(
        action: SuggestionAction.increase,
        suggestedWeeklyQuota: newQuota,
        changePercent: increase * 100,
        headline: 'Increase allocation',
        reason:
            'Utilization has averaged ${(avgUtil * 100).toStringAsFixed(1)}% '
            'over the last ${history.length} weeks, leaving very little headroom. '
            'Increasing allocation by 10% reduces shortage risk.',
        confidence: stability,
      );
    }

    return QuotaSuggestion(
      action: SuggestionAction.hold,
      suggestedWeeklyQuota: allocatedWeekly,
      changePercent: 0,
      headline: 'Hold current allocation',
      reason:
          'Average utilization of ${(avgUtil * 100).toStringAsFixed(1)}% is '
          'well-matched to current allocation. No change recommended.',
      confidence: stability,
    );
  }
}
