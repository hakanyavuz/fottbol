import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/utils/team_name_matcher.dart';
import 'package:fottbol_prediction/models/lineup.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/providers/match_prediction_provider.dart';
import 'package:fottbol_prediction/services/football_offline_repository.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Kadro Geçiş Mekanizması ve Kadro Kalkanı Testleri', () {
    test('Maç önünde gerçek kadrodan Muhtemel 11 başarıyla üretilir', () {
      final kayseriSquad = FootballOfflineRepository.getRealisticSquad(1003, 'Kayserispor');
      expect(kayseriSquad.isNotEmpty, isTrue);

      final kayserispor = Team(
        id: '1003',
        name: 'Kayserispor',
        shortName: 'KAY',
        crestUrl: '',
        league: 'Turkey',
        venue: 'RHG Enertürk Enerji Stadyumu',
        stats: FootballOfflineRepository.getRealisticStats(1003, 'Kayserispor'),
        squad: kayseriSquad,
      );

      final probableLineup = FootballOfflineRepository.generateProbableLineup(kayserispor, isHome: true);
      expect(probableLineup.teamName, equals('Kayserispor'));
      expect(probableLineup.startXI.length, equals(11));
      expect(probableLineup.substitutes.isNotEmpty, isTrue);
      // Kaleci kontrolü
      expect(probableLineup.startXI.any((p) => p.pos == 'G'), isTrue);
      // Gerçek oyuncu isimleri yer almalı (placeholder olmamalı)
      expect(probableLineup.startXI.any((p) => p.name.contains('Kayserispor Oyuncusu') || p.name.contains('Kaptanı')), isFalse);
    });

    test('Kadro Kalkanı: Fenerbahçe - Kayserispor maçına Beşiktaş - Galatasaray kadrosu atanırsa reddedilir', () {
      final fenerbahce = Team(
        id: '1002',
        name: 'Fenerbahçe',
        shortName: 'FB',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Şükrü Saracoğlu',
        stats: FootballOfflineRepository.getRealisticStats(1002, 'Fenerbahçe'),
        squad: FootballOfflineRepository.getRealisticSquad(1002, 'Fenerbahçe'),
      );

      final kayserispor = Team(
        id: '1003',
        name: 'Kayserispor',
        shortName: 'KAY',
        crestUrl: '',
        league: 'Turkey',
        venue: 'RHG Enertürk Enerji Stadyumu',
        stats: FootballOfflineRepository.getRealisticStats(1003, 'Kayserispor'),
        squad: FootballOfflineRepository.getRealisticSquad(1003, 'Kayserispor'),
      );

      // Yanlış maçın resmi kadrosu (Beşiktaş vs Galatasaray)
      final wrongLineups = [
        TeamLineup(
          teamId: 1001,
          teamName: 'Galatasaray',
          teamLogo: '',
          formation: '4-2-3-1',
          startXI: [LineupPlayer(id: 1, name: 'Fernando Muslera', number: 1, pos: 'G')],
          substitutes: [],
        ),
        TeamLineup(
          teamId: 1004,
          teamName: 'Beşiktaş',
          teamLogo: '',
          formation: '4-2-3-1',
          startXI: [LineupPlayer(id: 2, name: 'Mert Günok', number: 34, pos: 'G')],
          substitutes: [],
        ),
      ];

      // MatchPredictionProvider üzerinde doğrulama
      final provider = MatchPredictionProvider();
      provider.selectHomeTeam(fenerbahce);
      provider.selectAwayTeam(kayserispor);

      // Takım eşleşme kontrolü: Galatasaray veya Beşiktaş, Fenerbahçe ve Kayserispor ile ASLA eşleşmemelidir
      final bool teamsMatch = wrongLineups.length >= 2 &&
          ((TeamNameMatcher.matches(wrongLineups[0].teamName, fenerbahce.name) && TeamNameMatcher.matches(wrongLineups[1].teamName, kayserispor.name)) ||
           (TeamNameMatcher.matches(wrongLineups[1].teamName, fenerbahce.name) && TeamNameMatcher.matches(wrongLineups[0].teamName, kayserispor.name)));

      expect(teamsMatch, isFalse, reason: 'Yanlış takım kadrosu kesinlikle reddedilmelidir!');
    });

    test('Doğru resmi kadro geldiğinde takımlar doğrulanır ve resmi kadro onaylanır', () {
      final fenerbahce = Team(
        id: '1002',
        name: 'Fenerbahçe',
        shortName: 'FB',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Şükrü Saracoğlu',
        stats: FootballOfflineRepository.getRealisticStats(1002, 'Fenerbahçe'),
        squad: FootballOfflineRepository.getRealisticSquad(1002, 'Fenerbahçe'),
      );

      final kayserispor = Team(
        id: '1003',
        name: 'Kayserispor',
        shortName: 'KAY',
        crestUrl: '',
        league: 'Turkey',
        venue: 'RHG Enertürk Enerji Stadyumu',
        stats: FootballOfflineRepository.getRealisticStats(1003, 'Kayserispor'),
        squad: FootballOfflineRepository.getRealisticSquad(1003, 'Kayserispor'),
      );

      final officialLineups = [
        TeamLineup(
          teamId: 1002,
          teamName: 'Fenerbahce SK',
          teamLogo: '',
          formation: '4-3-3',
          startXI: [
            LineupPlayer(id: 1, name: 'Dominik Livakovic', number: 40, pos: 'G'),
            LineupPlayer(id: 2, name: 'Bright Osayi-Samuel', number: 21, pos: 'D'),
          ],
          substitutes: [],
        ),
        TeamLineup(
          teamId: 1003,
          teamName: 'Kayserispor FK',
          teamLogo: '',
          formation: '4-2-3-1',
          startXI: [
            LineupPlayer(id: 10, name: 'Bilal Bayazit', number: 1, pos: 'G'),
            LineupPlayer(id: 11, name: 'Duckens Nazon', number: 9, pos: 'F'),
          ],
          substitutes: [],
        ),
      ];

      final bool teamsMatch = officialLineups.length >= 2 &&
          ((TeamNameMatcher.matches(officialLineups[0].teamName, fenerbahce.name) && TeamNameMatcher.matches(officialLineups[1].teamName, kayserispor.name)) ||
           (TeamNameMatcher.matches(officialLineups[1].teamName, fenerbahce.name) && TeamNameMatcher.matches(officialLineups[0].teamName, kayserispor.name)));

      expect(teamsMatch, isTrue, reason: 'Fenerbahce SK ve Kayserispor FK resmi isimleri başarıyla eşleşmelidir.');
    });
  });

  group('Skor Tahmin Çeşitliliği ve xG Dinamik Testleri', () {
    test('Farklı güç dengelerindeki maçlar tekdüze (1-0, 1-1) skorlara kilitlenmez', () {
      final fbSquad = FootballOfflineRepository.getRealisticSquad(1002, 'Fenerbahçe');
      final kaySquad = FootballOfflineRepository.getRealisticSquad(1003, 'Kayserispor');
      final gsSquad = FootballOfflineRepository.getRealisticSquad(1001, 'Galatasaray');
      final bjkSquad = FootballOfflineRepository.getRealisticSquad(1004, 'Beşiktaş');
      final bodrumSquad = FootballOfflineRepository.getRealisticSquad(1019, 'Bodrum FK');
      final hataySquad = FootballOfflineRepository.getRealisticSquad(1013, 'Hatayspor');

      final fb = Team(
        id: '1002',
        name: 'Fenerbahçe',
        shortName: 'FB',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Kadıköy',
        stats: FootballOfflineRepository.getRealisticStats(1002, 'Fenerbahçe'),
        squad: fbSquad,
      );

      final kayseri = Team(
        id: '1003',
        name: 'Kayserispor',
        shortName: 'KAY',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Kayseri',
        stats: FootballOfflineRepository.getRealisticStats(1003, 'Kayserispor'),
        squad: kaySquad,
      );

      final gs = Team(
        id: '1001',
        name: 'Galatasaray',
        shortName: 'GS',
        crestUrl: '',
        league: 'Turkey',
        venue: 'RAMS Park',
        stats: FootballOfflineRepository.getRealisticStats(1001, 'Galatasaray'),
        squad: gsSquad,
      );

      final bjk = Team(
        id: '1004',
        name: 'Beşiktaş',
        shortName: 'BJK',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Tüpraş',
        stats: FootballOfflineRepository.getRealisticStats(1004, 'Beşiktaş'),
        squad: bjkSquad,
      );

      final bodrum = Team(
        id: '1019',
        name: 'Bodrum FK',
        shortName: 'BOD',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Bodrum',
        stats: FootballOfflineRepository.getRealisticStats(1019, 'Bodrum FK'),
        squad: bodrumSquad,
      );

      final hatay = Team(
        id: '1013',
        name: 'Hatayspor',
        shortName: 'HAT',
        crestUrl: '',
        league: 'Turkey',
        venue: 'Mersin',
        stats: FootballOfflineRepository.getRealisticStats(1013, 'Hatayspor'),
        squad: hataySquad,
      );

      // 1. Maç: Fenerbahçe (Güçlü Ev Sahibi) vs Kayserispor
      final pred1 = PoissonEngine.calculatePrediction(homeTeam: fb, awayTeam: kayseri);
      // 2. Maç: Galatasaray vs Beşiktaş (Derbi)
      final pred2 = PoissonEngine.calculatePrediction(homeTeam: gs, awayTeam: bjk);
      // 3. Maç: Bodrum FK vs Hatayspor (Kısır alt sıra maçı)
      final pred3 = PoissonEngine.calculatePrediction(homeTeam: bodrum, awayTeam: hatay);

      final score1 = '${pred1.predictedHomeGoals}-${pred1.predictedAwayGoals}';
      final score2 = '${pred2.predictedHomeGoals}-${pred2.predictedAwayGoals}';
      final score3 = '${pred3.predictedHomeGoals}-${pred3.predictedAwayGoals}';

      final scores = {score1, score2, score3};
      expect(scores.length, greaterThan(1), reason: 'Farklı maçlar farklı beklenen skorlar üretmelidir! Alınanlar: $scores');

      // Fenerbahçe yüksek hücum gücüne (xG > 2.0) sahip olduğu için predictedHomeGoals >= 2 olmalıdır
      expect(pred1.lambdaHome, greaterThan(2.0));
      expect(pred1.predictedHomeGoals, greaterThanOrEqualTo(2), reason: 'Fenerbahçe hücum gücü 2+ gol üretmelidir');
    });
  });
}
