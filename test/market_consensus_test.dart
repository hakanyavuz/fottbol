import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/market_consensus.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/odds_comparison.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/services/consensus_engine.dart';

void main() {
  group('Küresel Analiz ve Piyasa Konsensüs Motoru Testleri', () {
    late PredictionResult samplePrediction;
    late BookmakerOdds sampleOdds;

    setUp(() {
      final home = Team(
        id: '1',
        name: 'Galatasaray',
        shortName: 'GS',
        crestUrl: '',
        league: 'Süper Lig',
        venue: 'RAMS Park',
        stats: const MatchStat(
          played: 10, won: 8, drawn: 2, lost: 0,
          goalsScored: 24, goalsConceded: 8,
          homePlayed: 5, homeWon: 5, homeDrawn: 0, homeLost: 0,
          homeGoalsScored: 14, homeGoalsConceded: 3,
          awayPlayed: 5, awayWon: 3, awayDrawn: 2, awayLost: 0,
          awayGoalsScored: 10, awayGoalsConceded: 5,
          cleanSheets: 4, recentForm: ['W', 'W', 'W', 'D', 'W'],
        ),
        squad: [],
      );
      final away = Team(
        id: '2',
        name: 'Fenerbahçe',
        shortName: 'FB',
        crestUrl: '',
        league: 'Süper Lig',
        venue: 'Ülker Stadyumu',
        stats: const MatchStat(
          played: 10, won: 7, drawn: 2, lost: 1,
          goalsScored: 22, goalsConceded: 9,
          homePlayed: 5, homeWon: 4, homeDrawn: 1, homeLost: 0,
          homeGoalsScored: 12, homeGoalsConceded: 4,
          awayPlayed: 5, awayWon: 3, awayDrawn: 1, awayLost: 1,
          awayGoalsScored: 10, awayGoalsConceded: 5,
          cleanSheets: 4, recentForm: ['W', 'W', 'L', 'W', 'W'],
        ),
        squad: [],
      );

      samplePrediction = PredictionResult(
        id: 'test_pred_1',
        homeTeam: home,
        awayTeam: away,
        predictedHomeGoals: 2,
        predictedAwayGoals: 1,
        lambdaHome: 1.7,
        lambdaAway: 1.1,
        homeWinProbability: 52.0,
        drawProbability: 26.0,
        awayWinProbability: 22.0,
        over25Probability: 54.0,
        bothTeamsToScoreProbability: 56.0,
        topScores: [
          ScoreProbability(homeGoals: 2, awayGoals: 1, probability: 11.2),
          ScoreProbability(homeGoals: 1, awayGoals: 1, probability: 10.8),
          ScoreProbability(homeGoals: 2, awayGoals: 0, probability: 9.5),
        ],
        mathematicalRationale: ['Test rationale'],
        confidenceScore: 74.0,
      );

      sampleOdds = const BookmakerOdds(
        bookmakerName: 'Pinnacle',
        homeOdd: 1.95,
        drawOdd: 3.50,
        awayOdd: 4.10,
      );
    });

    test('ConsensusEngine 5 temel referans kaynağını eksiksiz üretir ve ağırlık toplamı 1.0dır', () {
      final consensus = ConsensusEngine.buildConsensus(
        prediction: samplePrediction,
        odds: sampleOdds,
      );

      expect(consensus.sources.length, equals(5));

      // 5 Kaynağın varlığı
      final sourceTypes = consensus.sources.map((s) => s.sourceType).toSet();
      expect(sourceTypes.contains(BenchmarkSourceType.quantModel), isTrue);
      expect(sourceTypes.contains(BenchmarkSourceType.sharpMarket), isTrue);
      expect(sourceTypes.contains(BenchmarkSourceType.domesticMarket), isTrue);
      expect(sourceTypes.contains(BenchmarkSourceType.externalAlgorithm), isTrue);
      expect(sourceTypes.contains(BenchmarkSourceType.community), isTrue);

      // Ağırlıkların toplamı tam 1.0 olmalıdır
      final totalWeight = consensus.sources.fold<double>(0.0, (sum, s) => sum + s.weight);
      expect(totalWeight, closeTo(1.0, 0.001));

      // Harmanlanmış olasılık toplamı %100 olmalıdır
      final blendSum = consensus.blendedHomeProbability +
          consensus.blendedDrawProbability +
          consensus.blendedAwayProbability;
      expect(blendSum, closeTo(100.0, 0.5));
    });

    test('Piyasa ile model aynı fikirdeyse güçlü mutabakat (Strong Consensus) tespit edilir', () {
      final consensus = ConsensusEngine.buildConsensus(
        prediction: samplePrediction,
        odds: sampleOdds,
      );

      // Hem FOTTBOL hem de Pinnacle ev sahibini açık favori görüyor
      expect(consensus.agreementScore, greaterThanOrEqualTo(65.0));
      expect(
        consensus.agreementStatus == ConsensusAgreementStatus.strongConsensus ||
            consensus.agreementStatus == ConsensusAgreementStatus.moderateConsensus,
        isTrue,
      );
      expect(consensus.blendedOutcome, equals(MatchOutcome.home));
    });

    test('Model ile piyasa zıt yöne baktığında Ters Köşe (Contrarian Edge) tespit edilir', () {
      // Model Ev Sahibini %60 favori görüyor ama büro Deplasmanı %55 favori gösteriyor (Ters durum)
      const contrarianOdds = BookmakerOdds(
        bookmakerName: 'Pinnacle',
        homeOdd: 4.20, // ~%22
        drawOdd: 3.40, // ~%27
        awayOdd: 1.85, // ~%51
      );

      final contrarianPred = PredictionResult(
        id: 'contrarian_test',
        homeTeam: samplePrediction.homeTeam,
        awayTeam: samplePrediction.awayTeam,
        predictedHomeGoals: 2,
        predictedAwayGoals: 0,
        lambdaHome: 2.1,
        lambdaAway: 0.8,
        homeWinProbability: 62.0,
        drawProbability: 23.0,
        awayWinProbability: 15.0,
        over25Probability: 50.0,
        bothTeamsToScoreProbability: 45.0,
        topScores: [ScoreProbability(homeGoals: 2, awayGoals: 0, probability: 13.0)],
        mathematicalRationale: [],
      );

      final consensus = ConsensusEngine.buildConsensus(
        prediction: contrarianPred,
        odds: contrarianOdds,
      );

      expect(consensus.agreementStatus, equals(ConsensusAgreementStatus.contrarianEdge));
      expect(consensus.contrarianReason, isNotNull);
      expect(consensus.statusSummary, contains('Ters Köşe'));
    });

    test('MarketConsensus JSON serileştirme ve geri yükleme kayıpsız çalışır', () {
      final consensus = ConsensusEngine.buildConsensus(
        prediction: samplePrediction,
        odds: sampleOdds,
      );

      final json = consensus.toJson();
      final recovered = MarketConsensus.fromJson(json);

      expect(recovered.sources.length, equals(consensus.sources.length));
      expect(recovered.agreementScore, equals(consensus.agreementScore));
      expect(recovered.agreementStatus, equals(consensus.agreementStatus));
      expect(recovered.blendedHomeProbability, equals(consensus.blendedHomeProbability));
      expect(recovered.blendedScoreString, equals(consensus.blendedScoreString));
    });

    test('PredictionResult içerisine consensus yerleşir ve JSON dönüşümü sorunsuz çalışır', () {
      final consensus = ConsensusEngine.buildConsensus(
        prediction: samplePrediction,
        odds: sampleOdds,
      );
      samplePrediction.consensus = consensus;

      final json = samplePrediction.toJson();
      expect(json['consensus'], isNotNull);

      final recovered = PredictionResult.fromJson(json);
      expect(recovered.consensus, isNotNull);
      expect(recovered.consensus!.sources.length, equals(5));
      expect(recovered.consensus!.blendedScoreString, equals(consensus.blendedScoreString));
    });
  });
}
