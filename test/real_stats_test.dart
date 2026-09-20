import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/cache/cache_manager.dart';
import 'package:fottbol_prediction/core/constants/league_constants.dart';
import 'package:fottbol_prediction/core/utils/season_utils.dart';
import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/player.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';

/// API-Football /teams/statistics yanıtının küçültülmüş örneği
Map<String, dynamic> apiFootballStats({
  required int homeScored,
  required int awayScored,
  required int homeConceded,
  required int awayConceded,
  String form = 'WWDLW',
}) =>
    {
      'form': form,
      'fixtures': {
        'played': {'home': 10, 'away': 10, 'total': 20},
        'wins': {'home': 7, 'away': 4, 'total': 11},
        'draws': {'home': 2, 'away': 3, 'total': 5},
        'loses': {'home': 1, 'away': 3, 'total': 4},
      },
      'goals': {
        'for': {
          'total': {'home': homeScored, 'away': awayScored, 'total': homeScored + awayScored},
        },
        'against': {
          'total': {'home': homeConceded, 'away': awayConceded, 'total': homeConceded + awayConceded},
        },
      },
      'clean_sheet': {'home': 5, 'away': 3, 'total': 8},
    };

void main() {
  group('MatchStat gerçek veri ayrıştırma', () {
    test('API-Football istatistik yanıtı doğru çevrilir', () {
      final stat = MatchStat.fromApiFootball(
        apiFootballStats(homeScored: 25, awayScored: 15, homeConceded: 8, awayConceded: 14),
      );

      expect(stat.played, 20);
      expect(stat.homePlayed, 10);
      expect(stat.homeGoalsScored, 25);
      expect(stat.awayGoalsConceded, 14);
      expect(stat.cleanSheets, 8);
      expect(stat.avgHomeGoalsScored, closeTo(2.5, 0.001));
      expect(stat.hasData, true);
      // Topla oynama / şut verisi bu uç noktada yok -> uydurulmamalı
      expect(stat.avgPossession, isNull);
      expect(stat.hasTacticalMetrics, false);
    });

    test('form dizisi en yeni maç başta olacak şekilde ters çevrilir', () {
      // API eskiden yeniye verir: son maç 'L'
      final stat = MatchStat.fromApiFootball(
        apiFootballStats(
          homeScored: 10,
          awayScored: 10,
          homeConceded: 10,
          awayConceded: 10,
          form: 'WWWDL',
        ),
      );

      expect(stat.recentForm, ['L', 'D', 'W', 'W', 'W']);
    });

    test('football-data puan durumu satırları çevrilir', () {
      final stat = MatchStat.fromStandingsRows(
        total: {
          'playedGames': 20,
          'won': 12,
          'draw': 5,
          'lost': 3,
          'goalsFor': 40,
          'goalsAgainst': 18,
          'form': 'W,D,W,W,L',
        },
        home: {'playedGames': 10, 'won': 8, 'draw': 1, 'lost': 1, 'goalsFor': 24, 'goalsAgainst': 6},
        away: {'playedGames': 10, 'won': 4, 'draw': 4, 'lost': 2, 'goalsFor': 16, 'goalsAgainst': 12},
      );

      expect(stat.played, 20);
      expect(stat.avgHomeGoalsScored, closeTo(2.4, 0.001));
      expect(stat.avgAwayGoalsConceded, closeTo(1.2, 0.001));
      expect(stat.recentForm.first, 'L'); // en son maç başta
    });

    test('veri yokken ortalamalar lig baz değerlerine düşer', () {
      final stat = MatchStat.unknown();

      expect(stat.hasData, false);
      expect(stat.avgHomeGoalsScored, LeagueConstants.avgHomeGoals);
      expect(stat.avgAwayGoalsScored, LeagueConstants.avgAwayGoals);
      expect(stat.winRate, 0);
    });
  });

  group('Player ayrıştırma', () {
    test('API-Football oyuncu kaydı çevrilir', () {
      final player = Player.fromApiFootball({
        'player': {'id': 276, 'name': 'Neymar'},
        'statistics': [
          {
            'games': {'appearences': 22, 'position': 'Attacker', 'rating': '8.123456'},
            'goals': {'total': 14, 'assists': 9},
          }
        ],
      });

      expect(player.id, '276');
      expect(player.position, 'Forvet');
      expect(player.goals, 14);
      expect(player.assists, 9);
      expect(player.rating, closeTo(8.12, 0.01));
    });

    test('bileşik pozisyon adları doğru eşlenir', () {
      expect(Player.mapPosition('Attacking Midfield'), 'Orta Saha');
      expect(Player.mapPosition('Centre-Back'), 'Defans');
      expect(Player.mapPosition('Left Winger'), 'Forvet');
      expect(Player.mapPosition('Goalkeeper'), 'Kaleci');
      expect(Player.mapPosition(null), 'Orta Saha');
    });

    test('copyWith sakatlık kalkınca gerekçeyi temizler', () {
      final injured = Player(
        id: '1',
        name: 'Test',
        position: 'Forvet',
        goals: 5,
        assists: 1,
        matchesPlayed: 10,
        rating: 7.5,
        isInjured: true,
        injuryReason: 'Kas yırtığı',
      );

      final healthy = injured.copyWith(isInjured: false);
      expect(healthy.isInjured, false);
      expect(healthy.injuryReason, isNull);
      expect(healthy.attackPenalty, 0.0);
      // Orijinal kayıt değişmemeli (immutable)
      expect(injured.isInjured, true);
    });
  });

  group('Tahmin motoru gerçek veriye tepki veriyor', () {
    test('istatistiksiz iki takım lig ortalaması baz alınarak modellenir', () {
      final a = ApiTeam(id: 1, name: 'A', country: 'TR', logo: '').toTeam();
      final b = ApiTeam(id: 2, name: 'B', country: 'TR', logo: '').toTeam();

      final result = PoissonEngine.calculatePrediction(homeTeam: a, awayTeam: b);

      expect(result.isSparseData, true);
      expect(result.lambdaHome, closeTo(LeagueConstants.avgHomeGoals, 0.001));
      expect(result.lambdaAway, closeTo(LeagueConstants.avgAwayGoals, 0.001));
    });

    test('farklı gerçek istatistikler farklı tahmin üretir (sabit skor regresyonu)', () {
      final strong = ApiTeam(id: 10, name: 'Güçlü', country: 'TR', logo: '').toTeam(
        stats: MatchStat.fromApiFootball(
          apiFootballStats(homeScored: 30, awayScored: 20, homeConceded: 6, awayConceded: 10),
        ),
      );
      final weak = ApiTeam(id: 11, name: 'Zayıf', country: 'TR', logo: '').toTeam(
        stats: MatchStat.fromApiFootball(
          apiFootballStats(homeScored: 8, awayScored: 5, homeConceded: 20, awayConceded: 26),
        ),
      );

      final strongAtHome = PoissonEngine.calculatePrediction(homeTeam: strong, awayTeam: weak);
      final weakAtHome = PoissonEngine.calculatePrediction(homeTeam: weak, awayTeam: strong);

      // Aynı sabit skor değil, verilere göre farklı sonuçlar
      expect(strongAtHome.lambdaHome, greaterThan(weakAtHome.lambdaHome));
      expect(strongAtHome.homeWinProbability, greaterThan(weakAtHome.homeWinProbability));
      expect(
        strongAtHome.predictedScoreString == weakAtHome.predictedScoreString,
        false,
        reason: 'Farklı güçteki takımlar aynı skoru üretmemeli',
      );
    });

    test('tüm olasılıklar aynı toplama normalize edilir', () {
      final a = ApiTeam(id: 1, name: 'A', country: 'TR', logo: '').toTeam(
        stats: MatchStat.fromApiFootball(
          apiFootballStats(homeScored: 22, awayScored: 16, homeConceded: 12, awayConceded: 15),
        ),
      );
      final b = ApiTeam(id: 2, name: 'B', country: 'TR', logo: '').toTeam(
        stats: MatchStat.fromApiFootball(
          apiFootballStats(homeScored: 18, awayScored: 14, homeConceded: 14, awayConceded: 18),
        ),
      );

      final r = PoissonEngine.calculatePrediction(homeTeam: a, awayTeam: b);
      final sum = r.homeWinProbability + r.drawProbability + r.awayWinProbability;

      expect(sum, closeTo(100.0, 0.2));
      expect(r.over25Probability, greaterThan(0));
      expect(r.over25Probability, lessThan(100));
      expect(r.bothTeamsToScoreProbability, greaterThan(0));
    });
  });

  group('Yardımcılar', () {
    test('önbellekten okunan iç içe map derinlemesine normalize edilir', () {
      final raw = <dynamic, dynamic>{
        'league': <dynamic, dynamic>{'id': 203, 'name': 'Süper Lig'},
        'seasons': [
          <dynamic, dynamic>{'year': 2025}
        ],
      };

      final normalized = CacheManager.normalize(raw);
      expect(normalized, isA<Map<String, dynamic>>());
      expect(normalized['league'], isA<Map<String, dynamic>>());
      expect((normalized['seasons'] as List).first, isA<Map<String, dynamic>>());
    });

    test('sezon takvime göre hesaplanır', () {
      expect(SeasonUtils.currentSeason(DateTime(2026, 9, 8)), 2026);
      expect(SeasonUtils.currentSeason(DateTime(2026, 3, 8)), 2025);
      expect(SeasonUtils.recentSeasons(count: 3, now: DateTime(2026, 9, 8)), [2026, 2025, 2024]);
    });
  });
}
