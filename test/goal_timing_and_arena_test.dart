import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/models/goal_timing_distribution.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/models/weather_pitch_condition.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';

Team testTeam(int id, String name, {MatchStat? stats}) =>
    ApiTeam(id: id, name: name, country: 'TR', logo: '').toTeam(stats: stats);

MatchStat testStats({
  required int homeScored,
  required int awayScored,
  required int homeConceded,
  required int awayConceded,
}) =>
    MatchStat(
      played: 20,
      won: 10,
      drawn: 5,
      lost: 5,
      goalsScored: homeScored + awayScored,
      goalsConceded: homeConceded + awayConceded,
      homePlayed: 10,
      homeWon: 6,
      homeDrawn: 2,
      homeLost: 2,
      homeGoalsScored: homeScored,
      homeGoalsConceded: homeConceded,
      awayPlayed: 10,
      awayWon: 4,
      awayDrawn: 3,
      awayLost: 3,
      awayGoalsScored: awayScored,
      awayGoalsConceded: awayConceded,
      cleanSheets: 5,
      recentForm: ['W', 'W', 'D', 'W', 'W'],
    );

void main() {
  group('GoalTimingDistribution & Arena Testleri', () {
    test('Gol zamanlama dağılımı 6 periyot üretir ve yüzdeler pozitiftir', () {
      final timing = GoalTimingDistribution.calculate(
        lambdaHome: 1.85,
        lambdaAway: 1.10,
      );

      expect(timing.totalIntervals.length, 6);
      expect(timing.homeIntervals.length, 6);
      expect(timing.awayIntervals.length, 6);

      // İkinci yarı yorgunluk ve risk alma faktöründen dolayı ilk yarıdan yüksek olmalı
      expect(timing.secondHalfGoalProb, greaterThan(timing.firstHalfGoalProb));
      expect(timing.peakInterval, isNotEmpty);
    });

    test('Nötr saha seçildiğinde PoissonEngine ev sahibi avantajını dengeler', () {
      final teamA = testTeam(
        1,
        'Galatasaray',
        stats: testStats(homeScored: 24, awayScored: 18, homeConceded: 8, awayConceded: 12),
      );

      final teamB = testTeam(
        2,
        'Fenerbahçe',
        stats: testStats(homeScored: 22, awayScored: 16, homeConceded: 10, awayConceded: 11),
      );

      final standardPred = PoissonEngine.calculatePrediction(
        homeTeam: teamA,
        awayTeam: teamB,
        isNeutralGround: false,
      );

      final neutralPred = PoissonEngine.calculatePrediction(
        homeTeam: teamA,
        awayTeam: teamB,
        isNeutralGround: true,
      );

      // Nötr sahada ev sahibi avantajı silindiğinden Team A'nın lambdası daha düşük olmalıdır
      expect(neutralPred.lambdaHome, lessThan(standardPred.lambdaHome));
    });

    test('Ağır hava koşulu (heavyRain) toplam gol beklentisini düşürür', () {
      final teamA = testTeam(
        1,
        'Takım A',
        stats: testStats(homeScored: 20, awayScored: 15, homeConceded: 10, awayConceded: 12),
      );

      final clearPred = PoissonEngine.calculatePrediction(
        homeTeam: teamA,
        awayTeam: teamA,
        weatherCondition: WeatherCondition.clear,
      );

      final rainyPred = PoissonEngine.calculatePrediction(
        homeTeam: teamA,
        awayTeam: teamA,
        weatherCondition: WeatherCondition.heavyRain,
      );

      expect(rainyPred.lambdaHome, lessThan(clearPred.lambdaHome));
    });
  });
}
