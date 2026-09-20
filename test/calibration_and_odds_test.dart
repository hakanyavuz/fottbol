import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/constants/league_constants.dart';
import 'package:fottbol_prediction/models/head_to_head.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/odds_comparison.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/services/model_calibrator.dart';

Team dummyTeam(String id, String name) => Team(
      id: id,
      name: name,
      shortName: name,
      crestUrl: '',
      league: 'Test Lig',
      venue: 'Stadyum',
      stats: MatchStat.unknown(),
      squad: const [],
    );

void main() {
  group('ModelCalibrator Tests', () {
    test('boş geçmişte literatür taban değerleri döner', () {
      final calib = ModelCalibrator.calibrate([]);
      expect(calib.isDataCalibrated, isFalse);
      expect(calib.calibratedRho, LeagueConstants.dixonColesRho);
      expect(calib.calibratedH2hWeight, LeagueConstants.maxHeadToHeadWeight);
      expect(calib.settledCount, 0);
    });

    test('sonuçlanmış maçlar arttıkça rho ve H2H kalibrasyonu çalışır', () {
      final now = DateTime.now();
      final predictions = List.generate(12, (i) {
        final p = PredictionResult(
          id: 'test_$i',
          homeTeam: dummyTeam('1', 'Ev'),
          awayTeam: dummyTeam('2', 'Dep'),
          predictedHomeGoals: 1,
          predictedAwayGoals: 1,
          lambdaHome: 1.3,
          lambdaAway: 1.1,
          homeWinProbability: 40.0,
          drawProbability: 32.0,
          awayWinProbability: 28.0,
          over25Probability: 45.0,
          bothTeamsToScoreProbability: 55.0,
          topScores: [],
          mathematicalRationale: [],
          fixtureId: 1000 + i,
          matchDate: now.subtract(Duration(days: i + 1)),
          createdAt: now.subtract(Duration(days: i + 2)),
          actualHomeGoals: i % 2 == 0 ? 0 : 1,
          actualAwayGoals: i % 2 == 0 ? 0 : 1, // 0-0 ve 1-1 yoğunluğu
          headToHead: const HeadToHeadSummary(
            played: 6,
            homeTeamWins: 2,
            draws: 2,
            awayTeamWins: 2,
            homeTeamGoalsAvg: 1.0,
            awayTeamGoalsAvg: 1.0,
            recent: [],
          ),
        );
        return p;
      });

      final result = ModelCalibrator.calibrate(predictions);
      expect(result.isDataCalibrated, isTrue);
      expect(result.settledCount, 12);
      expect(result.calibratedRho, lessThanOrEqualTo(0.0));
      expect(result.calibratedH2hWeight, greaterThan(0.0));
      expect(result.summaryText, contains('12 maçlık'));
    });
  });

  group('HeadToHead Time-Decay Tests', () {
    test('HeadToHeadSummary zaman ağırlıklı gol ortalamalarını doğru hesaplar', () {
      const summary = HeadToHeadSummary(
        played: 4,
        homeTeamWins: 2,
        draws: 1,
        awayTeamWins: 1,
        homeTeamGoalsAvg: 2.0,
        awayTeamGoalsAvg: 1.0,
        timeWeightedHomeGoalsAvg: 2.2,
        timeWeightedAwayGoalsAvg: 0.9,
        recent: [],
      );

      expect(summary.weightFor(0.20), closeTo(0.08, 0.001));
      expect(summary.timeWeightedHomeGoalsAvg, 2.2);
      expect(summary.timeWeightedAwayGoalsAvg, 0.9);

      final json = summary.toJson();
      final fromJson = HeadToHeadSummary.fromJson(json);
      expect(fromJson.timeWeightedHomeGoalsAvg, 2.2);
      expect(fromJson.timeWeightedAwayGoalsAvg, 0.9);
    });
  });

  group('OddsComparison Tests', () {
    test('oran marjı ve saf piyasa olasılıkları doğru hesaplanır', () {
      // 1: 2.00, X: 3.40, 2: 3.80
      const odds = BookmakerOdds(
        bookmakerName: 'Bet365',
        homeOdd: 2.00,
        drawOdd: 3.40,
        awayOdd: 3.80,
      );

      // 1/2 + 1/3.4 + 1/3.8 = 0.5 + 0.2941 + 0.2632 = 1.0573
      expect(odds.overround, closeTo(1.057, 0.01));
      expect(odds.marginPercent, closeTo(5.7, 0.5));

      // Saf Piyasa %: 0.5 / 1.0573 * 100 ≈ 47.3%
      expect(odds.marketHomeProbability, closeTo(47.3, 0.5));
    });

    test('OddsComparison model olasılıkları ile kıyaslayıp Value Bet tespit eder', () {
      const odds = BookmakerOdds(
        bookmakerName: 'TestBookmaker',
        homeOdd: 2.20,
        drawOdd: 3.30,
        awayOdd: 3.40,
      );

      // Model: Ev %55, Beraberlik %25, Deplasman %20
      final comparison = OddsComparison.fromModelAndOdds(
        odds: odds,
        modelHomeProb: 55.0,
        modelDrawProb: 25.0,
        modelAwayProb: 20.0,
      );

      // Ev tercihi: Piyasa ~42.5%, Model 55% -> Fark ~+12.5%, EV = (0.55 * 2.20) - 1 = +0.21 (+%21)
      expect(comparison.hasValueBet, isTrue);
      expect(comparison.homeChoice.isValue, isTrue);
      expect(comparison.homeChoice.probabilityDiff, greaterThan(5.0));
      expect(comparison.homeChoice.expectedValue, greaterThan(0.10));
      expect(comparison.bestChoice.outcome, MatchOutcome.home);

      // JSON serialization
      final json = comparison.toJson();
      final parsed = OddsComparison.fromJson(json);
      expect(parsed.odds.bookmakerName, 'TestBookmaker');
      expect(parsed.homeChoice.odd, 2.20);
      expect(parsed.hasValueBet, isTrue);
    });
  });
}
