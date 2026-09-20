import 'package:flutter/foundation.dart';
import '../models/fixture.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import '../models/odds_comparison.dart';
import 'api_football_service.dart';
import 'club_elo_service.dart';
import 'health_check_service.dart';
import 'real_sports_live_service.dart';
import 'remote_config_service.dart';
import 'sofascore_live_service.dart';

/// Çok Kaynaklı Kotasız Futbol Veri Koordinatörü
///
/// ESPN, Sofascore, Club Elo ve yerel önbellek kaynaklarını
/// tek bir güvenilir çatı altında birleştirir.
class MultiSourceFootballService {
  static bool _initialized = false;

  /// Tüm alt servisleri paralel olarak başlatır
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await RemoteConfigService.initialize();
      await Future.wait([
        HealthCheckService.probeAll(),
        ClubEloService.initialize(),
      ]);
      _initialized = true;
      debugPrint('MultiSourceFootballService başarıyla başlatıldı.');
    } catch (e) {
      debugPrint('MultiSourceFootballService başlatma uyarısı: $e');
    }
  }

  /// Seçili tarihteki tüm canlı ve fikstür maçlarını kotasız olarak getirir
  static Future<List<Fixture>> getLiveFixtures({DateTime? date}) async {
    // 1. ESPN üzerinden kotasız maçları getir
    final fixtures = await RealSportsLiveService.getLiveFixtures(date: date);
    return fixtures;
  }

  /// Bir maçın resmi ilk 11 ve yedek kadrolarını getirir
  static Future<List<TeamLineup>> getFixtureLineups(int fixtureId, {String? leagueCode}) async {
    return await RealSportsLiveService.getFixtureLineups(fixtureId, leagueCode: leagueCode);
  }

  /// Bir maçın canlı olaylarını (goller, kartlar, değişiklikler) getirir
  static Future<List<MatchEvent>> getFixtureEvents(int fixtureId, {String? leagueCode}) async {
    return await RealSportsLiveService.getFixtureEvents(fixtureId, leagueCode: leagueCode);
  }

  /// Bir maçın gerçek piyasa oranlarını getirir (Sofascore -> API-Football -> Simülasyon)
  static Future<BookmakerOdds?> getOddsForMatch({
    required String homeTeam,
    required String awayTeam,
    DateTime? date,
    int? fixtureId,
    ApiFootballService? apiService,
  }) async {
    // 1. Önce Sofascore üzerinden gerçek canlı büro oranlarını dene (Kotasız & Ücretsiz)
    final sofaOdds = await SofascoreLiveService.getLiveOddsForMatch(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      date: date,
    );
    if (sofaOdds != null) return sofaOdds;

    // 2. Sofascore'da bulunamadıysa ve API-Football anahtarı varsa oradan dene
    if (fixtureId != null && apiService != null && apiService.hasKey) {
      try {
        final apiOdds = await apiService.getOddsForFixture(fixtureId);
        if (apiOdds != null) return apiOdds;
      } catch (_) {}
    }

    return null;
  }

  /// Bir maçın canlı xG ve şut istatistiklerini getirir
  static Future<LiveMatchStats?> getLiveStatsForMatch({
    required String homeTeam,
    required String awayTeam,
    DateTime? date,
  }) async {
    return await SofascoreLiveService.getLiveStatsForMatch(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      date: date,
    );
  }

  /// Takımların Elo puanlarını ve aralarındaki kalite farkını döner
  static ({double homeElo, double awayElo, double eloDiff}) getEloAnalysis({
    required String homeTeam,
    required String awayTeam,
  }) {
    final hElo = ClubEloService.getTeamElo(homeTeam);
    final aElo = ClubEloService.getTeamElo(awayTeam);
    final diff = hElo - aElo;
    return (homeElo: hElo, awayElo: aElo, eloDiff: diff);
  }
}
