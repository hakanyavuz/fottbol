import 'dart:math' as math;
import '../models/head_to_head.dart';
import '../models/referee_stat.dart';
import '../models/team.dart';

/// Kart & Korner Tahmin Modeli
class CardCornerPrediction {
  final double expectedTotalCorners;
  final double cornerOver95Prob; // 9.5 Korner Üstü İhtimali (%)
  final double cornerOver105Prob; // 10.5 Korner Üstü İhtimali (%)
  final String recommendedCornerPick;

  final double expectedTotalCards;
  final double cardOver45Prob; // 4.5 Kart Üstü İhtimali (%)
  final double redCardProb; // Kırmızı Kart Çıkma İhtimali (%)
  final String recommendedCardPick;

  const CardCornerPrediction({
    required this.expectedTotalCorners,
    required this.cornerOver95Prob,
    required this.cornerOver105Prob,
    required this.recommendedCornerPick,
    required this.expectedTotalCards,
    required this.cardOver45Prob,
    required this.redCardProb,
    required this.recommendedCardPick,
  });

  Map<String, dynamic> toJson() => {
    'expectedTotalCorners': expectedTotalCorners,
    'cornerOver95Prob': cornerOver95Prob,
    'cornerOver105Prob': cornerOver105Prob,
    'recommendedCornerPick': recommendedCornerPick,
    'expectedTotalCards': expectedTotalCards,
    'cardOver45Prob': cardOver45Prob,
    'redCardProb': redCardProb,
    'recommendedCardPick': recommendedCardPick,
  };

  factory CardCornerPrediction.fromJson(Map<String, dynamic> json) => CardCornerPrediction(
    expectedTotalCorners: (json['expectedTotalCorners'] as num?)?.toDouble() ?? 9.5,
    cornerOver95Prob: (json['cornerOver95Prob'] as num?)?.toDouble() ?? 50.0,
    cornerOver105Prob: (json['cornerOver105Prob'] as num?)?.toDouble() ?? 40.0,
    recommendedCornerPick: json['recommendedCornerPick'] ?? '9.5 Korner ÜST',
    expectedTotalCards: (json['expectedTotalCards'] as num?)?.toDouble() ?? 4.5,
    cardOver45Prob: (json['cardOver45Prob'] as num?)?.toDouble() ?? 50.0,
    redCardProb: (json['redCardProb'] as num?)?.toDouble() ?? 18.0,
    recommendedCardPick: json['recommendedCardPick'] ?? '4.5 Kart ALT',
  );
}

/// Kabus Rakip (Bogey Team) Analiz Raporu
class BogeyAnalysis {
  final bool hasBogeyEffect;
  final String? bogeyTeamName; // Kabus olan takım
  final String? victimTeamName; // Psikolojik baskı altındaki takım
  final double frustrationIndex; // 0.0 - 100.0 arası kabus derecesi
  final String description;

  const BogeyAnalysis({
    required this.hasBogeyEffect,
    this.bogeyTeamName,
    this.victimTeamName,
    this.frustrationIndex = 0.0,
    required this.description,
  });

  static const BogeyAnalysis none = BogeyAnalysis(
    hasBogeyEffect: false,
    description: 'Tarihsel eşleşmede anormal bir ters rakip baskısı bulunmuyor.',
  );

  Map<String, dynamic> toJson() => {
    'hasBogeyEffect': hasBogeyEffect,
    'bogeyTeamName': bogeyTeamName,
    'victimTeamName': victimTeamName,
    'frustrationIndex': frustrationIndex,
    'description': description,
  };

  factory BogeyAnalysis.fromJson(Map<String, dynamic> json) => BogeyAnalysis(
    hasBogeyEffect: json['hasBogeyEffect'] ?? false,
    bogeyTeamName: json['bogeyTeamName'],
    victimTeamName: json['victimTeamName'],
    frustrationIndex: (json['frustrationIndex'] as num?)?.toDouble() ?? 0.0,
    description: json['description'] ?? '',
  );
}

/// Özel Pazarlar Motoru: Kartlar, Kornerler & Kabus Rakip (Bogey Team) Endeksi
class SpecializedMarketsEngine {
  /// Korner ve Kart pazarlarını modelleyen analitik fonksiyon
  static CardCornerPrediction calculateCardsAndCorners({
    required Team homeTeam,
    required Team awayTeam,
    RefereeStat? referee,
    bool isDerby = false,
  }) {
    // 1. KORNER MODELİ (Poisson tabanlı beklenen korner)
    // Lig ortalaması yaklaşık 9.8 korner
    double baseHomeCorners = 5.2;
    double baseAwayCorners = 4.4;

    // Hücum baskısına göre dinamik ölçekleme
    final homeAttack = homeTeam.stats.avgHomeGoalsScored;
    final awayAttack = awayTeam.stats.avgAwayGoalsScored;

    double lambdaCornersHome = baseHomeCorners * (0.85 + (homeAttack * 0.12));
    double lambdaCornersAway = baseAwayCorners * (0.85 + (awayAttack * 0.12));

    double totalExpCorners = lambdaCornersHome + lambdaCornersAway;

    // 9.5 ve 10.5 Üstü kümülatif Poisson yaklaşımı
    double cornerOver95 = _calculatePoissonOver(totalExpCorners, 9);
    double cornerOver105 = _calculatePoissonOver(totalExpCorners, 10);

    String cornerPick = totalExpCorners >= 10.2
        ? '9.5 Korner ÜST (%${(cornerOver95 * 100).toStringAsFixed(0)})'
        : '10.5 Korner ALT (%${((1.0 - cornerOver105) * 100).toStringAsFixed(0)})';

    // 2. KART MODELİ (Hakem sertliği + Derbi katsayısı)
    final ref = referee ?? const RefereeStat(name: 'Standart');
    double baseYellows = ref.avgYellowCards > 0 ? ref.avgYellowCards : 4.4;
    double baseReds = ref.avgRedCards > 0 ? ref.avgRedCards : 0.18;

    if (isDerby) {
      baseYellows *= 1.25;
      baseReds *= 1.45;
    }

    double totalExpCards = baseYellows + (baseReds * 2.0);
    double cardOver45 = _calculatePoissonOver(totalExpCards, 4);
    double redCardPercentage = (1.0 - math.exp(-baseReds)) * 100.0;

    String cardPick = totalExpCards >= 4.8
        ? '4.5 Kart ÜST (%${(cardOver45 * 100).toStringAsFixed(0)})'
        : '4.5 Kart ALT (%${((1.0 - cardOver45) * 100).toStringAsFixed(0)})';

    return CardCornerPrediction(
      expectedTotalCorners: double.parse(totalExpCorners.toStringAsFixed(1)),
      cornerOver95Prob: double.parse((cornerOver95 * 100).toStringAsFixed(1)),
      cornerOver105Prob: double.parse((cornerOver105 * 100).toStringAsFixed(1)),
      recommendedCornerPick: cornerPick,
      expectedTotalCards: double.parse(totalExpCards.toStringAsFixed(1)),
      cardOver45Prob: double.parse((cardOver45 * 100).toStringAsFixed(1)),
      redCardProb: double.parse(redCardPercentage.toStringAsFixed(1)),
      recommendedCardPick: cardPick,
    );
  }

  /// Kabus Rakip (Bogey Team) Tespiti
  /// Güçlü takımın, kağıt üzerinde zayıf olan bir takıma karşı sürekli puan kaybetmesi sendromu
  static BogeyAnalysis detectBogeyTeam({
    required Team homeTeam,
    required Team awayTeam,
    HeadToHeadSummary? h2h,
    double? homeElo,
    double? awayElo,
  }) {
    if (h2h == null || h2h.played < 4) {
      return BogeyAnalysis.none;
    }

    final hElo = homeElo ?? 1500;
    final aElo = awayElo ?? 1500;
    final eloDiff = hElo - aElo;

    // Durum 1: Ev sahibi bariz favori (Elo +100 üstün) ama H2H'de deplasman domine ediyor
    if (eloDiff >= 80) {
      final awayUnbeatenRate = (h2h.awayTeamWins + h2h.draws) / h2h.played;

      if (awayUnbeatenRate >= 0.60) {
        final frustr = (awayUnbeatenRate * 100.0).clamp(60.0, 95.0);
        return BogeyAnalysis(
          hasBogeyEffect: true,
          bogeyTeamName: awayTeam.name,
          victimTeamName: homeTeam.name,
          frustrationIndex: double.parse(frustr.toStringAsFixed(1)),
          description: '⚠️ KABUS RAKİP ALARMI: ${homeTeam.name} kalite ve Elo olarak üstün olmasına rağmen son ${h2h.played} maçın %${(awayUnbeatenRate * 100).toStringAsFixed(0)}\'inde ${awayTeam.name} takımını yenemedi!',
        );
      }
    }

    // Durum 2: Deplasman bariz favori ama ev sahibi deplasmana ters geliyor
    if (eloDiff <= -80) {
      final homeUnbeatenRate = (h2h.homeTeamWins + h2h.draws) / h2h.played;

      if (homeUnbeatenRate >= 0.60) {
        final frustr = (homeUnbeatenRate * 100.0).clamp(60.0, 95.0);
        return BogeyAnalysis(
          hasBogeyEffect: true,
          bogeyTeamName: homeTeam.name,
          victimTeamName: awayTeam.name,
          frustrationIndex: double.parse(frustr.toStringAsFixed(1)),
          description: '⚠️ TERS DEPLASMAN SENDROMU: ${awayTeam.name} güçlü kadrosuna rağmen bu statta son ${h2h.played} maçta %${(homeUnbeatenRate * 100).toStringAsFixed(0)} kayıp yaşadı.',
        );
      }
    }

    return BogeyAnalysis.none;
  }

  static double _calculatePoissonOver(double lambda, int threshold) {
    double cumulativeUnder = 0.0;
    for (int k = 0; k <= threshold; k++) {
      cumulativeUnder += _poissonPmf(lambda, k);
    }
    return (1.0 - cumulativeUnder).clamp(0.01, 0.99);
  }

  static double _poissonPmf(double lambda, int k) {
    if (k < 0) return 0.0;
    double logP = -lambda + (k * math.log(lambda)) - _logFactorial(k);
    return math.exp(logP);
  }

  static double _logFactorial(int n) {
    if (n <= 1) return 0.0;
    double sum = 0.0;
    for (int i = 2; i <= n; i++) {
      sum += math.log(i);
    }
    return sum;
  }
}
