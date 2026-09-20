import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

Team apiTeam(int id, String name, {MatchStat? stats}) =>
    ApiTeam(id: id, name: name, country: 'TR', logo: '').toTeam(stats: stats);

MatchStat testStat({
  required int homeScored,
  required int awayScored,
  required int homeConceded,
  required int awayConceded,
  List<String> form = const ['W', 'D', 'W', 'W', 'L'],
}) =>
    MatchStat(
      played: 20,
      won: 10,
      drawn: 5,
      lost: 5,
      cleanSheets: 7,
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
      recentForm: form,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('PoissonEngine Elo & xG Entegrasyon Testleri', () {
    final homeTeam = apiTeam(
      1,
      'Galatasaray',
      stats: testStat(homeScored: 24, awayScored: 21, homeConceded: 8, awayConceded: 10),
    );

    final awayTeam = apiTeam(
      2,
      'Kayserispor',
      stats: testStat(homeScored: 12, awayScored: 9, homeConceded: 14, awayConceded: 18),
    );

    test('Club Elo ve xG parametreleri PredictionResult üzerine taşınır ve gerekçeye eklenir', () {
      final prediction = PoissonEngine.calculatePrediction(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeElo: 1735.0,
        awayElo: 1465.0,
        homeXg: 2.65,
        awayXg: 0.75,
        homeRestDays: 7,
        awayRestDays: 3,
      );

      expect(prediction.homeElo, equals(1735.0));
      expect(prediction.awayElo, equals(1465.0));
      expect(prediction.eloDifference, equals(270.0));
      expect(prediction.homeXg, equals(2.65));
      expect(prediction.awayXg, equals(0.75));
      expect(prediction.homeRestDays, equals(7));
      expect(prediction.awayRestDays, equals(3));

      // Gerekçelerde Elo ve xG yer almalıdır
      final hasEloRationale = prediction.mathematicalRationale.any((r) => r.contains('Club Elo Güç Endeksi'));
      final hasXgRationale = prediction.mathematicalRationale.any((r) => r.contains('xG Kalite Ayarı'));
      final hasRestRationale = prediction.mathematicalRationale.any((r) => r.contains('dinlendi'));

      expect(hasEloRationale, isTrue);
      expect(hasXgRationale, isTrue);
      expect(hasRestRationale, isTrue);

      // Güçlü ev sahibi lehine yüksek kazanma olasılığı
      expect(prediction.homeWinProbability, greaterThan(prediction.awayWinProbability));
    });

    test('Elo farkı büyük olduğunda ev sahibinin beklenen golü artar', () {
      final predWithElo = PoissonEngine.calculatePrediction(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeElo: 1800.0,
        awayElo: 1300.0,
      );

      final predWithoutElo = PoissonEngine.calculatePrediction(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeElo: 1500.0,
        awayElo: 1500.0,
      );

      expect(predWithElo.lambdaHome, greaterThan(predWithoutElo.lambdaHome));
      expect(predWithElo.lambdaAway, lessThan(predWithoutElo.lambdaAway));
    });
  });
}
