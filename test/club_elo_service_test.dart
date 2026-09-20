import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/services/club_elo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ClubEloService Testleri', () {
    test('Temel kulüp Elo puanları doğru tanımlıdır', () {
      final gsElo = ClubEloService.getTeamElo('Galatasaray');
      final fbElo = ClubEloService.getTeamElo('Fenerbahçe');
      final realElo = ClubEloService.getTeamElo('Real Madrid');
      final cityElo = ClubEloService.getTeamElo('Manchester City');

      expect(gsElo, greaterThanOrEqualTo(1700.0));
      expect(fbElo, greaterThanOrEqualTo(1700.0));
      expect(realElo, greaterThanOrEqualTo(2000.0));
      expect(cityElo, greaterThanOrEqualTo(2000.0));
    });

    test('Bilinmeyen takım için standart lig ortalama puanı (~1480) döner', () {
      final unknownElo = ClubEloService.getTeamElo('Bilinmeyen Köy Spor');
      expect(unknownElo, equals(1480.0));
    });

    test('Elo farkı (Delta Elo) doğru hesaplanır', () {
      final diff = ClubEloService.calculateEloDifference('Real Madrid', 'Galatasaray');
      expect(diff, greaterThan(250.0));
    });

    test('Elo farkına göre gol çarpanları favoriyi ödüllendirir, sürprizi dengeler', () {
      final multipliers = ClubEloService.calculateGoalMultipliers(200.0);
      expect(multipliers.homeMultiplier, greaterThan(1.10));
      expect(multipliers.awayMultiplier, lessThan(0.90));
    });

    test('Lojistik galibiyet beklentisi [0.0 - 1.0] aralığında tutarlıdır', () {
      final pHomeFav = ClubEloService.calculateExpectedWinProbability(250.0);
      final pEven = ClubEloService.calculateExpectedWinProbability(0.0, isNeutral: true);
      final pAwayFav = ClubEloService.calculateExpectedWinProbability(-250.0);

      expect(pHomeFav, greaterThan(0.70));
      expect(pEven, closeTo(0.50, 0.05));
      expect(pAwayFav, lessThan(0.35));
    });
  });
}
