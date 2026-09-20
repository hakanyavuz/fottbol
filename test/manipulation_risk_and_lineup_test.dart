import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/models/value_bet.dart';
import 'package:fottbol_prediction/services/gemini_analysis_service.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';

void main() {
  group('Şike / Manipülasyon ve Yüksek Varyans Koruma Motoru Testleri', () {
    test('Türkiye, İtalya ve Fransa lig/kupaları doğru tespit edilir', () {
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Trendyol Süper Lig'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Trendyol 1. Lig'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Ziraat Türkiye Kupası'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Serie A', country: 'Italy'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Coppa Italia'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Ligue 1', country: 'France'), isTrue);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Coupe de France'), isTrue);

      // İngiltere ve Almanya bu kapsama girmemelidir
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Premier League', country: 'England'), isFalse);
      expect(PoissonEngine.isHighManipulationRiskLeague(leagueName: 'Bundesliga', country: 'Germany'), isFalse);
    });

    test('Riskli liglerde güven skoru %75 tavanı ile sınırlandırılır ve risk rozeti üretilir', () {
      final homeTeam = Team(
        id: '1',
        name: 'Galatasaray',
        shortName: 'GS',
        crestUrl: '',
        league: 'Trendyol Süper Lig',
        venue: 'RAMS Park',
        stats: const MatchStat(
          played: 10,
          won: 8,
          drawn: 2,
          lost: 0,
          goalsScored: 30,
          goalsConceded: 5,
          homePlayed: 5,
          homeWon: 5,
          homeDrawn: 0,
          homeLost: 0,
          homeGoalsScored: 16,
          homeGoalsConceded: 2,
          awayPlayed: 5,
          awayWon: 3,
          awayDrawn: 2,
          awayLost: 0,
          awayGoalsScored: 14,
          awayGoalsConceded: 3,
          cleanSheets: 6,
          recentForm: ['W', 'W', 'W', 'W', 'W'],
        ),
        squad: [],
      );

      final awayTeam = Team(
        id: '2',
        name: 'Kasımpaşa',
        shortName: 'KAS',
        crestUrl: '',
        league: 'Trendyol Süper Lig',
        venue: 'Recep Tayyip Erdoğan',
        stats: const MatchStat(
          played: 10,
          won: 2,
          drawn: 2,
          lost: 6,
          goalsScored: 10,
          goalsConceded: 22,
          homePlayed: 5,
          homeWon: 1,
          homeDrawn: 1,
          homeLost: 3,
          homeGoalsScored: 5,
          homeGoalsConceded: 8,
          awayPlayed: 5,
          awayWon: 1,
          awayDrawn: 1,
          awayLost: 3,
          awayGoalsScored: 5,
          awayGoalsConceded: 14,
          cleanSheets: 1,
          recentForm: ['L', 'L', 'D', 'L', 'L'],
        ),
        squad: [],
      );

      final pred = PoissonEngine.calculatePrediction(homeTeam: homeTeam, awayTeam: awayTeam);

      expect(pred.isHighManipulationRisk, isTrue);
      expect(pred.manipulationRiskRegion, equals('Türkiye'));
      // Normal şartlarda bu maç %85+ güven üretirken, riskli ligde maksimum %75 ile sınırlandırılmış olmalıdır
      expect(pred.confidenceScore, lessThanOrEqualTo(75.0));
      expect(pred.riskLevel, contains('Manipülasyon Riski'));
      expect(pred.mathematicalRationale.any((r) => r.contains('Risk Kalkanı')), isTrue);
    });

    test('Riskli ligdeki ValueBet için Kelly Kasa Payı %30 koruma indirimiyle maksimum %2.5 sınırında tutulur', () {
      final safePred = PredictionResult(
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
        mathematicalRationale: const [],
        isHighManipulationRisk: false,
      );

      final riskPred = PredictionResult(
        id: '2',
        homeTeam: Team(id: '3', name: 'Juventus', shortName: 'JUV', crestUrl: '', league: 'Serie A', venue: 'Allianz', stats: MatchStat.unknown(), squad: []),
        awayTeam: Team(id: '4', name: 'Empoli', shortName: 'EMP', crestUrl: '', league: 'Serie A', venue: 'Castellani', stats: MatchStat.unknown(), squad: []),
        predictedHomeGoals: 2,
        predictedAwayGoals: 0,
        lambdaHome: 2.0,
        lambdaAway: 0.6,
        homeWinProbability: 60.0,
        drawProbability: 22.0,
        awayWinProbability: 18.0,
        over25Probability: 55.0,
        bothTeamsToScoreProbability: 40.0,
        topScores: [],
        mathematicalRationale: const [],
        isHighManipulationRisk: true,
        manipulationRiskRegion: 'İtalya',
      );

      final normalBet = ValueBet(
        matchTitle: 'Arsenal - Chelsea',
        leagueName: 'Premier League',
        selectionLabel: 'MS 1',
        marketOdds: 2.10,
        modelProbability: 60.0,
        impliedProbability: 47.6,
        edgePercentage: 12.4,
        riskCategory: 'Banko',
        prediction: safePred,
      );

      final riskBet = ValueBet(
        matchTitle: 'Juventus - Empoli',
        leagueName: 'Serie A',
        selectionLabel: 'MS 1',
        marketOdds: 2.10,
        modelProbability: 60.0,
        impliedProbability: 47.6,
        edgePercentage: 12.4,
        riskCategory: 'Banko',
        prediction: riskPred,
      );

      // Normal ligde max %5.0 kasa payı verilir
      expect(normalBet.kellyStakePercentage, equals(5.0));

      // Riskli ligde (İtalya) %30 koruma indirimiyle maksimum %2.5 kasa payı verilir
      expect(riskBet.kellyStakePercentage, equals(2.5));
    });

    test('Gemini Taktik Brifingi riskli liglerde Manipülasyon & Varyans Güvenlik Kalkanı maddesini ekler', () {
      final riskPred = PredictionResult(
        id: '3',
        homeTeam: Team(id: '5', name: 'PSG', shortName: 'PSG', crestUrl: '', league: 'Ligue 1', venue: 'Parc des Princes', stats: MatchStat.unknown(), squad: []),
        awayTeam: Team(id: '6', name: 'Lyon', shortName: 'OL', crestUrl: '', league: 'Ligue 1', venue: 'Groupama', stats: MatchStat.unknown(), squad: []),
        predictedHomeGoals: 2,
        predictedAwayGoals: 1,
        lambdaHome: 2.2,
        lambdaAway: 1.1,
        homeWinProbability: 62.0,
        drawProbability: 20.0,
        awayWinProbability: 18.0,
        over25Probability: 60.0,
        bothTeamsToScoreProbability: 55.0,
        topScores: [],
        mathematicalRationale: const [],
        isHighManipulationRisk: true,
        manipulationRiskRegion: 'Fransa',
      );

      final briefing = GeminiAnalysisService.generateManagerBriefing(riskPred);
      expect(briefing.length, equals(4));
      expect(briefing.last['title'], contains('Manipülasyon & Varyans Güvenlik Kalkanı'));
      expect(briefing.last['text'], contains('kasa payı %30 korumaya alınmış'));
    });
  });
}
