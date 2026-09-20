import 'dart:math' as math;

/// 15'er Dakikalık Dilimlerde Gol Olasılık Dağılımı
class GoalTimingDistribution {
  final List<double> homeIntervals; // [0-15, 16-30, 31-45, 46-60, 61-75, 76-90+]
  final List<double> awayIntervals;
  final List<double> totalIntervals;
  final String peakInterval; // Örn: "76-90+"
  final double peakProbability;
  final double firstHalfGoalProb;
  final double secondHalfGoalProb;

  const GoalTimingDistribution({
    required this.homeIntervals,
    required this.awayIntervals,
    required this.totalIntervals,
    required this.peakInterval,
    required this.peakProbability,
    required this.firstHalfGoalProb,
    required this.secondHalfGoalProb,
  });

  /// Lambda (xG) ve futbol zaman-ağırlık dinamikleriyle 15'er dakikalık gol dağılımını hesaplar
  static GoalTimingDistribution calculate({
    required double lambdaHome,
    required double lambdaAway,
  }) {
    // Futbol literatüründe gollerin zaman dağılımı yorgunluk ve risk alma nedeniyle
    // maçın sonlarına doğru artar (0-15: ~%13, 76-90: ~%23)
    const weights = [0.13, 0.15, 0.18, 0.16, 0.17, 0.21];

    final homeIntervals = <double>[];
    final awayIntervals = <double>[];
    final totalIntervals = <double>[];

    for (int i = 0; i < weights.length; i++) {
      final w = weights[i];
      // Poisson ile bu aralıkta en az 1 gol olma olasılığı: 1 - exp(-lambda * w)
      final hProb = (1.0 - math.exp(-lambdaHome * w)) * 100.0;
      final aProb = (1.0 - math.exp(-lambdaAway * w)) * 100.0;
      final tProb = (1.0 - math.exp(-(lambdaHome + lambdaAway) * w)) * 100.0;

      homeIntervals.add((hProb * 10).round() / 10);
      awayIntervals.add((aProb * 10).round() / 10);
      totalIntervals.add((tProb * 10).round() / 10);
    }

    const labels = ['0-15 dk', '16-30 dk', '31-45 dk', '46-60 dk', '61-75 dk', '76-90+ dk'];
    int maxIdx = 0;
    double maxP = 0.0;
    for (int i = 0; i < totalIntervals.length; i++) {
      if (totalIntervals[i] > maxP) {
        maxP = totalIntervals[i];
        maxIdx = i;
      }
    }

    // İlk Yarı ve İkinci Yarı Gol Olasılığı
    final totalLambda = lambdaHome + lambdaAway;
    final fhProb = (1.0 - math.exp(-totalLambda * 0.46)) * 100.0; // İlk 45 dk payı ~%46
    final shProb = (1.0 - math.exp(-totalLambda * 0.54)) * 100.0; // İkinci 45 dk payı ~%54

    return GoalTimingDistribution(
      homeIntervals: homeIntervals,
      awayIntervals: awayIntervals,
      totalIntervals: totalIntervals,
      peakInterval: labels[maxIdx],
      peakProbability: maxP,
      firstHalfGoalProb: (fhProb * 10).round() / 10,
      secondHalfGoalProb: (shProb * 10).round() / 10,
    );
  }
}
