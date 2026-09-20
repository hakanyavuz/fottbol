import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fottbol_prediction/core/constants/league_constants.dart';
import 'package:fottbol_prediction/core/utils/math_utils.dart';
import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/models/fixture.dart';
import 'package:fottbol_prediction/models/head_to_head.dart';
import 'package:fottbol_prediction/models/match_stat.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/models/team.dart';
import 'package:fottbol_prediction/providers/match_prediction_provider.dart';
import 'package:fottbol_prediction/services/api_football_service.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';
import 'package:fottbol_prediction/widgets/goal_distribution_chart.dart';
import 'package:fottbol_prediction/widgets/head_to_head_card.dart';
import 'package:fottbol_prediction/widgets/score_matrix_heatmap.dart';

Team apiTeam(int id, String name, {MatchStat? stats}) =>
    ApiTeam(id: id, name: name, country: 'TR', logo: '').toTeam(stats: stats);

MatchStat stats({required int homeScored, required int awayScored, required int homeConceded, required int awayConceded}) =>
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
      cleanSheets: 6,
      recentForm: const ['W', 'D', 'L', 'W', 'W'],
    );

Fixture finished(int id, int homeId, int awayId, int hg, int ag, DateTime date) => Fixture(
      id: id,
      date: date,
      statusShort: 'FT',
      leagueId: 203,
      leagueName: 'Süper Lig',
      season: 2025,
      homeTeamId: homeId,
      homeTeamName: 'T$homeId',
      awayTeamId: awayId,
      awayTeamName: 'T$awayId',
      homeGoals: hg,
      awayGoals: ag,
    );

/// Head-to-head çağrılarını sayan sahte servis (ağa çıkmaz)
class H2HSpyService extends ApiFootballService {
  final HeadToHeadSummary? response;
  int calls = 0;

  H2HSpyService(this.response) : super(apiKey: 'test-key');

  @override
  Future<HeadToHeadSummary?> getHeadToHead({
    required int homeTeamId,
    required int awayTeamId,
    int last = 10,
  }) async {
    calls++;
    return response;
  }
}

void main() {
  group('Dixon-Coles düzeltmesi', () {
    test('τ yalnızca 0-0, 0-1, 1-0, 1-1 skorlarını değiştirir', () {
      const l = 1.6, m = 1.1, rho = -0.13;
      expect(MathUtils.dixonColesTau(0, 0, l, m, rho), closeTo(1 - l * m * rho, 1e-12));
      expect(MathUtils.dixonColesTau(0, 1, l, m, rho), closeTo(1 + l * rho, 1e-12));
      expect(MathUtils.dixonColesTau(1, 0, l, m, rho), closeTo(1 + m * rho, 1e-12));
      expect(MathUtils.dixonColesTau(1, 1, l, m, rho), closeTo(1 - rho, 1e-12));
      expect(MathUtils.dixonColesTau(2, 1, l, m, rho), 1.0);
      expect(MathUtils.dixonColesTau(0, 3, l, m, rho), 1.0);
    });

    test('düzeltme toplam olasılık kütlesini korur', () {
      const l = 1.7, m = 1.05, rho = LeagueConstants.dixonColesRho;
      var total = 0.0;
      for (var h = 0; h <= 20; h++) {
        for (var a = 0; a <= 20; a++) {
          total += MathUtils.poissonProbability(h, l) *
              MathUtils.poissonProbability(a, m) *
              MathUtils.dixonColesTau(h, a, l, m, rho);
        }
      }
      expect(total, closeTo(1.0, 1e-9));
    });

    test('uç beklenen gollerde ρ sıkıştırılır, olasılık negatif olmaz', () {
      const l = 4.5, m = 4.5;
      final safe = MathUtils.clampRho(-0.9, l, m);
      expect(safe, greaterThanOrEqualTo(-1 / l));
      for (final (h, a) in [(0, 0), (0, 1), (1, 0), (1, 1)]) {
        expect(MathUtils.dixonColesTau(h, a, l, m, -0.9), greaterThanOrEqualTo(0));
      }
    });

    test('negatif ρ beraberliği ve 0-0 / 1-1 skorlarını artırır', () {
      final home = apiTeam(1, 'Ev', stats: stats(homeScored: 16, awayScored: 12, homeConceded: 11, awayConceded: 14));
      final away = apiTeam(2, 'Dep', stats: stats(homeScored: 15, awayScored: 11, homeConceded: 12, awayConceded: 15));

      final plain = PoissonEngine.calculatePrediction(homeTeam: home, awayTeam: away, rho: 0);
      final dc = PoissonEngine.calculatePrediction(homeTeam: home, awayTeam: away);

      expect(plain.dixonColesRho, 0);
      expect(dc.dixonColesRho, LeagueConstants.dixonColesRho);
      expect(dc.drawProbability, greaterThan(plain.drawProbability));
      expect(dc.scoreMatrix[0][0], greaterThan(plain.scoreMatrix[0][0]));
      expect(dc.scoreMatrix[1][1], greaterThan(plain.scoreMatrix[1][1]));
      expect(dc.scoreMatrix[1][0], lessThan(plain.scoreMatrix[1][0]));
      expect(dc.scoreMatrix[0][1], lessThan(plain.scoreMatrix[0][1]));
    });

    test('matris, 1X2 ve ilk 3 skor aynı toplama normalize edilir', () {
      final r = PoissonEngine.calculatePrediction(
        homeTeam: apiTeam(1, 'A', stats: stats(homeScored: 22, awayScored: 14, homeConceded: 9, awayConceded: 15)),
        awayTeam: apiTeam(2, 'B', stats: stats(homeScored: 14, awayScored: 10, homeConceded: 13, awayConceded: 18)),
      );

      final matrixSum = r.scoreMatrix.expand((row) => row).fold(0.0, (a, b) => a + b);
      expect(matrixSum, closeTo(100, 1e-9));
      expect(r.homeWinProbability + r.drawProbability + r.awayWinProbability, closeTo(100, 0.2));

      final top = r.topScores.first;
      expect(top.probability, closeTo(r.scoreMatrix[top.homeGoals][top.awayGoals], 1e-9));
      expect(r.predictedHomeGoals, top.homeGoals);
    });
  });

  group('Head-to-head', () {
    final fixtures = [
      finished(1, 10, 20, 2, 0, DateTime(2025, 3, 1)), // 10 evde kazandı
      finished(2, 20, 10, 1, 1, DateTime(2024, 10, 1)), // berabere (20 evde)
      finished(3, 20, 10, 3, 1, DateTime(2024, 2, 1)), // 20 evde kazandı
      finished(4, 10, 30, 5, 0, DateTime(2025, 1, 1)), // ilgisiz maç
      Fixture(
        id: 5,
        date: DateTime(2026, 10, 1),
        statusShort: 'NS',
        leagueId: 203,
        leagueName: 'Süper Lig',
        season: 2026,
        homeTeamId: 10,
        homeTeamName: 'T10',
        awayTeamId: 20,
        awayTeamName: 'T20',
      ), // oynanmamış
    ];

    test('özet, bu maçın ev sahibi açısından ve sahadan bağımsız hesaplanır', () {
      final s = HeadToHeadSummary.fromFixtures(fixtures, homeTeamId: 10, awayTeamId: 20);

      expect(s.played, 3); // ilgisiz ve oynanmamış maç dışarıda
      expect(s.homeTeamWins, 1);
      expect(s.draws, 1);
      expect(s.awayTeamWins, 1);
      expect(s.homeTeamGoalsAvg, closeTo((2 + 1 + 1) / 3, 1e-9));
      expect(s.awayTeamGoalsAvg, closeTo((0 + 1 + 3) / 3, 1e-9));
      expect(s.recent.first.date, DateTime(2025, 3, 1)); // en yeni başta
    });

    test('bakış açısı ters çevrilince sonuçlar simetrik değişir', () {
      final s = HeadToHeadSummary.fromFixtures(fixtures, homeTeamId: 20, awayTeamId: 10);
      expect(s.homeTeamWins, 1);
      expect(s.awayTeamWins, 1);
      expect(s.homeTeamGoalsAvg, closeTo(4 / 3, 1e-9));
    });

    test('ağırlık örneklemle artar ve üst sınırda durur', () {
      HeadToHeadSummary withPlayed(int n) => HeadToHeadSummary(
            played: n,
            homeTeamWins: 0,
            draws: n,
            awayTeamWins: 0,
            homeTeamGoalsAvg: 1,
            awayTeamGoalsAvg: 1,
            recent: const [],
          );

      expect(withPlayed(0).weight, 0);
      expect(withPlayed(5).weight, closeTo(LeagueConstants.maxHeadToHeadWeight / 2, 1e-9));
      expect(withPlayed(25).weight, LeagueConstants.maxHeadToHeadWeight);
    });

    test('ev sahibinin baskın olduğu geçmiş beklenen golünü artırır', () {
      final home = apiTeam(10, 'A', stats: stats(homeScored: 15, awayScored: 12, homeConceded: 12, awayConceded: 15));
      final away = apiTeam(20, 'B', stats: stats(homeScored: 15, awayScored: 12, homeConceded: 12, awayConceded: 15));
      const dominant = HeadToHeadSummary(
        played: 10,
        homeTeamWins: 8,
        draws: 1,
        awayTeamWins: 1,
        homeTeamGoalsAvg: 3.2,
        awayTeamGoalsAvg: 0.4,
        recent: [],
      );

      final without = PoissonEngine.calculatePrediction(homeTeam: home, awayTeam: away);
      final withH2H = PoissonEngine.calculatePrediction(homeTeam: home, awayTeam: away, headToHead: dominant);

      expect(withH2H.lambdaHome, greaterThan(without.lambdaHome));
      expect(withH2H.lambdaAway, lessThan(without.lambdaAway));
      expect(withH2H.headToHead, isNotNull);
      expect(withH2H.mathematicalRationale.any((r) => r.contains('Aralarındaki son 10 maç')), true);

      // Ağırlık %15 ile sınırlı: harmanlanmış değer iki uç arasında kalmalı
      final expected = 0.85 * without.lambdaHome + 0.15 * 3.2;
      expect(withH2H.lambdaHome, closeTo(expected, 1e-9));
    });

    test('yeni alanlar JSON üzerinden kayıpsız taşınır', () {
      final r = PoissonEngine.calculatePrediction(
        homeTeam: apiTeam(10, 'A'),
        awayTeam: apiTeam(20, 'B'),
        headToHead: HeadToHeadSummary.fromFixtures(fixtures, homeTeamId: 10, awayTeamId: 20),
      );

      final restored = PredictionResult.fromJson(
        json.decode(json.encode(r.toJson())) as Map<String, dynamic>,
      );

      expect(restored.scoreMatrix.length, 6);
      expect(restored.scoreMatrix[2][1], closeTo(r.scoreMatrix[2][1], 1e-12));
      expect(restored.dixonColesRho, r.dixonColesRho);
      expect(restored.headToHead!.played, 3);
      expect(restored.headToHead!.recent.length, 3);
      expect(restored.homeTeam.dataSource, Team.sourceApiFootball);
    });
  });

  group('Veri kaynağı ayrımı', () {
    test('API-Football kimliği yalnızca o kaynaktan gelen takımda vardır', () {
      expect(apiTeam(645, 'Galatasaray').apiFootballId, 645);

      final customTeam = Team(
        id: 'custom_unknown',
        name: 'Custom',
        shortName: 'CUS',
        crestUrl: '',
        league: 'PL',
        venue: '',
        stats: MatchStat.unknown(),
        squad: const [],
      );
      expect(customTeam.apiFootballId, isNull, reason: 'sayısal olmayan kimlik null döner');
    });

    TestWidgetsFlutterBinding.ensureInitialized();

    Future<MatchPredictionProvider> providerWith(Team home, Team away) async {
      SharedPreferences.setMockInitialValues({});
      final provider = MatchPredictionProvider();
      await Future<void>.delayed(Duration.zero);
      provider.selectHomeTeam(home);
      provider.selectAwayTeam(away);
      return provider;
    }

    test('iki takım da geçerli kimliğe sahipse H2H çekilip modele katılır', () async {
      final spy = H2HSpyService(const HeadToHeadSummary(
        played: 4,
        homeTeamWins: 2,
        draws: 1,
        awayTeamWins: 1,
        homeTeamGoalsAvg: 1.5,
        awayTeamGoalsAvg: 1.0,
        recent: [],
      ));
      final provider = await providerWith(apiTeam(10, 'A'), apiTeam(20, 'B'));

      final result = await provider.executePrediction(service: spy);

      expect(spy.calls, 1);
      expect(result!.headToHead!.played, 4);
    });

    test('sayısal olmayan kimlikli takımlar için H2H sorgusu yapılmaz', () async {
      Team custom(String id) => Team(
            id: id,
            name: 'Custom$id',
            shortName: 'CUS',
            crestUrl: '',
            league: 'PL',
            venue: '',
            stats: MatchStat.unknown(),
            squad: const [],
          );
      final spy = H2HSpyService(null);
      final provider = await providerWith(custom('custom_1'), custom('custom_2'));

      final result = await provider.executePrediction(service: spy);

      expect(spy.calls, 0, reason: 'Sayısal kimlik olmadığından H2H çekilemez');
      expect(result!.headToHead, isNull);
    });
  });

  group('Grafik bileşenleri', () {
    PredictionResult sample() => PoissonEngine.calculatePrediction(
          homeTeam: apiTeam(10, 'Ev FK', stats: stats(homeScored: 20, awayScored: 12, homeConceded: 9, awayConceded: 15)),
          awayTeam: apiTeam(20, 'Dep FK', stats: stats(homeScored: 14, awayScored: 10, homeConceded: 12, awayConceded: 17)),
        );

    Widget host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
          theme: ThemeData(brightness: brightness, useMaterial3: true),
          home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))),
        );

    test('marjinal dağılımlar matris toplamlarıdır', () {
      final r = sample();
      final home = GoalDistributionChart.homeMarginal(r.scoreMatrix);
      final away = GoalDistributionChart.awayMarginal(r.scoreMatrix);

      expect(home.fold(0.0, (a, b) => a + b), closeTo(100, 1e-9));
      expect(away.fold(0.0, (a, b) => a + b), closeTo(100, 1e-9));
      expect(home[0], closeTo(r.scoreMatrix[0].fold(0.0, (a, b) => a + b), 1e-9));
    });

    test('ısı haritası skalası tekdüze koyulaşır', () {
      double lum(double t) => ScoreMatrixHeatmap.colorFor(t, const [
            Color(0xFFDCFCE7),
            Color(0xFF86EFAC),
            Color(0xFF4ADE80),
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF15803D),
            Color(0xFF166534),
          ]).computeLuminance();

      var previous = lum(0);
      for (var i = 1; i <= 20; i++) {
        final current = lum(i / 20);
        expect(current, lessThanOrEqualTo(previous + 1e-9), reason: 't=${i / 20} daha açık olmamalı');
        previous = current;
      }
    });

    for (final brightness in Brightness.values) {
      testWidgets('ısı haritası 36 hücreyi ve en olası skoru çizer ($brightness)', (tester) async {
        final r = sample();
        await tester.pumpWidget(host(ScoreMatrixHeatmap(prediction: r), brightness: brightness));

        expect(find.byType(Tooltip), findsNWidgets(36));
        expect(find.byIcon(Icons.star_rounded), findsNWidgets(2)); // hücre + gösterge
        expect(find.text('Tüm skorlar (tablo)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tablo görünümü açılınca 36 skor listelenir', (tester) async {
      await tester.pumpWidget(host(ScoreMatrixHeatmap(prediction: sample())));
      await tester.ensureVisible(find.text('Tüm skorlar (tablo)'));
      await tester.tap(find.text('Tüm skorlar (tablo)'));
      await tester.pumpAndSettle();

      expect(find.textContaining(' kazanır'), findsWidgets);
      expect(find.text('Beraberlik'), findsNWidgets(6));
    });

    testWidgets('gol dağılımı grafiği iki seri ve gösterge çizer', (tester) async {
      await tester.pumpWidget(host(GoalDistributionChart(prediction: sample())));

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.textContaining('Ev FK · en olası'), findsOneWidget);
      expect(find.textContaining('Dep FK · en olası'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('matrisi olmayan eski kayıtta grafikler gizlenir', (tester) async {
      final old = PredictionResult.fromJson({
        'id': 'eski',
        'homeTeam': {'name': 'A'},
        'awayTeam': {'name': 'B'},
      });
      await tester.pumpWidget(host(Column(children: [
        ScoreMatrixHeatmap(prediction: old),
        GoalDistributionChart(prediction: old),
      ])));

      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('H2H kartı dağılımı ve son maçları gösterir', (tester) async {
      final summary = HeadToHeadSummary.fromFixtures(
        [
          finished(1, 10, 20, 2, 0, DateTime(2025, 3, 1)),
          finished(2, 20, 10, 1, 1, DateTime(2024, 10, 1)),
        ],
        homeTeamId: 10,
        awayTeamId: 20,
      );

      await tester.pumpWidget(host(HeadToHeadCard(summary: summary, homeName: 'T10', awayName: 'T20')));

      expect(find.text('Aralarındaki Son Maçlar'), findsOneWidget);
      expect(find.text('T10 1G'), findsOneWidget);
      expect(find.text('Beraberlik 1'), findsOneWidget);
      expect(find.text('2 - 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
