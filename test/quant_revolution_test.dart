import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/head_to_head.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/odds_comparison.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/referee_stat.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/services/dropping_odds_service.dart';
import 'package:fottbol_prediction/services/live_momentum_service.dart';
import 'package:fottbol_prediction/models/match_event.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';
import 'package:fottbol_prediction/services/specialized_markets_engine.dart';

Team _mockTeam({
  required String id,
  required String name,
  required String league,
  int homeGoalsScored = 32,
  int awayGoalsScored = 14,
}) {
  return Team(
    id: id,
    name: name,
    shortName: name.length >= 3 ? name.substring(0, 3).toUpperCase() : name,
    crestUrl: '',
    league: league,
    venue: '$name Stadium',
    squad: const [],
    stats: MatchStat(
      played: 20,
      won: 12,
      drawn: 4,
      lost: 4,
      goalsScored: homeGoalsScored + awayGoalsScored,
      goalsConceded: 18,
      homePlayed: 10,
      homeWon: 8,
      homeDrawn: 1,
      homeLost: 1,
      homeGoalsScored: homeGoalsScored,
      homeGoalsConceded: 7,
      awayPlayed: 10,
      awayWon: 4,
      awayDrawn: 3,
      awayLost: 3,
      awayGoalsScored: awayGoalsScored,
      awayGoalsConceded: 11,
      cleanSheets: 6,
      recentForm: const ['W', 'W', 'D', 'W', 'L'],
    ),
  );
}

void main() {
  group('Faz 1: Bayesian Oran Füzyonu ve Akıllı Tercihler Testleri', () {
    final homeTeam = _mockTeam(id: '1', name: 'Real Madrid', league: 'La Liga', homeGoalsScored: 38);
    final awayTeam = _mockTeam(id: '2', name: 'Getafe', league: 'La Liga', awayGoalsScored: 8);

    test('PoissonEngine Bayesian Oran Füzyonu oranları modelle harmanlar', () {
      const marketOdds = BookmakerOdds(
        bookmakerName: 'Bet365',
        homeOdd: 1.25,
        drawOdd: 6.00,
        awayOdd: 11.00,
        over25Odd: 1.55,
        under25Odd: 2.35,
      );

      final result = PoissonEngine.calculatePrediction(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeElo: 1980.0,
        awayElo: 1540.0,
        marketOdds: marketOdds,
      );

      expect(result.primaryPick, contains('MS 1'));
      expect(result.primaryPickConfidence, greaterThan(60.0));
      expect(result.secondaryPick, isNotEmpty);
      expect(result.safetyPick, isNotEmpty);
      expect(result.mathematicalRationale.any((r) => r.contains('Bayesian Piyasa Füzyonu')), isTrue);
    });

    test('PredictionResult JSON serileştirme yeni quant alanlarını eksiksiz korur', () {
      final pred = PoissonEngine.calculatePrediction(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeElo: 1850.0,
        awayElo: 1550.0,
      );

      final json = pred.toJson();
      expect(json['primaryPick'], isNotNull);
      expect(json['primaryPickConfidence'], isNotNull);
      expect(json['cardCornerPrediction'], isNotNull);
      expect(json['bogeyAnalysis'], isNotNull);

      final restored = PredictionResult.fromJson(json);
      expect(restored.primaryPick, equals(pred.primaryPick));
      expect(restored.primaryPickConfidence, equals(pred.primaryPickConfidence));
      expect(restored.cardCornerPrediction?.recommendedCornerPick, equals(pred.cardCornerPrediction?.recommendedCornerPick));
    });
  });

  group('Faz 3: Canlı Momentum & Düşen Oran Testleri', () {
    test('LiveMomentumService yoğun şut ve gol baskısını tespit eder', () {
      final events = [
        MatchEvent(time: 60, teamName: 'Real Madrid', playerName: 'Vinicius', type: MatchEventType.substitution, detail: 'Shot on target'),
        MatchEvent(time: 63, teamName: 'Real Madrid', playerName: 'Bellingham', type: MatchEventType.substitution, detail: 'Shot on target'),
        MatchEvent(time: 66, teamName: 'Real Madrid', playerName: 'Rodrygo', type: MatchEventType.substitution, detail: 'Corner awarded'),
        MatchEvent(time: 68, teamName: 'Real Madrid', playerName: 'Mbappe', type: MatchEventType.substitution, detail: 'Shot blocked'),
      ];

      final snapshot = LiveMomentumService.analyzeMomentum(
        currentMinute: 70,
        events: events,
        homeTeamName: 'Real Madrid',
        awayTeamName: 'Getafe',
        liveHomeXg: 1.85,
        liveAwayXg: 0.15,
      );

      expect(snapshot.homeMomentum, greaterThan(50.0));
      expect(snapshot.isHomeSurge, isTrue);
      expect(snapshot.tacticalAlert, isNotNull);
      expect(snapshot.tacticalAlert, contains('Canlı Baskı Alarmı'));
    });

    test('DroppingOddsService piyasa oran düşüşlerini listeler', () {
      final home = _mockTeam(id: '1', name: 'Arsenal', league: 'Premier League');
      final away = _mockTeam(id: '2', name: 'Chelsea', league: 'Premier League');

      final dummyPred = PredictionResult(
        id: 'test_drop',
        homeTeam: home,
        awayTeam: away,
        predictedHomeGoals: 2,
        predictedAwayGoals: 0,
        lambdaHome: 2.1,
        lambdaAway: 0.7,
        homeWinProbability: 72.0, // Fair odd = 1.38
        drawProbability: 18.0,
        awayWinProbability: 10.0,
        over25Probability: 60.0,
        bothTeamsToScoreProbability: 45.0,
        topScores: [],
        mathematicalRationale: [],
        oddsComparison: OddsComparison.fromModelAndOdds(
          odds: const BookmakerOdds(
            bookmakerName: 'Market',
            homeOdd: 1.20, // 1.38'den 1.20'ye düşüş (%13.6)
            drawOdd: 4.50,
            awayOdd: 10.50, // Düşüş yok
          ),
          modelHomeProb: 72.0,
          modelDrawProb: 18.0,
          modelAwayProb: 10.0,
        ),
      );

      final drops = DroppingOddsService.analyzeDroppingOdds([dummyPred], minDropPercent: 5.0);
      expect(drops, isNotEmpty);
      expect(drops.first.marketName, contains('MS 1'));
      expect(drops.first.dropPercentage, greaterThan(10.0));
    });
  });

  group('Faz 4: Kartlar, Kornerler ve Kabus Rakip Testleri', () {
    test('SpecializedMarketsEngine korner ve kart olasılıklarını hesaplar', () {
      final homeTeam = _mockTeam(id: '1', name: 'Liverpool', league: 'Premier League');
      final awayTeam = _mockTeam(id: '2', name: 'Everton', league: 'Premier League');
      const referee = RefereeStat(
        name: 'Michael Oliver',
        avgYellowCards: 5.2,
        avgRedCards: 0.35,
        avgFouls: 28.0,
      );

      final prediction = SpecializedMarketsEngine.calculateCardsAndCorners(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        referee: referee,
        isDerby: true,
      );

      expect(prediction.expectedTotalCorners, greaterThan(8.0));
      expect(prediction.recommendedCornerPick, isNotEmpty);
      expect(prediction.expectedTotalCards, greaterThan(5.0));
      expect(prediction.redCardProb, greaterThan(20.0));
    });

    test('SpecializedMarketsEngine Bogey Team (Kabus Rakip) tespit eder', () {
      final giantHome = _mockTeam(id: '1', name: 'Barcelona', league: 'La Liga');
      final bogeyAway = _mockTeam(id: '2', name: 'Celta Vigo', league: 'La Liga');

      const h2h = HeadToHeadSummary(
        homeTeamWins: 1,
        draws: 2,
        awayTeamWins: 3, // Celta Vigo son 6 maçta 3 galibiyet 2 beraberlik almış
        played: 6,
        homeTeamGoalsAvg: 1.2,
        awayTeamGoalsAvg: 1.8,
        recent: [],
      );

      final bogeyReport = SpecializedMarketsEngine.detectBogeyTeam(
        homeTeam: giantHome,
        awayTeam: bogeyAway,
        h2h: h2h,
        homeElo: 1920.0, // Barcelona çok üstün Elo
        awayElo: 1610.0,
      );

      expect(bogeyReport.hasBogeyEffect, isTrue);
      expect(bogeyReport.bogeyTeamName, equals('Celta Vigo'));
      expect(bogeyReport.victimTeamName, equals('Barcelona'));
      expect(bogeyReport.frustrationIndex, greaterThanOrEqualTo(60.0));
      expect(bogeyReport.description, contains('KABUS RAKİP ALARMI'));
    });
  });
}
