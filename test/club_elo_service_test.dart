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

    test('Bilinmeyen takım için deterministik orta sıra lig puanı (1385-1610) döner', () {
      final unknownElo1 = ClubEloService.getTeamElo('Bilinmeyen Köy Spor');
      final unknownElo2 = ClubEloService.getTeamElo('Farklı Kasaba FK');
      expect(unknownElo1, inInclusiveRange(1385.0, 1610.0));
      expect(unknownElo2, inInclusiveRange(1385.0, 1610.0));
      expect(unknownElo1, isNot(equals(unknownElo2)));
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
