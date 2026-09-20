import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/models/fixture.dart';
import 'package:fottbol_prediction/models/prediction_result.dart';
import 'package:fottbol_prediction/providers/match_prediction_provider.dart';
import 'package:fottbol_prediction/services/api_football_service.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';
import 'package:fottbol_prediction/views/league_fixtures_view.dart';

/// API-Football /fixtures yanıtındaki tek maçın küçültülmüş örneği
Map<String, dynamic> fixtureJson({
  int id = 1001,
  String status = 'FT',
  int? homeGoals = 2,
  int? awayGoals = 1,
  String date = '2026-09-06T17:00:00+00:00',
}) =>
    {
      'fixture': {
        'id': id,
        'date': date,
        'status': {'long': 'Match Finished', 'short': status, 'elapsed': 90},
        'venue': {'name': 'RAMS Park', 'city': 'İstanbul'},
      },
      'league': {
        'id': 203,
        'name': 'Süper Lig',
        'country': 'Turkey',
        'logo': '',
        'season': 2026,
        'round': 'Regular Season - 4',
      },
      'teams': {
        'home': {'id': 645, 'name': 'Galatasaray', 'logo': '', 'winner': true},
        'away': {'id': 611, 'name': 'Fenerbahçe', 'logo': '', 'winner': false},
      },
      'goals': {'home': homeGoals, 'away': awayGoals},
      'score': {
        'halftime': {'home': 1, 'away': 0},
        'fulltime': {'home': homeGoals, 'away': awayGoals},
      },
    };

/// Belirli skor ve olasılıklarla test tahmini üretir
PredictionResult makePrediction({
  int predictedHome = 2,
  int predictedAway = 1,
  double homeWin = 50,
  double draw = 25,
  double awayWin = 25,
  double over25 = 60,
  double btts = 55,
  int? actualHome,
  int? actualAway,
  int? fixtureId = 1001,
  DateTime? matchDate,
  DateTime? createdAt,
}) {
  final team = ApiTeam(id: 1, name: 'A', country: 'TR', logo: '').toTeam();
  return PredictionResult(
    id: 'p_${fixtureId ?? DateTime.now().microsecondsSinceEpoch}',
    homeTeam: team,
    awayTeam: team,
    predictedHomeGoals: predictedHome,
    predictedAwayGoals: predictedAway,
    lambdaHome: 1.6,
    lambdaAway: 1.1,
    homeWinProbability: homeWin,
    drawProbability: draw,
    awayWinProbability: awayWin,
    over25Probability: over25,
    bothTeamsToScoreProbability: btts,
    topScores: [
      ScoreProbability(homeGoals: predictedHome, awayGoals: predictedAway, probability: 12),
      ScoreProbability(homeGoals: 1, awayGoals: 1, probability: 11),
      ScoreProbability(homeGoals: 1, awayGoals: 0, probability: 10),
    ],
    mathematicalRationale: const [],
    fixtureId: fixtureId,
    matchDate: matchDate ?? DateTime(2026, 9, 6, 20),
    createdAt: createdAt ?? DateTime(2026, 9, 5),
    actualHomeGoals: actualHome,
    actualAwayGoals: actualAway,
  );
}

/// Ağa çıkmadan önceden belirlenmiş maç sonucu döndüren sahte servis
class FakeApiFootballService extends ApiFootballService {
  final Map<int, Fixture> fixtures;
  final List<int> requestedIds = [];

  FakeApiFootballService(this.fixtures) : super(apiKey: 'test-key');

  @override
  Future<Fixture?> getFixtureById(int fixtureId, {bool forceRefresh = false}) async {
    requestedIds.add(fixtureId);
    return fixtures[fixtureId];
  }
}

void main() {
  group('Fixture ayrıştırma', () {
    test('biten maç doğru çevrilir', () {
      final f = Fixture.fromApiFootball(fixtureJson());

      expect(f.id, 1001);
      expect(f.homeTeamName, 'Galatasaray');
      expect(f.awayTeamId, 611);
      expect(f.leagueId, 203);
      expect(f.season, 2026);
      expect(f.isFinished, true);
      expect(f.isUpcoming, false);
      expect(f.scoreString, '2 - 1');
      expect(f.statusLabel, 'Bitti');
    });

    test('oynanmamış maçta skor yoktur', () {
      final f = Fixture.fromApiFootball(fixtureJson(status: 'NS', homeGoals: null, awayGoals: null));

      expect(f.isUpcoming, true);
      expect(f.hasScore, false);
      expect(f.scoreString, '-');
    });

    test('ertelenen ve canlı maç durumları tanınır', () {
      expect(Fixture.fromApiFootball(fixtureJson(status: 'PST')).isCancelled, true);
      final live = Fixture.fromApiFootball(fixtureJson(status: '2H'));
      expect(live.isLive, true);
      expect(live.statusLabel, "90'");
    });

    test('eksik alanlarda çökmez', () {
      final f = Fixture.fromApiFootball(const {});
      expect(f.id, 0);
      expect(f.date, isNull);
      expect(f.isUpcoming, true);
    });
  });

  group('İsabet değerlendirmesi', () {
    test('tam skor, 1X2, 2.5 üst ve KG var isabetleri', () {
      final p = makePrediction(actualHome: 2, actualAway: 1);

      expect(p.isExactScoreHit, true);
      expect(p.isOutcomeHit, true);
      expect(p.isOver25Hit, true); // 3 gol, tahmin %60 üst
      expect(p.isBttsHit, true); // iki takım da attı, tahmin %55 var
      expect(p.isTop3ScoreHit, true);
    });

    test('yanlış tahminde isabetler false döner', () {
      final p = makePrediction(actualHome: 0, actualAway: 0);

      expect(p.isExactScoreHit, false);
      expect(p.isOutcomeHit, false); // 1 dendi, X oldu
      expect(p.isOver25Hit, false);
      expect(p.isBttsHit, false);
      expect(p.isTop3ScoreHit, false);
    });

    test('sonuç yokken isabet belirsizdir (null)', () {
      final p = makePrediction();
      expect(p.hasResult, false);
      expect(p.isOutcomeHit, isNull);
    });

    test('model 1X2 tercihini en yüksek olasılıktan seçer', () {
      expect(makePrediction(homeWin: 30, draw: 40, awayWin: 30).predictedOutcome, MatchOutcome.draw);
      expect(makePrediction(homeWin: 20, draw: 30, awayWin: 50).predictedOutcome, MatchOutcome.away);
    });

    test('maç başladıktan sonra yapılan tahmin karneye sayılmaz', () {
      final late = makePrediction(
        actualHome: 2,
        actualAway: 1,
        matchDate: DateTime(2026, 9, 6, 20),
        createdAt: DateTime(2026, 9, 6, 22),
      );

      expect(late.isPreMatch, false);
      expect(late.isScorable, false);
      expect(PredictionAccuracy.from([late]).settled, 0);
    });

    test('fikstüre bağlı olmayan serbest tahmin karneye sayılmaz', () {
      final free = makePrediction(fixtureId: null, actualHome: 2, actualAway: 1);
      expect(free.isScorable, false);
    });

    test('karne oranları doğru hesaplanır', () {
      final accuracy = PredictionAccuracy.from([
        makePrediction(fixtureId: 1, actualHome: 2, actualAway: 1), // tam isabet
        makePrediction(fixtureId: 2, actualHome: 3, actualAway: 0), // 1X2 isabet
        makePrediction(fixtureId: 3, actualHome: 0, actualAway: 2), // ıska
        makePrediction(fixtureId: 4), // sonuç yok -> sayılmaz
      ]);

      expect(accuracy.settled, 3);
      expect(accuracy.exactScoreHits, 1);
      expect(accuracy.outcomeHits, 2);
      expect(accuracy.outcomeRate, closeTo(66.7, 0.1));
      expect(accuracy.exactScoreRate, closeTo(33.3, 0.1));
    });

    test('ertelenen maç sonuç beklemez', () {
      final p = makePrediction(matchDate: DateTime(2026, 1, 1), createdAt: DateTime(2025, 12, 30))
        ..fixtureStatus = 'PST';
      expect(p.isAwaitingResult, false);
    });

    test('yeni alanlar JSON üzerinden kayıpsız taşınır', () {
      final original = makePrediction(actualHome: 1, actualAway: 1)
        ..fixtureStatus = 'FT'
        ..resultCheckedAt = DateTime(2026, 9, 7);

      final restored = PredictionResult.fromJson(
        json.decode(json.encode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.fixtureId, 1001);
      expect(restored.matchDate, original.matchDate);
      expect(restored.actualScoreString, '1 - 1');
      expect(restored.fixtureStatus, 'FT');
      expect(restored.resultCheckedAt, DateTime(2026, 9, 7));
      expect(restored.isScorable, true);
    });
  });

  group('Tahmin motoru fikstür bağlamı', () {
    test('aynı maç tekrar tahmin edilince sabit id kullanılır', () {
      final a = ApiTeam(id: 1, name: 'A', country: 'TR', logo: '').toTeam();
      final b = ApiTeam(id: 2, name: 'B', country: 'TR', logo: '').toTeam();

      final first = PoissonEngine.calculatePrediction(homeTeam: a, awayTeam: b, fixtureId: 555);
      final second = PoissonEngine.calculatePrediction(homeTeam: a, awayTeam: b, fixtureId: 555);

      expect(first.id, 'fixture_555');
      expect(second.id, first.id);
      expect(first.fixtureId, 555);
    });
  });

  group('Sonuç kontrolü (provider + sahte servis)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('oynanmış maçın gerçek skoru çekilir ve karne güncellenir', () async {
      final pending = makePrediction(
        fixtureId: 1001,
        matchDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      final notYetPlayed = makePrediction(
        fixtureId: 2002,
        matchDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );

      SharedPreferences.setMockInitialValues({
        'saved_predictions': [
          json.encode(pending.toJson()),
          json.encode(notYetPlayed.toJson()),
        ],
      });

      final provider = MatchPredictionProvider();
      await provider.loadPastPredictions();
      expect(provider.pastPredictions.where((p) => p.isAwaitingResult).length, 1);

      final service = FakeApiFootballService({
        1001: Fixture.fromApiFootball(fixtureJson(id: 1001, homeGoals: 2, awayGoals: 1)),
      });

      final updated = await provider.refreshResults(service);

      expect(updated, 1);
      // Henüz oynanmamış maç için istek atılmamalı (kota koruması)
      expect(service.requestedIds, [1001]);

      final settled = provider.pastPredictions.firstWhere((p) => p.fixtureId == 1001);
      expect(settled.actualScoreString, '2 - 1');
      expect(provider.accuracy.settled, 1);
      expect(provider.accuracy.exactScoreHits, 1);

      // Sonuç kalıcı olarak kaydedilmiş olmalı
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('saved_predictions')!;
      expect(stored.length, 2, reason: 'Güncelleme kopya kayıt oluşturmamalı');
      expect(stored.any((s) => s.contains('"actualHomeGoals":2')), true);
    });

    test('maç henüz bitmediyse sonuç yazılmaz', () async {
      final pending = makePrediction(
        fixtureId: 3003,
        matchDate: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      SharedPreferences.setMockInitialValues({
        'saved_predictions': [json.encode(pending.toJson())],
      });

      final provider = MatchPredictionProvider();
      await provider.loadPastPredictions();

      final service = FakeApiFootballService({
        3003: Fixture.fromApiFootball(
          fixtureJson(id: 3003, status: '2H', homeGoals: 1, awayGoals: 0),
        ),
      });

      final updated = await provider.refreshResults(service);

      expect(updated, 0);
      final p = provider.pastPredictions.single;
      expect(p.hasResult, false);
      expect(p.fixtureStatus, '2H');
    });
  });

  group('Arayüz yardımcıları', () {
    test('Türkçe gün başlıkları', () {
      final now = DateTime(2026, 9, 11, 10);
      expect(turkishDayLabel(DateTime(2026, 9, 11, 21), now), 'Bugün');
      expect(turkishDayLabel(DateTime(2026, 9, 12, 21), now), 'Yarın');
      expect(turkishDayLabel(DateTime(2026, 9, 10, 21), now), 'Dün');
      expect(turkishDayLabel(DateTime(2026, 9, 13, 21), now), '13 Eylül Pazar');
      expect(turkishDayLabel(null, now), 'Tarih belirsiz');
    });
  });
}
