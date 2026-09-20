import 'dart:math' as math;
import '../core/constants/league_constants.dart';
import 'fixture.dart';

/// Aralarındaki tek bir geçmiş maç (gösterim için sade kayıt)
class HeadToHeadMatch {
  final DateTime? date;
  final String homeName;
  final String awayName;
  final int homeGoals;
  final int awayGoals;

  const HeadToHeadMatch({
    this.date,
    required this.homeName,
    required this.awayName,
    required this.homeGoals,
    required this.awayGoals,
  });

  String get scoreLine => '$homeName $homeGoals - $awayGoals $awayName';

  Map<String, dynamic> toJson() => {
    'date': date?.toIso8601String(),
    'homeName': homeName,
    'awayName': awayName,
    'homeGoals': homeGoals,
    'awayGoals': awayGoals,
  };

  factory HeadToHeadMatch.fromJson(Map<String, dynamic> json) => HeadToHeadMatch(
    date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    homeName: json['homeName'] ?? '',
    awayName: json['awayName'] ?? '',
    homeGoals: (json['homeGoals'] as num?)?.toInt() ?? 0,
    awayGoals: (json['awayGoals'] as num?)?.toInt() ?? 0,
  );
}

/// İki takımın aralarındaki maçların özeti — `GET /fixtures/headtohead`.
///
/// Tüm değerler **bu maçın** ev sahibi (A) ve deplasman (B) takımı açısındandır;
/// geçmiş maçın hangi sahada oynandığından bağımsız olarak A'nın ve B'nin
/// attığı goller toplanır.
class HeadToHeadSummary {
  final int played;
  final int homeTeamWins;
  final int draws;
  final int awayTeamWins;
  final double homeTeamGoalsAvg;
  final double awayTeamGoalsAvg;

  /// Zamana göre sönümlü (time-decay) ağırlıklı gol ortalamaları
  final double timeWeightedHomeGoalsAvg;
  final double timeWeightedAwayGoalsAvg;

  /// Karşılıklı gol (KG Var) istatistiği
  final int bttsCount;
  final double bttsPercentage;

  /// 2.5 Gol Üstü istatistiği
  final int over25Count;
  final double over25Percentage;

  /// Maç başı toplam gol
  final double avgTotalGoals;

  /// En yeni başta, en fazla 5 maç
  final List<HeadToHeadMatch> recent;

  const HeadToHeadSummary({
    required this.played,
    required this.homeTeamWins,
    required this.draws,
    required this.awayTeamWins,
    required this.homeTeamGoalsAvg,
    required this.awayTeamGoalsAvg,
    double? timeWeightedHomeGoalsAvg,
    double? timeWeightedAwayGoalsAvg,
    this.bttsCount = 0,
    this.bttsPercentage = 0.0,
    this.over25Count = 0,
    this.over25Percentage = 0.0,
    this.avgTotalGoals = 0.0,
    required this.recent,
  })  : timeWeightedHomeGoalsAvg = timeWeightedHomeGoalsAvg ?? homeTeamGoalsAvg,
        timeWeightedAwayGoalsAvg = timeWeightedAwayGoalsAvg ?? awayTeamGoalsAvg;

  bool get hasData => played > 0;

  /// Beklenen gol hesabındaki ağırlık (varsayılan tavan ile)
  double get weight => weightFor(LeagueConstants.maxHeadToHeadWeight);

  /// Belirli bir tavan ağırlığına göre hesaplanan dinamik H2H ağırlığı
  double weightFor(double maxWeight) {
    if (played == 0) return 0;
    final ratio = math.min(played, LeagueConstants.headToHeadFullWeightMatches) /
        LeagueConstants.headToHeadFullWeightMatches;
    return maxWeight * ratio;
  }

  /// Fikstür listesinden özet çıkarır. Yalnızca iki takımın da yer aldığı ve
  /// sonucu kesinleşmiş maçlar sayılır.
  factory HeadToHeadSummary.fromFixtures(
    List<Fixture> fixtures, {
    required int homeTeamId,
    required int awayTeamId,
  }) {
    final finished = fixtures.where((f) {
      final involvesBoth = (f.homeTeamId == homeTeamId && f.awayTeamId == awayTeamId) ||
          (f.homeTeamId == awayTeamId && f.awayTeamId == homeTeamId);
      return involvesBoth && f.isFinished && f.hasScore;
    }).toList()
      ..sort((a, b) => (b.date ?? DateTime(1900)).compareTo(a.date ?? DateTime(1900)));

    var aWins = 0, draws = 0, bWins = 0, aGoals = 0, bGoals = 0;
    var btts = 0, over25 = 0;
    final now = DateTime.now();
    double sumWeights = 0.0;
    double weightedAGoals = 0.0;
    double weightedBGoals = 0.0;

    for (final f in finished) {
      final aIsHome = f.homeTeamId == homeTeamId;
      final aScored = aIsHome ? f.homeGoals! : f.awayGoals!;
      final bScored = aIsHome ? f.awayGoals! : f.homeGoals!;

      aGoals += aScored;
      bGoals += bScored;

      if (aScored > 0 && bScored > 0) {
        btts++;
      }
      if (aScored + bScored > 2) {
        over25++;
      }

      // Zamana göre üstel sönümleme: 2 yıllık yarı ömür (~730 gün)
      final daysDiff = f.date != null ? math.max(0, now.difference(f.date!).inDays) : 365;
      final timeWeight = math.exp(-0.35 * (daysDiff / 365.0));
      sumWeights += timeWeight;
      weightedAGoals += aScored * timeWeight;
      weightedBGoals += bScored * timeWeight;

      if (aScored > bScored) {
        aWins++;
      } else if (aScored < bScored) {
        bWins++;
      } else {
        draws++;
      }
    }

    final n = finished.length;
    final rawHAvg = n > 0 ? aGoals / n : 0.0;
    final rawAAvg = n > 0 ? bGoals / n : 0.0;
    final totalAvg = n > 0 ? (aGoals + bGoals) / n : 0.0;
    final bttsPct = n > 0 ? (btts / n) * 100 : 0.0;
    final over25Pct = n > 0 ? (over25 / n) * 100 : 0.0;

    return HeadToHeadSummary(
      played: n,
      homeTeamWins: aWins,
      draws: draws,
      awayTeamWins: bWins,
      homeTeamGoalsAvg: rawHAvg,
      awayTeamGoalsAvg: rawAAvg,
      timeWeightedHomeGoalsAvg: sumWeights > 0 ? weightedAGoals / sumWeights : rawHAvg,
      timeWeightedAwayGoalsAvg: sumWeights > 0 ? weightedBGoals / sumWeights : rawAAvg,
      bttsCount: btts,
      bttsPercentage: bttsPct,
      over25Count: over25,
      over25Percentage: over25Pct,
      avgTotalGoals: totalAvg,
      recent: finished
          .take(5)
          .map((f) => HeadToHeadMatch(
                date: f.date,
                homeName: f.homeTeamName,
                awayName: f.awayTeamName,
                homeGoals: f.homeGoals!,
                awayGoals: f.awayGoals!,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'played': played,
    'homeTeamWins': homeTeamWins,
    'draws': draws,
    'awayTeamWins': awayTeamWins,
    'homeTeamGoalsAvg': homeTeamGoalsAvg,
    'awayTeamGoalsAvg': awayTeamGoalsAvg,
    'timeWeightedHomeGoalsAvg': timeWeightedHomeGoalsAvg,
    'timeWeightedAwayGoalsAvg': timeWeightedAwayGoalsAvg,
    'bttsCount': bttsCount,
    'bttsPercentage': bttsPercentage,
    'over25Count': over25Count,
    'over25Percentage': over25Percentage,
    'avgTotalGoals': avgTotalGoals,
    'recent': recent.map((m) => m.toJson()).toList(),
  };

  factory HeadToHeadSummary.fromJson(Map<String, dynamic> json) => HeadToHeadSummary(
    played: (json['played'] as num?)?.toInt() ?? 0,
    homeTeamWins: (json['homeTeamWins'] as num?)?.toInt() ?? 0,
    draws: (json['draws'] as num?)?.toInt() ?? 0,
    awayTeamWins: (json['awayTeamWins'] as num?)?.toInt() ?? 0,
    homeTeamGoalsAvg: (json['homeTeamGoalsAvg'] as num?)?.toDouble() ?? 0,
    awayTeamGoalsAvg: (json['awayTeamGoalsAvg'] as num?)?.toDouble() ?? 0,
    timeWeightedHomeGoalsAvg: (json['timeWeightedHomeGoalsAvg'] as num?)?.toDouble(),
    timeWeightedAwayGoalsAvg: (json['timeWeightedAwayGoalsAvg'] as num?)?.toDouble(),
    bttsCount: (json['bttsCount'] as num?)?.toInt() ?? 0,
    bttsPercentage: (json['bttsPercentage'] as num?)?.toDouble() ?? 0.0,
    over25Count: (json['over25Count'] as num?)?.toInt() ?? 0,
    over25Percentage: (json['over25Percentage'] as num?)?.toDouble() ?? 0.0,
    avgTotalGoals: (json['avgTotalGoals'] as num?)?.toDouble() ?? 0.0,
    recent: (json['recent'] as List? ?? [])
        .whereType<Map>()
        .map((m) => HeadToHeadMatch.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}
