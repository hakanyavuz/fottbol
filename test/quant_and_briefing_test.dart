import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/coupon_slip.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/odds_comparison.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/referee_stat.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/models/value_bet.dart';
import 'package:fottbol_prediction/services/gemini_analysis_service.dart';

void main() {
  group('Faz 5: Kelly Kriteri ve Quant Kasa Yönetimi Testleri', () {
    test('ValueBet Kelly Kasa Payı formülü (Half-Kelly) doğru ve sınırlandırılmış hesaplanır', () {
      final dummyPred = PredictionResult(
        id: '1',
        homeTeam: Team(id: '1', name: 'Arsenal', shortName: 'ARS', crestUrl: '', league: 'Premier League', venue: 'Emirates', stats: MatchStat.unknown(), squad: []),
        awayTeam: Team(id: '2', name: 'Chelsea', shortName: 'CHE', crestUrl: '', league: 'Premier League', venue: 'Stamford Bridge', stats: MatchStat.unknown(), squad: []),
        predictedHomeGoals: 2,
        predictedAwayGoals: 1,
        lambdaHome: 1.8,
        lambdaAway: 1.0,
        homeWinProbability: 60.0,
        drawProbability: 22.0,
        awayWinProbability: 18.0,
        over25Probability: 55.0,
        bothTeamsToScoreProbability: 52.0,
        topScores: [],
        mathematicalRationale: const ['Poisson analizi'],
        oddsComparison: OddsComparison.fromModelAndOdds(
          odds: const BookmakerOdds(
            bookmakerName: 'Pinnacle',
            homeOdd: 2.10,
            drawOdd: 3.40,
            awayOdd: 3.60,
          ),
          modelHomeProb: 60.0,
          modelDrawProb: 22.0,
          modelAwayProb: 18.0,
        ),
      );

      // Piyasa Oranı: 2.10, Model Olasılığı: %60.0
      // İmplied Prob = 1 / 2.10 = %47.6 -> Edge = +%12.4
      final valueBets = ValueBet.findValueBets(dummyPred);
      expect(valueBets, isNotEmpty);
      final bet = valueBets.first;

      // Kelly formülü: b = 1.10, p = 0.60, q = 0.40 -> fullKelly = (1.10*0.60 - 0.40)/1.10 = 0.236
      // Half-Kelly = 0.236 * 0.5 * 100 = %11.8 -> max %5.0 ile sınırlandırılır
      expect(bet.kellyStakePercentage, equals(5.0));

      // Düşük avantajlı bir bahis senaryosu
      final marginalBet = ValueBet(
        matchTitle: 'Test - Test',
        leagueName: 'Test Lig',
        selectionLabel: 'MS 1',
        marketOdds: 2.0,
        modelProbability: 53.0, // Implied 50%, Edge %3
        impliedProbability: 50.0,
        edgePercentage: 3.0,
        riskCategory: 'Dengeli',
        prediction: dummyPred,
      );
      // b = 1.0, p = 0.53, q = 0.47 -> fullKelly = (1.0*0.53 - 0.47)/1.0 = 0.06
      // Half-Kelly = 0.06 * 0.5 * 100 = %3.0
      expect(marginalBet.kellyStakePercentage, closeTo(3.0, 0.2));
    });

    test('CouponSlip gerçek bileşik çarpımsal olasılık ve Beklenen Değer (EV) hesaplar', () {
      final slip = CouponSlip(
        title: 'Günün Bankoları',
        category: 'Banko',
        totalOdds: 2.50,
        combinedConfidenceScore: 70.0, // Aritmetik ortalama %70
        items: const [
          CouponItem(
            matchTitle: 'Galatasaray - Kasımpaşa',
            leagueName: 'Süper Lig',
            selectionLabel: 'MS 1',
            odds: 1.35,
            confidenceScore: 75.0, // 0.75
            riskCategory: 'Banko',
          ),
          CouponItem(
            matchTitle: 'Real Madrid - Getafe',
            leagueName: 'La Liga',
            selectionLabel: 'MS 1',
            odds: 1.30,
            confidenceScore: 80.0, // 0.80
            riskCategory: 'Banko',
          ),
          CouponItem(
            matchTitle: 'Bayern - Augsburg',
            leagueName: 'Bundesliga',
            selectionLabel: '2.5 Üst',
            odds: 1.42,
            confidenceScore: 70.0, // 0.70
            riskCategory: 'Banko',
          ),
        ],
      );

      // Gerçek çarpımsal ihtimal: 0.75 * 0.80 * 0.70 = 0.42 (%42.0)
      expect(slip.jointProbabilityPercentage, closeTo(42.0, 0.5));

      // Beklenen Değer (EV): (0.42 * 2.50 - 1) * 100 = (1.05 - 1) * 100 = +%5.0
      expect(slip.expectedValuePercentage, closeTo(5.0, 1.0));

      // Kombinede Quarter-Kelly kasa payı güvenli aralıkta olmalı (0.5 - 3.0)
      expect(slip.kellyStakeRecommendation, greaterThanOrEqualTo(0.5));
      expect(slip.kellyStakeRecommendation, lessThanOrEqualTo(3.0));
    });
  });

  group('Faz 4: Teknik Direktör Brifingi ve Hakem Analiz Testleri', () {
    test('GeminiAnalysisService 3 kritik başlıklı Teknik Direktör Taktik Hapı üretir', () {
      final dummyPred = PredictionResult(
        id: '10',
        homeTeam: Team(id: '1', name: 'Fenerbahçe', shortName: 'FB', crestUrl: '', league: 'Süper Lig', venue: 'Kadıköy', stats: MatchStat.unknown(), squad: []),
        awayTeam: Team(id: '2', name: 'Beşiktaş', shortName: 'BJK', crestUrl: '', league: 'Süper Lig', venue: 'Tüpraş', stats: MatchStat.unknown(), squad: []),
        predictedHomeGoals: 2,
        predictedAwayGoals: 1,
        lambdaHome: 1.7,
        lambdaAway: 1.2,
        homeWinProbability: 52.0,
        drawProbability: 26.0,
        awayWinProbability: 22.0,
        over25Probability: 58.0,
        bothTeamsToScoreProbability: 56.0,
        topScores: [],
        mathematicalRationale: const ['Poisson analizi'],
        refereeStat: RefereeStat.forName('Turgut Doman'),
      );

      final briefing = GeminiAnalysisService.generateManagerBriefing(dummyPred);
      expect(briefing.length, equals(3));
      
      // 1. Oyun Planı & Tempo
      expect(briefing[0]['title'], contains('Oyun Planı'));
      expect(briefing[0]['text'], contains('Fenerbahçe'));

      // 2. Kadro & Zafiyet
      expect(briefing[1]['title'], contains('Kadro'));

      // 3. Hakem & Disiplin
      expect(briefing[2]['title'], contains('Hakem'));
      expect(briefing[2]['text'], contains('Turgut Doman'));
    });
  });
}
