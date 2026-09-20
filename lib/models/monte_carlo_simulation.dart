import 'dart:math' as math;

/// Monte Carlo Maç Simülasyonu Sonuç Modeli
class MonteCarloSimulation {
  final int totalSimulations;
  final int homeWins;
  final int draws;
  final int awayWins;
  final double homeWinPercentage;
  final double drawPercentage;
  final double awayWinPercentage;
  final double avgTotalGoals;
  final int over25Count;
  final double over25Percentage;
  final int bttsCount;
  final double bttsPercentage;
  final Map<String, int> mostFrequentScores; // "2-1": 1420

  const MonteCarloSimulation({
    required this.totalSimulations,
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.homeWinPercentage,
    required this.drawPercentage,
    required this.awayWinPercentage,
    required this.avgTotalGoals,
    required this.over25Count,
    required this.over25Percentage,
    required this.bttsCount,
    required this.bttsPercentage,
    required this.mostFrequentScores,
  });

  /// Lambda (xG) değerlerine göre maçı N defa simüle eder (Varsayılan: 10.000)
  static MonteCarloSimulation simulate({
    required double lambdaHome,
    required double lambdaAway,
    int iterations = 10000,
  }) {
    final random = math.Random();
    int hWins = 0, dCount = 0, aWins = 0;
    int totalGoalsSum = 0;
    int over25 = 0;
    int btts = 0;
    final scoreCounts = <String, int>{};

    // Poisson rastgele değişken üretici (Knuth algoritması)
    int samplePoisson(double lambda) {
      final l = math.exp(-lambda);
      double p = 1.0;
      int k = 0;
      do {
        k++;
        p *= random.nextDouble();
      } while (p > l);
      return k - 1;
    }

    for (int i = 0; i < iterations; i++) {
      final h = samplePoisson(lambdaHome);
      final a = samplePoisson(lambdaAway);

      totalGoalsSum += (h + a);
      if (h + a > 2) over25++;
      if (h > 0 && a > 0) btts++;

      if (h > a) {
        hWins++;
      } else if (h < a) {
        aWins++;
      } else {
        dCount++;
      }

      final scoreKey = '$h-$a';
      scoreCounts[scoreKey] = (scoreCounts[scoreKey] ?? 0) + 1;
    }

    final sortedScores = Map.fromEntries(
      scoreCounts.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)),
    );

    return MonteCarloSimulation(
      totalSimulations: iterations,
      homeWins: hWins,
      draws: dCount,
      awayWins: aWins,
      homeWinPercentage: (hWins / iterations) * 100.0,
      drawPercentage: (dCount / iterations) * 100.0,
      awayWinPercentage: (aWins / iterations) * 100.0,
      avgTotalGoals: totalGoalsSum / iterations,
      over25Count: over25,
      over25Percentage: (over25 / iterations) * 100.0,
      bttsCount: btts,
      bttsPercentage: (btts / iterations) * 100.0,
      mostFrequentScores: Map.fromEntries(sortedScores.entries.take(5)),
    );
  }
}
