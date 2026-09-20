import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/utils/math_utils.dart';
import 'package:fottbol_prediction/models/country.dart';
import 'package:fottbol_prediction/models/league.dart';
import 'package:fottbol_prediction/models/api_team.dart';
import 'package:fottbol_prediction/services/mock_football_service.dart';
import 'package:fottbol_prediction/services/poisson_engine.dart';

void main() {
  test('MathUtils Poisson Probability calculation test', () {
    final prob = MathUtils.poissonProbability(1, 1.0);
    expect(prob, closeTo(0.367, 0.005));
  });

  test('Country and League model parsing test', () {
    final country = Country.fromJson({
      'name': 'Turkey',
      'code': 'TR',
      'flag': 'https://media.api-sports.io/flags/tr.svg',
    });
    expect(country.name, 'Turkey');
    expect(country.code, 'TR');

    final league = League.fromJson({
      'league': {
        'id': 203,
        'name': 'Süper Lig',
        'type': 'League',
        'logo': 'https://media.api-sports.io/football/leagues/203.png',
      },
      'country': {'name': 'Turkey', 'code': 'TR'},
      'seasons': [
        {'year': 2024, 'current': true},
        {'year': 2023, 'current': false}
      ]
    });
    expect(league.id, 203);
    expect(league.isCup, false);
    expect(league.seasons.first, 2024);
  });

  test('ApiTeam conversion to Team and Sparse Data Fallback in PoissonEngine', () {
    final apiTeamA = ApiTeam(
      id: 9991,
      name: 'Alt Lig Takımı A',
      country: 'Turkey',
      logo: '',
    );
    final apiTeamB = ApiTeam(
      id: 9992,
      name: 'Alt Lig Takımı B',
      country: 'Turkey',
      logo: '',
    );

    // Takımların detaylı kadrosu (squad) boş
    final teamA = apiTeamA.toTeam();
    final teamB = apiTeamB.toTeam();
    expect(teamA.squad.isEmpty, true);
    expect(teamB.squad.isEmpty, true);

    final prediction = PoissonEngine.calculatePrediction(
      homeTeam: teamA,
      awayTeam: teamB,
    );

    // Sparse data fallback bayrağı aktif olmalı
    expect(prediction.isSparseData, true);
    expect(prediction.predictedHomeGoals, greaterThanOrEqualTo(0));
    expect(prediction.predictedAwayGoals, greaterThanOrEqualTo(0));
    expect(prediction.mathematicalRationale.first.contains('Sınırlı Veri Modu'), true);
  });

  test('Poisson Engine generates valid predictions for standard mock teams', () {
    final teams = MockFootballService.getMockTeams();
    final home = teams[0];
    final away = teams[1];

    final result = PoissonEngine.calculatePrediction(
      homeTeam: home,
      awayTeam: away,
    );

    expect(result.isSparseData, false); // Normal lig verisinde eksiksiz kadro var
    expect(result.homeWinProbability, greaterThan(0));
    expect(result.drawProbability, greaterThan(0));
    expect(result.awayWinProbability, greaterThan(0));
  });
}
