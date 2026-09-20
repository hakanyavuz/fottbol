import 'dart:math' as math;
import '../core/constants/league_constants.dart';
import '../core/utils/math_utils.dart';
import '../models/head_to_head.dart';
import '../models/team.dart';
import '../models/prediction_result.dart';
import '../models/referee_stat.dart';
import '../models/weather_pitch_condition.dart';
import 'club_elo_service.dart';

/// İstatistiksel Poisson Dağılımı ve Form Tabanlı Tahmin Motoru
class PoissonEngine {
  // Avrupa ve genel lig ortalamaları referans sabitleri
  static const double leagueAvgHomeGoals = LeagueConstants.avgHomeGoals;
  static const double leagueAvgAwayGoals = LeagueConstants.avgAwayGoals;

  /// İki takım verisini alarak Poisson modelini çalıştırır ve tahmini üretir.
  ///
  /// [fixtureId] ve [matchDate] gerçek bir fikstürden gelindiğinde doldurulur;
  /// böylece maç oynandıktan sonra gerçek skor çekilip isabet ölçülebilir.
  ///
  /// [rho] Dixon-Coles düşük skor düzeltmesidir (0 verilirse saf Poisson).
  /// [headToHead] verilirse aralarındaki maçların gol ortalamaları örneklem
  /// büyüklüğüne göre sınırlı bir ağırlıkla beklenen gole katılır.
  static PredictionResult calculatePrediction({
    required Team homeTeam,
    required Team awayTeam,
    int? fixtureId,
    DateTime? matchDate,
    String? referee,
    double rho = LeagueConstants.dixonColesRho,
    double maxH2hWeight = LeagueConstants.maxHeadToHeadWeight,
    bool isDataCalibrated = false,
    HeadToHeadSummary? headToHead,
    bool isNeutralGround = false,
    WeatherCondition? weatherCondition,
    double? homeElo,
    double? awayElo,
    double? homeXg,
    double? awayXg,
    int? homeRestDays,
    int? awayRestDays,
  }) {
    final List<String> rationale = [];

    // 1. Hücum ve Savunma Gücü Hesaplamaları
    // Ev sahibi hücum gücü = Takımın iç sahada attığı gol / Lig iç saha gol ortalaması
    double homeAttackStrength = homeTeam.stats.avgHomeGoalsScored / leagueAvgHomeGoals;
    // Deplasman savunma zafiyeti = Deplasmanın dışarıda yediği gol / Lig deplasman yeme ortalaması
    // Deplasman takımlarının yediği gol ortalaması = ev sahiplerinin attığı gol ortalaması (1.55)
    double awayDefenseWeakness = awayTeam.stats.avgAwayGoalsConceded / leagueAvgHomeGoals;

    // Deplasman hücum gücü = Deplasmanın attığı gol / Lig deplasman gol ortalaması
    double awayAttackStrength = awayTeam.stats.avgAwayGoalsScored / leagueAvgAwayGoals;
    // Ev sahibi savunma zafiyeti = Ev sahibinin iç sahada yediği / Lig ev yeme ortalaması
    // Ev sahiplerinin yediği gol ortalaması = deplasmanların attığı gol ortalaması (1.20)
    double homeDefenseWeakness = homeTeam.stats.avgHomeGoalsConceded / leagueAvgAwayGoals;

    rationale.add(
      '${homeTeam.name} iç sahada maç başı ${homeTeam.stats.avgHomeGoalsScored.toStringAsFixed(1)} gol atıyor '
      '(Hücum Gücü: %${(homeAttackStrength * 100).toStringAsFixed(0)}).',
    );
    rationale.add(
      '${awayTeam.name} deplasmanda maç başı ${awayTeam.stats.avgAwayGoalsConceded.toStringAsFixed(1)} gol kalesinde görüyor '
      '(Savunma Zafiyeti: %${(awayDefenseWeakness * 100).toStringAsFixed(0)}).',
    );

    // 2. Son Maç Form Faktörü (Son 5 maç)
    double homeFormFactor = _calculateFormFactor(homeTeam.stats.recentForm);
    double awayFormFactor = _calculateFormFactor(awayTeam.stats.recentForm);

    final homePoints = _formPoints(homeTeam.stats.recentForm);
    final awayPoints = _formPoints(awayTeam.stats.recentForm);
    rationale.add(
      'Son 5 maçlık form tablosunda ${homeTeam.name} $homePoints/15 puan toplarken, '
      '${awayTeam.name} $awayPoints/15 puan topladı.',
    );

    // 3. Kadro ve Sakatlık Etkisi (Dinamik Gol Payı ve Mevki Ağırlıklı)
    final bool missingSquad = homeTeam.squad.isEmpty || awayTeam.squad.isEmpty;
    final bool missingStats = !homeTeam.stats.hasData || !awayTeam.stats.hasData;
    final bool isSparseData = missingSquad || missingStats;

    if (isSparseData) {
      final eksikler = <String>[];
      if (missingStats) {
        final takimlar = [
          if (!homeTeam.stats.hasData) homeTeam.name,
          if (!awayTeam.stats.hasData) awayTeam.name,
        ].join(' ve ');
        eksikler.add(
          '$takimlar için sezon istatistiği çekilemediğinden bu takım(lar) lig ortalamasıyla modellendi',
        );
      }
      if (missingSquad) {
        eksikler.add(
          'oyuncu bazlı kadro/sakatlık verisi bulunmadığından tahmin takım gol ortalamaları ve form üzerinden hesaplandı',
        );
      }

      rationale.insert(0, '⚠️ Sınırlı Veri Modu: ${eksikler.join('; ')}.');
    }

    double homeInjuryAttackMultiplier = 1.0;
    double homeInjuryDefenseMultiplier = 1.0;
    for (final player in homeTeam.squad.where((p) => p.isInjured)) {
      final dynPenalty = player.dynamicAttackPenalty(homeTeam.stats.goalsScored);
      homeInjuryAttackMultiplier -= dynPenalty;
      homeInjuryDefenseMultiplier += player.defensePenalty;
      if (dynPenalty > 0 || player.defensePenalty > 0) {
        rationale.add(
          '${homeTeam.name} kilit oyuncusu ${player.name} (${player.position}) sakatlığı nedeniyle hücum/savunma verimi revize edildi (-%${(dynPenalty * 100).toStringAsFixed(1)}).',
        );
      }
    }

    double awayInjuryAttackMultiplier = 1.0;
    double awayInjuryDefenseMultiplier = 1.0;
    for (final player in awayTeam.squad.where((p) => p.isInjured)) {
      final dynPenalty = player.dynamicAttackPenalty(awayTeam.stats.goalsScored);
      awayInjuryAttackMultiplier -= dynPenalty;
      awayInjuryDefenseMultiplier += player.defensePenalty;
      if (dynPenalty > 0 || player.defensePenalty > 0) {
        rationale.add(
          '${awayTeam.name} kilit oyuncusu ${player.name} (${player.position}) sakatlığı deplasman gücünü etkiliyor (-%${(dynPenalty * 100).toStringAsFixed(1)}).',
        );
      }
    }

    // 3b. Dinlenme ve Fikstür Yoğunluğu (Fatigue & Rest Days)
    // Varsayılan lig ritminde 6-7 gün dinlenme normaldir; hafta içi Avrupa maçı yapanlar 3 gün dinlenir.
    int effectiveHomeRestDays = homeRestDays ?? 6;
    int effectiveAwayRestDays = awayRestDays ?? 6;
    if (homeRestDays == null && awayRestDays == null && matchDate != null) {
      final dayOfWeek = matchDate.weekday; // 1: Pazartesi ... 7: Pazar
      // Hafta sonu maçıysa ve takım Avrupa kupalarında yer alıyorsa dinlenme 3 gün
      if ((dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) &&
          (homeTeam.name.contains('Galatasaray') ||
              homeTeam.name.contains('Fenerbahçe') ||
              homeTeam.name.contains('Beşiktaş') ||
              homeTeam.name.contains('City') ||
              homeTeam.name.contains('Real') ||
              homeTeam.name.contains('Bayern'))) {
        effectiveHomeRestDays = 3;
      }
      if ((dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) &&
          (awayTeam.name.contains('Galatasaray') ||
              awayTeam.name.contains('Fenerbahçe') ||
              awayTeam.name.contains('Beşiktaş') ||
              awayTeam.name.contains('City') ||
              awayTeam.name.contains('Real') ||
              awayTeam.name.contains('Bayern'))) {
        effectiveAwayRestDays = 3;
      }
    }

    double homeRestMultiplier = effectiveHomeRestDays <= 3 ? 0.94 : 1.0;
    double awayRestMultiplier = effectiveAwayRestDays <= 3 ? 0.93 : 1.0;
    if (effectiveHomeRestDays <= 3) {
      rationale.add(
        '${homeTeam.name} hafta içi yoğun fikstür nedeniyle $effectiveHomeRestDays gün dinlenebildi; fiziksel yorgunluk faktörü uygulandı (-%6).',
      );
    }
    if (effectiveAwayRestDays <= 3) {
      rationale.add(
        '${awayTeam.name} yoğun fikstür ve seyahat nedeniyle $effectiveAwayRestDays gün dinlendi (-%7).',
      );
    }

    // 3e. Club Elo Küresel Güç Endeksi ve Takım Kalite Farkı
    final effectiveHomeElo = homeElo ?? ClubEloService.getTeamElo(homeTeam.name);
    final effectiveAwayElo = awayElo ?? ClubEloService.getTeamElo(awayTeam.name);
    final eloDiff = effectiveHomeElo - effectiveAwayElo;
    final eloMultipliers = ClubEloService.calculateGoalMultipliers(eloDiff);

    if (eloDiff.abs() >= 25.0) {
      rationale.add(
        '⚖️ Club Elo Güç Endeksi: ${homeTeam.name} (${effectiveHomeElo.toInt()}) vs ${awayTeam.name} (${effectiveAwayElo.toInt()}) '
        '[Fark: ${eloDiff > 0 ? "+" : ""}${eloDiff.toInt()}]. Kadro kalite farkı beklenen gole yansıtıldı.',
      );
    }

    // 3c. Şut ve Bitiricilik Kalitesi (Shot Quality & xG Efficiency)
    double homeShotEff = 0.35;
    double awayShotEff = 0.33;
    final hShots = homeTeam.stats.avgShotsPerGame;
    final hTarget = homeTeam.stats.avgShotsOnTarget;
    if (hShots != null && hShots > 0 && hTarget != null) {
      homeShotEff = hTarget / hShots;
    }
    final aShots = awayTeam.stats.avgShotsPerGame;
    final aTarget = awayTeam.stats.avgShotsOnTarget;
    if (aShots != null && aShots > 0 && aTarget != null) {
      awayShotEff = aTarget / aShots;
    }

    // Normal lig ortalaması isabet oranı ~%34 kabul edilir
    double homeShotMultiplier = hShots != null ? (0.90 + (homeShotEff / 0.34) * 0.10) : 1.0;
    double awayShotMultiplier = aShots != null ? (0.90 + (awayShotEff / 0.34) * 0.10) : 1.0;

    // 3d. Hakem Eğilimi & Kart/Penaltı Etkisi (Referee Bias & Strictness)
    RefereeStat? refStat;
    double refereePenaltyXgMultiplier = 1.0;
    if (referee != null && referee.isNotEmpty) {
      refStat = RefereeStat.forName(referee);
      if (refStat.hasHighPenaltyTendency) {
        refereePenaltyXgMultiplier = 1.04; // Yüksek penaltı eğilimi toplam gol beklentisini %4 artırır
        rationale.add(
          'Hakem ${refStat.name}: Maç başı ${refStat.avgPenalties.toStringAsFixed(2)} penaltı ve '
          '${refStat.avgYellowCards.toStringAsFixed(1)} sarı kart ortalamasına sahip (${refStat.strictnessRating}). '
          'Penaltı olasılığı yüksek görüldüğünden beklenen gol çarpanı revize edildi (+%4).',
        );
      } else {
        rationale.add(
          'Hakem ${refStat.name}: Maç başı ${refStat.avgFouls.toStringAsFixed(0)} faul ve '
          '${refStat.avgYellowCards.toStringAsFixed(1)} sarı kart ortalamasıyla maçı yönetiyor (${refStat.strictnessRating}).',
        );
      }
    }

    // Nötr Saha Etkisi: Ev sahibi avantajını nötrler
    double effectiveHomeAvgGoals = leagueAvgHomeGoals;
    double effectiveAwayAvgGoals = leagueAvgAwayGoals;
    if (isNeutralGround) {
      const neutralAvg = (leagueAvgHomeGoals + leagueAvgAwayGoals) / 2.0; // 1.375
      effectiveHomeAvgGoals = neutralAvg;
      effectiveAwayAvgGoals = neutralAvg;
      rationale.add(
        '🏟️ Nötr Saha: Karşılaşma tarafsız sahada oynandığından ev sahibi saha avantajı eşitlendi.',
      );
    }

    // 4. Beklenen Gol (Lambda / xG) Değerlerinin Hesaplanması
    double lambdaHome = homeAttackStrength *
        awayDefenseWeakness *
        effectiveHomeAvgGoals *
        homeFormFactor *
        homeInjuryAttackMultiplier *
        awayInjuryDefenseMultiplier *
        homeRestMultiplier *
        homeShotMultiplier *
        refereePenaltyXgMultiplier;

    double lambdaAway = awayAttackStrength *
        homeDefenseWeakness *
        effectiveAwayAvgGoals *
        awayFormFactor *
        awayInjuryAttackMultiplier *
        homeInjuryDefenseMultiplier *
        awayRestMultiplier *
        awayShotMultiplier *
        refereePenaltyXgMultiplier;

    // Club Elo Kalite Çarpanı Uygulaması
    lambdaHome *= eloMultipliers.homeMultiplier;
    lambdaAway *= eloMultipliers.awayMultiplier;

    // xG (Beklenen Gol) Kalite Harmanlaması
    if (homeXg != null && awayXg != null && homeXg > 0 && awayXg > 0) {
      lambdaHome = lambdaHome * 0.70 + homeXg * 0.30;
      lambdaAway = lambdaAway * 0.70 + awayXg * 0.30;
      rationale.add(
        '🎯 xG Kalite Ayarı: Takımların son pozisyon kalitesi (${homeXg.toStringAsFixed(2)} - ${awayXg.toStringAsFixed(2)}) %30 ağırlıkla modele katıldı.',
      );
    }

    // Hava ve Zemin Koşulu Çarpanı
    if (weatherCondition != null && weatherCondition != WeatherCondition.clear) {
      lambdaHome *= weatherCondition.goalExpectancyMultiplier;
      lambdaAway *= weatherCondition.goalExpectancyMultiplier;
      rationale.add(
        '🌦️ Saha & Hava Durumu: ${weatherCondition.label} (Gol beklentisi çarpanı: x${weatherCondition.goalExpectancyMultiplier.toStringAsFixed(2)}).',
      );
    }

    // 5. Aralarındaki maçlar (Head-to-Head) — sınırlı ağırlıkla harmanlama
    final h2h = headToHead;
    if (h2h != null && h2h.hasData) {
      final w = h2h.weightFor(maxH2hWeight);
      final homeGoalsRef = h2h.timeWeightedHomeGoalsAvg;
      final awayGoalsRef = h2h.timeWeightedAwayGoalsAvg;
      lambdaHome = (1 - w) * lambdaHome + w * homeGoalsRef;
      lambdaAway = (1 - w) * lambdaAway + w * awayGoalsRef;

      final calibSuffix = isDataCalibrated ? ' (veriden kalibre edilmiş ağırlık)' : '';
      rationale.add(
        'Aralarındaki son ${h2h.played} maç: ${homeTeam.name} ${h2h.homeTeamWins}G, '
        '${h2h.draws}B, ${awayTeam.name} ${h2h.awayTeamWins}G '
        '(zaman ağırlıklı ort. ${homeGoalsRef.toStringAsFixed(1)} - ${awayGoalsRef.toStringAsFixed(1)} gol, '
        'KG Var: %${h2h.bttsPercentage.toStringAsFixed(0)}, 2.5 Üst: %${h2h.over25Percentage.toStringAsFixed(0)}). '
        'Bu geçmiş beklenen gole %${(w * 100).toStringAsFixed(0)} ağırlıkla$calibSuffix katıldı.',
      );
    }

    // Gerçekçi sınırlar (0.2 ile 4.5 arası gol beklentisi)
    lambdaHome = math.max(0.2, math.min(4.5, lambdaHome));
    lambdaAway = math.max(0.2, math.min(4.5, lambdaAway));

    rationale.add(
      'Poisson Beklenen Gol (xG): ${homeTeam.name}: ${lambdaHome.toStringAsFixed(2)} | '
      '${awayTeam.name}: ${lambdaAway.toStringAsFixed(2)}.',
    );

    // 6. 6x6 Skor Matrisi (0-5 gol) — Poisson × Dixon-Coles düzeltmesi
    final double effectiveRho = MathUtils.clampRho(rho, lambdaHome, lambdaAway);
    final raw = List.generate(6, (_) => List<double>.filled(6, 0));
    double total = 0.0;

    for (int h = 0; h <= 5; h++) {
      for (int a = 0; a <= 5; a++) {
        final double p = MathUtils.poissonProbability(h, lambdaHome) *
            MathUtils.poissonProbability(a, lambdaAway) *
            MathUtils.dixonColesTau(h, a, lambdaHome, lambdaAway, effectiveRho);
        raw[h][a] = p;
        total += p;
      }
    }

    if (effectiveRho != 0) {
      final calibSuffix = isDataCalibrated ? ' (gerçek sonuçlardan kalibre edildi)' : '';
      rationale.add(
        'Dixon-Coles düzeltmesi (ρ = ${effectiveRho.toStringAsFixed(2)})$calibSuffix uygulandı: '
        'bağımsız Poisson modelinin az tahmin ettiği 0-0 ve 1-1 skorlarının olasılığı dengelendi.',
      );
    }

    // Normalizasyon: matris 5 golden fazlasını kapsamadığı için kütle %100'ün biraz
    // altında kalır. Tüm çıktılar (matris, ilk 3 skor, 1X2, 2.5 Üst, KG Var) aynı
    // toplama bölünerek tutarlı ölçeklenir.
    final scoreMatrix = [
      for (int h = 0; h <= 5; h++)
        [for (int a = 0; a <= 5; a++) raw[h][a] / total * 100],
    ];

    double homeWinTotal = 0.0;
    double drawTotal = 0.0;
    double awayWinTotal = 0.0;
    double over25Total = 0.0;
    double bttsTotal = 0.0;
    final List<ScoreProbability> scoreProbabilities = [];

    for (int h = 0; h <= 5; h++) {
      for (int a = 0; a <= 5; a++) {
        final pct = scoreMatrix[h][a];
        scoreProbabilities.add(ScoreProbability(homeGoals: h, awayGoals: a, probability: pct));

        if (h > a) {
          homeWinTotal += pct;
        } else if (h == a) {
          drawTotal += pct;
        } else {
          awayWinTotal += pct;
        }
        if (h + a > 2) over25Total += pct;
        if (h > 0 && a > 0) bttsTotal += pct;
      }
    }

    // Şike / Manipülasyon ve Yüksek Varyans Analizi (Türkiye, İtalya, Fransa Lig ve Kupaları)
    final bool isHighRisk = isHighManipulationRiskLeague(
      leagueName: homeTeam.league.isNotEmpty ? homeTeam.league : awayTeam.league,
    );
    final String? riskRegion = isHighRisk
        ? getManipulationRiskCountryName(leagueName: homeTeam.league.isNotEmpty ? homeTeam.league : awayTeam.league)
        : null;

    if (isHighRisk) {
      final double diff = (homeWinTotal - awayWinTotal).abs();
      final double dampening = math.min(5.0, diff * 0.12);
      if (homeWinTotal > awayWinTotal) {
        homeWinTotal -= dampening;
        drawTotal += dampening * 0.6;
        awayWinTotal += dampening * 0.4;
      } else if (awayWinTotal > homeWinTotal) {
        awayWinTotal -= dampening;
        drawTotal += dampening * 0.6;
        homeWinTotal += dampening * 0.4;
      }
    }

    // Skorları olasılığa göre azalan sırala
    scoreProbabilities.sort((a, b) => b.probability.compareTo(a.probability));

    // Çıktı ve xG Uyumlu Dinamik Skor Seçimi (Outcome & xG Centroid Alignment):
    // Klasik Poisson modellerinde "Poisson Argmax Mode Tuzağı" görülür:
    // Ev sahibi kazanma toplamı %55-60 bile olsa, galibiyet olasılıkları birçok hücreye
    // dağılırken, saf 1-0 hücresi matematiksel olarak 2-0 veya 3-1'den daha yüksek tekil hücre
    // değerine sahip olur. Bu sebeple saf mod seçimi her maça 1-0/2-1/1-1 üretir.
    // Çözüm: Modelin öngördüğü 1X2 sonucuna (Ev / Beraberlik / Deplasman) uyan aday skorlar
    // arasından, beklenen gol vektörüne (lambdaHome, lambdaAway) en yakın ve olasılık kütlesi
    // yüksek olan dinamik centroid skoru manşet skoru olarak seçilir.
    final String dominantOutcome;
    if (homeWinTotal >= drawTotal && homeWinTotal >= awayWinTotal) {
      dominantOutcome = 'HOME';
    } else if (awayWinTotal >= drawTotal && awayWinTotal >= homeWinTotal) {
      dominantOutcome = 'AWAY';
    } else {
      dominantOutcome = 'DRAW';
    }

    final candidateScores = scoreProbabilities.where((s) {
      if (dominantOutcome == 'HOME') return s.homeGoals > s.awayGoals;
      if (dominantOutcome == 'AWAY') return s.awayGoals > s.homeGoals;
      return s.homeGoals == s.awayGoals;
    }).toList();

    // Aday skorları beklenen gol (lambda) mesafesi ve hücre olasılığını harmanlayarak puanla
    candidateScores.sort((a, b) {
      final distA = math.pow(a.homeGoals - lambdaHome, 2) + math.pow(a.awayGoals - lambdaAway, 2);
      final distB = math.pow(b.homeGoals - lambdaHome, 2) + math.pow(b.awayGoals - lambdaAway, 2);
      final scoreA = a.probability / (1.0 + 0.65 * distA);
      final scoreB = b.probability / (1.0 + 0.65 * distB);
      return scoreB.compareTo(scoreA);
    });

    final ScoreProbability primaryScore = candidateScores.isNotEmpty
        ? candidateScores.first
        : scoreProbabilities.first;

    // İlk sıraya manşet skoru koyarak, diğer olasılığı yüksek alternatifleri top 3 listesine ekle
    final otherCandidates = scoreProbabilities
        .where((s) => s.scoreString != primaryScore.scoreString)
        .toList();

    final top3Scores = <ScoreProbability>[
      primaryScore,
      ...otherCandidates.take(2),
    ];

    double round1(double v) => (v * 10).round() / 10;

    rationale.add(
      'xG ve Poisson analizine göre öne çıkan skor: ${primaryScore.homeGoals} - ${primaryScore.awayGoals} '
      '(%${primaryScore.probability.toStringAsFixed(1)} olasılıkla).',
    );

    // 7. Güven Skoru (Confidence Score) & Risk Seviyesi Belirleme
    final sortedOutcomes = [homeWinTotal, drawTotal, awayWinTotal]..sort((a, b) => b.compareTo(a));
    final top1 = sortedOutcomes[0];
    final top2 = sortedOutcomes[1];
    final margin = top1 - top2; // Fark ne kadar açıksa model o kadar kararlı

    // Örneklem güvenilirliği (takım verileri eksiksizse bonus)
    double sampleBonus = (!missingStats && !missingSquad) ? 10.0 : -10.0;
    if (h2h != null && h2h.played >= 3) sampleBonus += 5.0;

    double confidenceScore = math.min(95.0, math.max(40.0, 50.0 + (margin * 0.9) + sampleBonus));
    if (isHighRisk) {
      // Şike/manipülasyon liglerinde aşırı güven engellenir, maksimum %75 tavanı
      confidenceScore = math.min(75.0, confidenceScore - 5.0);
    }
    confidenceScore = round1(confidenceScore);

    String riskLevel = 'Dengeli';
    if (isHighRisk) {
      riskLevel = 'Yüksek Varyans (Manipülasyon Riski)';
      rationale.add(
        '🛡️ Risk Kalkanı ($riskRegion Lig/Kupa): Bu lig ve kupa organizasyonunda tarihsel sonuç anomalileri '
        've şike/manipülasyon varyansı yüksek olduğundan, model aşırı güvenden arındırılmış, güven tavanı %75 '
        'olarak sınırlandırılmış ve kasa koruma katsayısı uygulanmıştır.',
      );
    } else if (confidenceScore >= 78.0) {
      riskLevel = 'Banko (Düşük Risk)';
    } else if (confidenceScore <= 58.0) {
      riskLevel = 'Sürpriz / Yüksek Risk';
    } else {
      riskLevel = 'Dengeli Karşılaşma';
    }

    return PredictionResult(
      // Aynı maç tekrar tahmin edilirse geçmişte kopya oluşmaması için
      // fikstür kimliği varsa sabit bir id kullanılır.
      id: fixtureId != null
          ? 'fixture_$fixtureId'
          : DateTime.now().millisecondsSinceEpoch.toString(),
      fixtureId: fixtureId,
      matchDate: matchDate,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      predictedHomeGoals: primaryScore.homeGoals,
      predictedAwayGoals: primaryScore.awayGoals,
      lambdaHome: lambdaHome,
      lambdaAway: lambdaAway,
      homeWinProbability: round1(homeWinTotal),
      drawProbability: round1(drawTotal),
      awayWinProbability: round1(awayWinTotal),
      over25Probability: round1(over25Total),
      bothTeamsToScoreProbability: round1(bttsTotal),
      scoreMatrix: scoreMatrix,
      dixonColesRho: effectiveRho,
      headToHead: h2h != null && h2h.hasData ? h2h : null,
      confidenceScore: confidenceScore,
      riskLevel: riskLevel,
      homeRestDays: effectiveHomeRestDays,
      awayRestDays: effectiveAwayRestDays,
      homeShotEfficiency: round1(homeShotEff * 100),
      awayShotEfficiency: round1(awayShotEff * 100),
      refereeStat: refStat,
      topScores: top3Scores,
      mathematicalRationale: rationale,
      isSparseData: isSparseData,
      isHighManipulationRisk: isHighRisk,
      manipulationRiskRegion: riskRegion,
      homeElo: effectiveHomeElo,
      awayElo: effectiveAwayElo,
      eloDifference: eloDiff,
      homeXg: homeXg,
      awayXg: awayXg,
    );
  }

  /// Son 5 maçlık form puanı hesaplama: G=3, B=1, M=0
  static int _formPoints(List<String> form) {
    int points = 0;
    for (final res in form.take(5)) {
      if (res.toUpperCase() == 'W' || res.toUpperCase() == 'G') {
        points += 3;
      } else if (res.toUpperCase() == 'D' || res.toUpperCase() == 'B') {
        points += 1;
      }
    }
    return points;
  }

  /// Form çarpanı (0.85 ile 1.15 arası etki)
  static double _calculateFormFactor(List<String> form) {
    if (form.isEmpty) return 1.0;
    final points = _formPoints(form);
    // Maksimum 15 puan -> 0 ile 15 arası
    // 0 puan -> 0.85 katsayısı, 15 puan -> 1.15 katsayısı
    return 0.85 + (points / 15.0) * 0.30;
  }

  /// Türkiye, İtalya ve Fransa lig ve kupa maçlarında şike/manipülasyon ve yüksek varyans kontrolü
  static bool isHighManipulationRiskLeague({
    String? leagueName,
    String? country,
  }) {
    final l = (leagueName ?? '').toLowerCase();
    final c = (country ?? '').toLowerCase();

    // Ülke kontrolü
    final isTurkey = c.contains('turkey') || c.contains('türkiye') || c.contains('tur');
    final isItaly = c.contains('italy') || c.contains('i̇talya') || c.contains('ita');
    final isFrance = c.contains('france') || c.contains('fransa') || c.contains('fra');

    // Lig / Kupa isim kontrolü
    final isTurkeyLeague = l.contains('süper lig') ||
        l.contains('super lig') ||
        l.contains('1. lig') ||
        l.contains('2. lig') ||
        l.contains('türkiye kupası') ||
        l.contains('turkiye kupasi') ||
        l.contains('ziraat') ||
        l.contains('süper kupa');

    final isItalyLeague = l.contains('serie a') ||
        l.contains('serie b') ||
        l.contains('coppa italia') ||
        l.contains('supercoppa');

    final isFranceLeague = l.contains('ligue 1') ||
        l.contains('ligue 2') ||
        l.contains('coupe de france') ||
        l.contains('trophee des champions');

    return isTurkey || isItaly || isFrance || isTurkeyLeague || isItalyLeague || isFranceLeague;
  }

  static String getManipulationRiskCountryName({
    String? leagueName,
    String? country,
  }) {
    final l = (leagueName ?? '').toLowerCase();
    final c = (country ?? '').toLowerCase();
    if (c.contains('turkey') || c.contains('türkiye') || c.contains('tur') || l.contains('lig') || l.contains('ziraat')) {
      return 'Türkiye';
    }
    if (c.contains('italy') || c.contains('i̇talya') || c.contains('ita') || l.contains('serie') || l.contains('coppa')) {
      return 'İtalya';
    }
    if (c.contains('france') || c.contains('fransa') || c.contains('fra') || l.contains('ligue') || l.contains('coupe')) {
      return 'Fransa';
    }
    return 'Bölgesel';
  }
}
