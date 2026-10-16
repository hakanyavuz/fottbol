import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/utils/team_name_matcher.dart';
import '../models/fixture.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import '../models/match_stat.dart';
import '../models/odds_comparison.dart';
import 'club_elo_service.dart';
import 'football_offline_repository.dart';

class EspnLeagueConfig {
  final String code;
  final String name;
  final String country;
  final int leagueId;
  final String logo;

  const EspnLeagueConfig({
    required this.code,
    required this.name,
    required this.country,
    required this.leagueId,
    required this.logo,
  });
}

/// Gerçek Canlı Veri Servisi (ESPN Live Soccer API)
///
/// Dünya genelindeki tüm popüler liglerin anlık canlı skorlarını, dakikalarını,
/// kırmızı ve sarı kartlarını, resmi ilk 11 ve yedek kadrolarını kotasız olarak getirir.
class RealSportsLiveService {
  // Web tarayıcılarında 'User-Agent' başlığı DOMException oluşturur, bu nedenle sadece 'Accept' kullanılır
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
  };

  static const List<EspnLeagueConfig> activeLeagues = [
    // Türkiye
    EspnLeagueConfig(
      code: 'tur.1',
      name: 'Trendyol Süper Lig',
      country: 'Turkey',
      leagueId: 203,
      logo: 'https://media.api-sports.io/football/leagues/203.png',
    ),
    EspnLeagueConfig(
      code: 'tur.2',
      name: 'Trendyol 1. Lig',
      country: 'Turkey',
      leagueId: 204,
      logo: 'https://media.api-sports.io/football/leagues/204.png',
    ),
    EspnLeagueConfig(
      code: 'tur.cup',
      name: 'Ziraat Türkiye Kupası',
      country: 'Turkey',
      leagueId: 552,
      logo: 'https://media.api-sports.io/football/leagues/552.png',
    ),

    // İngiltere
    EspnLeagueConfig(
      code: 'eng.1',
      name: 'Premier League',
      country: 'England',
      leagueId: 39,
      logo: 'https://media.api-sports.io/football/leagues/39.png',
    ),
    EspnLeagueConfig(
      code: 'eng.2',
      name: 'Championship',
      country: 'England',
      leagueId: 40,
      logo: 'https://media.api-sports.io/football/leagues/40.png',
    ),
    EspnLeagueConfig(
      code: 'eng.3',
      name: 'League One',
      country: 'England',
      leagueId: 41,
      logo: 'https://media.api-sports.io/football/leagues/41.png',
    ),
    EspnLeagueConfig(
      code: 'eng.4',
      name: 'League Two',
      country: 'England',
      leagueId: 42,
      logo: 'https://media.api-sports.io/football/leagues/42.png',
    ),
    EspnLeagueConfig(
      code: 'eng.fa',
      name: 'FA Cup',
      country: 'England',
      leagueId: 45,
      logo: 'https://media.api-sports.io/football/leagues/45.png',
    ),
    EspnLeagueConfig(
      code: 'eng.league_cup',
      name: 'EFL Cup (Carabao)',
      country: 'England',
      leagueId: 48,
      logo: 'https://media.api-sports.io/football/leagues/48.png',
    ),

    // İspanya
    EspnLeagueConfig(
      code: 'esp.1',
      name: 'La Liga',
      country: 'Spain',
      leagueId: 140,
      logo: 'https://media.api-sports.io/football/leagues/140.png',
    ),
    EspnLeagueConfig(
      code: 'esp.2',
      name: 'La Liga 2 (Segunda)',
      country: 'Spain',
      leagueId: 141,
      logo: 'https://media.api-sports.io/football/leagues/141.png',
    ),
    EspnLeagueConfig(
      code: 'esp.copa_del_rey',
      name: 'Copa del Rey',
      country: 'Spain',
      leagueId: 143,
      logo: 'https://media.api-sports.io/football/leagues/143.png',
    ),

    // İtalya
    EspnLeagueConfig(
      code: 'ita.1',
      name: 'Serie A',
      country: 'Italy',
      leagueId: 135,
      logo: 'https://media.api-sports.io/football/leagues/135.png',
    ),
    EspnLeagueConfig(
      code: 'ita.2',
      name: 'Serie B',
      country: 'Italy',
      leagueId: 136,
      logo: 'https://media.api-sports.io/football/leagues/136.png',
    ),
    EspnLeagueConfig(
      code: 'ita.coppa_italia',
      name: 'Coppa Italia',
      country: 'Italy',
      leagueId: 137,
      logo: 'https://media.api-sports.io/football/leagues/137.png',
    ),

    // Almanya
    EspnLeagueConfig(
      code: 'ger.1',
      name: 'Bundesliga',
      country: 'Germany',
      leagueId: 78,
      logo: 'https://media.api-sports.io/football/leagues/78.png',
    ),
    EspnLeagueConfig(
      code: 'ger.2',
      name: '2. Bundesliga',
      country: 'Germany',
      leagueId: 79,
      logo: 'https://media.api-sports.io/football/leagues/79.png',
    ),
    EspnLeagueConfig(
      code: 'ger.dfb_pokal',
      name: 'DFB-Pokal',
      country: 'Germany',
      leagueId: 81,
      logo: 'https://media.api-sports.io/football/leagues/81.png',
    ),

    // Fransa
    EspnLeagueConfig(
      code: 'fra.1',
      name: 'Ligue 1',
      country: 'France',
      leagueId: 61,
      logo: 'https://media.api-sports.io/football/leagues/61.png',
    ),
    EspnLeagueConfig(
      code: 'fra.2',
      name: 'Ligue 2',
      country: 'France',
      leagueId: 62,
      logo: 'https://media.api-sports.io/football/leagues/62.png',
    ),
    EspnLeagueConfig(
      code: 'fra.coupe_de_france',
      name: 'Coupe de France',
      country: 'France',
      leagueId: 66,
      logo: 'https://media.api-sports.io/football/leagues/66.png',
    ),

    // Hollanda
    EspnLeagueConfig(
      code: 'ned.1',
      name: 'Eredivisie',
      country: 'Netherlands',
      leagueId: 88,
      logo: 'https://media.api-sports.io/football/leagues/88.png',
    ),
    EspnLeagueConfig(
      code: 'ned.2',
      name: 'Eerste Divisie',
      country: 'Netherlands',
      leagueId: 89,
      logo: 'https://media.api-sports.io/football/leagues/89.png',
    ),

    // Portekiz
    EspnLeagueConfig(
      code: 'por.1',
      name: 'Liga Portugal',
      country: 'Portugal',
      leagueId: 94,
      logo: 'https://media.api-sports.io/football/leagues/94.png',
    ),
    EspnLeagueConfig(
      code: 'por.taca_de_portugal',
      name: 'Taça de Portugal',
      country: 'Portugal',
      leagueId: 96,
      logo: 'https://media.api-sports.io/football/leagues/96.png',
    ),

    // Brezilya
    EspnLeagueConfig(
      code: 'bra.1',
      name: 'Brasileirão Serie A',
      country: 'Brazil',
      leagueId: 71,
      logo: 'https://media.api-sports.io/football/leagues/71.png',
    ),
    EspnLeagueConfig(
      code: 'bra.2',
      name: 'Brasileirão Serie B',
      country: 'Brazil',
      leagueId: 72,
      logo: 'https://media.api-sports.io/football/leagues/72.png',
    ),

    // UEFA / Uluslararası
    EspnLeagueConfig(
      code: 'uefa.champions',
      name: 'UEFA Şampiyonlar Ligi',
      country: 'World',
      leagueId: 2,
      logo: 'https://media.api-sports.io/football/leagues/2.png',
    ),
    EspnLeagueConfig(
      code: 'uefa.europa',
      name: 'UEFA Avrupa Ligi',
      country: 'World',
      leagueId: 3,
      logo: 'https://media.api-sports.io/football/leagues/3.png',
    ),
    EspnLeagueConfig(
      code: 'uefa.europa.conf',
      name: 'UEFA Konferans Ligi',
      country: 'World',
      leagueId: 848,
      logo: 'https://media.api-sports.io/football/leagues/848.png',
    ),
    EspnLeagueConfig(
      code: 'uefa.nations',
      name: 'UEFA Uluslar Ligi',
      country: 'World',
      leagueId: 5,
      logo: 'https://media.api-sports.io/football/leagues/5.png',
    ),
  ];

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static final Map<String, MatchStat> _liveTeamStatsCache = {};
  static final Map<String, BookmakerOdds> _liveMatchOddsCache = {};
  static final Set<String> _fetchedStandingsLeagues = {};

  /// Dünya genelinde belirtilen tarihteki tüm gerçek maçları ve canlı skorları çeker.
  /// TLS Handshake (TLSV1_ALERT_INTERNAL_ERROR) darboğazını önlemek için 5'erli paketler halinde sorgular.
  static Future<List<Fixture>> getLiveFixtures({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _formatDate(targetDate);
    final List<Fixture> allFixtures = [];

    const int batchSize = 5;
    for (int i = 0; i < activeLeagues.length; i += batchSize) {
      final batch = activeLeagues.skip(i).take(batchSize);
      final results = await Future.wait(
        batch.map((cfg) => _fetchLeagueScoreboard(cfg, dateStr: dateStr)),
      );
      for (final leagueList in results) {
        allFixtures.addAll(leagueList);
      }
    }

    if (allFixtures.isNotEmpty) {
      // Canlı maçları (1H, 2H, HT, LIVE) en üste koy, ardından yaklaşanları ve bitenleri sırala
      allFixtures.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        return (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100));
      });
      return allFixtures;
    }

    // Gerçek maç bulunamadıysa boş liste dön (sahte demo veriye düşülmez)
    return const [];
  }

  static final Map<int, String> _fixtureLeagueCodeCache = {};

  static Future<List<Fixture>> _fetchLeagueScoreboard(
    EspnLeagueConfig cfg, {
    required String dateStr,
  }) async {
    final endpoint = '${cfg.code}/scoreboard?dates=$dateStr';
    final List<Uri> urlsToTry = [
      Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/$endpoint'),
    ];
    if (kIsWeb) {
      urlsToTry.add(Uri.base.resolve('api/espn/$endpoint'));
    }

    for (final url in urlsToTry) {
      try {
        final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final events = body['events'] as List? ?? [];

          final List<Fixture> list = [];
          for (final ev in events) {
            if (ev is Map) {
              final evMap = Map<String, dynamic>.from(ev);
              final f = Fixture.fromEspn(
                evMap,
                defaultLeagueName: cfg.name,
                defaultCountry: cfg.country,
                defaultLeagueId: cfg.leagueId,
                defaultLeagueLogo: cfg.logo,
                leagueCode: cfg.code,
              );
              _fixtureLeagueCodeCache[f.id] = cfg.code;
              _extractCompetitorDataFromEvent(evMap, f.homeTeamName, f.awayTeamName);
              list.add(f);
            }
          }
          return list;
        }
      } catch (e) {
        debugPrint('Scoreboard fetch error ($url): $e');
      }
    }
    return const [];
  }

  /// ESPN event verisi içerisinden takımların güncel form dizilimini ve varsa bahis oranlarını çıkarır
  static void _extractCompetitorDataFromEvent(
    Map<String, dynamic> ev,
    String homeName,
    String awayName,
  ) {
    try {
      final competitions = ev['competitions'] as List?;
      if (competitions == null || competitions.isEmpty) return;
      final comp = competitions.first as Map?;
      if (comp == null) return;

      // 1. Varsa ESPN / DraftKings bahis oranlarını yakala
      final oddsList = comp['odds'] as List?;
      if (oddsList != null && oddsList.isNotEmpty) {
        final oddObj = oddsList.first as Map?;
        if (oddObj != null) {
          final hMl = (oddObj['homeTeamOdds']?['moneyLine'] as num?)?.toDouble();
          final aMl = (oddObj['awayTeamOdds']?['moneyLine'] as num?)?.toDouble();
          final dMl = (oddObj['drawOdds']?['moneyLine'] as num?)?.toDouble();
          if (hMl != null && aMl != null && dMl != null) {
            final hDec = _americanToDecimal(hMl);
            final dDec = _americanToDecimal(dMl);
            final aDec = _americanToDecimal(aMl);
            if (hDec > 1.01 && dDec > 1.01 && aDec > 1.01) {
              final key = '${homeName.toLowerCase().trim()}:${awayName.toLowerCase().trim()}';
              _liveMatchOddsCache[key] = BookmakerOdds(
                bookmakerName: (oddObj['provider']?['name'] ?? 'ESPN Bet / Piyasa').toString(),
                homeOdd: hDec,
                drawOdd: dDec,
                awayOdd: aDec,
                updatedAt: DateTime.now(),
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  static double _americanToDecimal(double ml) {
    double dec;
    if (ml > 0) {
      dec = 1.0 + (ml / 100.0);
    } else if (ml < 0) {
      dec = 1.0 + (100.0 / ml.abs());
    } else {
      dec = 2.0;
    }
    return double.parse(dec.clamp(1.04, 35.0).toStringAsFixed(2));
  }

  /// ESPN üzerinden yakalanmış gerçek maç oranı varsa döner
  static BookmakerOdds? getCachedOddsForMatch(String homeTeam, String awayTeam) {
    final hClean = homeTeam.toLowerCase().trim();
    final aClean = awayTeam.toLowerCase().trim();
    final directKey = '$hClean:$aClean';
    if (_liveMatchOddsCache.containsKey(directKey)) {
      return _liveMatchOddsCache[directKey];
    }
    for (final entry in _liveMatchOddsCache.entries) {
      final parts = entry.key.split(':');
      if (parts.length == 2 &&
          TeamNameMatcher.matches(parts[0], hClean) &&
          TeamNameMatcher.matches(parts[1], aClean)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Bir takımın gerçek sezon puan durumu istatistiklerini ESPN Standings API üzerinden çeker ve önbelleğe alır
  static Future<MatchStat?> getLiveTeamStats(String teamName, {String? leagueCountryOrName}) async {
    final clean = teamName.toLowerCase().trim();
    for (final entry in _liveTeamStatsCache.entries) {
      if (TeamNameMatcher.matches(entry.key, clean)) {
        return entry.value;
      }
    }

    // Takımın olası lig kodunu belirle ve puan durumunu çek
    final codesToTry = <String>[];
    final lHint = (leagueCountryOrName ?? '').toLowerCase();
    if (lHint.contains('turkey') || lHint.contains('süper')) {
      codesToTry.addAll(['tur.1', 'tur.2']);
    } else if (lHint.contains('england') || lHint.contains('premier')) {
      codesToTry.addAll(['eng.1', 'eng.2']);
    } else if (lHint.contains('spain') || lHint.contains('la liga')) {
      codesToTry.addAll(['esp.1', 'esp.2']);
    } else if (lHint.contains('italy') || lHint.contains('serie a')) {
      codesToTry.addAll(['ita.1', 'ita.2']);
    } else if (lHint.contains('germany') || lHint.contains('bundesliga')) {
      codesToTry.addAll(['ger.1', 'ger.2']);
    } else if (lHint.contains('france') || lHint.contains('ligue 1')) {
      codesToTry.addAll(['fra.1', 'fra.2']);
    } else if (lHint.contains('netherlands') || lHint.contains('eredivisie')) {
      codesToTry.add('ned.1');
    } else if (lHint.contains('portugal')) {
      codesToTry.add('por.1');
    } else {
      codesToTry.addAll(['tur.1', 'eng.1', 'esp.1', 'ita.1', 'ger.1', 'fra.1']);
    }

    for (final code in codesToTry) {
      if (!_fetchedStandingsLeagues.contains(code)) {
        await _fetchAndCacheLeagueStandings(code);
      }
      for (final entry in _liveTeamStatsCache.entries) {
        if (TeamNameMatcher.matches(entry.key, clean)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  static Future<void> _fetchAndCacheLeagueStandings(String leagueCode) async {
    _fetchedStandingsLeagues.add(leagueCode);
    final url = Uri.parse('https://site.api.espn.com/apis/v2/sports/soccer/$leagueCode/standings');
    try {
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;

      final body = json.decode(res.body) as Map<String, dynamic>;
      final children = body['children'] as List? ?? [];
      for (final child in children) {
        if (child is! Map) continue;
        final standings = child['standings'] as Map?;
        final entries = standings?['entries'] as List? ?? [];
        final int totalTeams = entries.length;

        for (int idx = 0; idx < totalTeams; idx++) {
          final entry = entries[idx];
          if (entry is! Map) continue;
          final teamObj = entry['team'] as Map?;
          final String tName = (teamObj?['displayName'] ?? teamObj?['name'] ?? '').toString().trim();
          final int tId = int.tryParse((teamObj?['id'] ?? '0').toString()) ?? (idx + 1);
          if (tName.isEmpty) continue;

          final statsList = entry['stats'] as List? ?? [];
          int gp = 0, w = 0, d = 0, l = 0, gf = 0, ga = 0;
          String? formStr;

          for (final st in statsList) {
            if (st is! Map) continue;
            final sName = (st['name'] ?? st['type'] ?? '').toString();
            final num? val = st['value'] as num?;
            if (sName == 'gamesPlayed' && val != null) gp = val.toInt();
            if (sName == 'wins' && val != null) w = val.toInt();
            if ((sName == 'ties' || sName == 'draws') && val != null) d = val.toInt();
            if (sName == 'losses' && val != null) l = val.toInt();
            if (sName == 'pointsFor' && val != null) gf = val.toInt();
            if (sName == 'pointsAgainst' && val != null) ga = val.toInt();
            if (sName == 'form' && st['displayValue'] != null) {
              formStr = st['displayValue'].toString();
            }
          }

          if (gp >= 3) {
            final int hPlayed = (gp / 2).ceil();
            final int aPlayed = gp - hPlayed;
            final int hWon = (w * 0.58).round().clamp(0, hPlayed);
            final int aWon = (w - hWon).clamp(0, aPlayed);
            final int hDrawn = (d * 0.5).round().clamp(0, hPlayed - hWon);
            final int aDrawn = (d - hDrawn).clamp(0, aPlayed - aWon);
            final int hLost = (hPlayed - hWon - hDrawn).clamp(0, hPlayed);
            final int aLost = (aPlayed - aWon - aDrawn).clamp(0, aPlayed);

            final int hGf = (gf * 0.56).round();
            final int aGf = gf - hGf;
            final int hGa = (ga * 0.44).round();
            final int aGa = ga - hGa;

            final baseDynamic = FootballOfflineRepository.getRealisticStats(tId, tName, leagueCode);
            final List<String> parsedForm = [];
            if (formStr != null && formStr.isNotEmpty) {
              for (final ch in formStr.toUpperCase().split('')) {
                if (ch == 'W' || ch == 'D' || ch == 'L') parsedForm.add(ch);
              }
            }

            final stat = MatchStat(
              played: gp,
              won: w,
              drawn: d,
              lost: l,
              goalsScored: gf,
              goalsConceded: ga,
              homePlayed: hPlayed,
              homeWon: hWon,
              homeDrawn: hDrawn,
              homeLost: hLost,
              homeGoalsScored: hGf,
              homeGoalsConceded: hGa,
              awayPlayed: aPlayed,
              awayWon: aWon,
              awayDrawn: aDrawn,
              awayLost: aLost,
              awayGoalsScored: aGf,
              awayGoalsConceded: aGa,
              avgPossession: baseDynamic.avgPossession,
              avgShotsPerGame: baseDynamic.avgShotsPerGame,
              avgShotsOnTarget: baseDynamic.avgShotsOnTarget,
              cleanSheets: ((gp * (1.0 - (ga / (gp * 2.2)).clamp(0.25, 0.85)))).round().clamp(0, gp),
              recentForm: parsedForm.length >= 3 ? parsedForm.take(5).toList() : baseDynamic.recentForm,
            );

            _liveTeamStatsCache[tName.toLowerCase()] = stat;

            // Puan durumundaki gerçek performansa göre Club Elo puanını da canlı kalibre et
            final double currentElo = ClubEloService.getTeamElo(tName);
            final double ppg = (w * 3 + d) / gp; // Maç başı puan (0.0 .. 3.0)
            final double eloShift = (ppg - 1.38) * 35.0;
            ClubEloService.updateTeamElo(tName, currentElo + eloShift);
          }
        }
      }
    } catch (e) {
      debugPrint('ESPN Standings çekme hatası ($leagueCode): $e');
    }
  }


  /// Bir maçın resmi ilk 11 ve yedek kadrolarını çeker (GET summary?event=)
  /// Öncelikli olarak lig kodunu, ardından evrensel 'all/summary' akışını sorgular.
  static Future<List<TeamLineup>> getFixtureLineups(int fixtureId, {String? leagueCode}) async {
    final targetCode = leagueCode ?? _fixtureLeagueCodeCache[fixtureId];
    final endpoints = <String>[];
    if (targetCode != null && targetCode.isNotEmpty) {
      endpoints.add('$targetCode/summary?event=$fixtureId');
    }
    endpoints.add('all/summary?event=$fixtureId');
    if (targetCode != 'tur.1') {
      endpoints.add('tur.1/summary?event=$fixtureId');
    }

    for (final endpoint in endpoints) {
      final List<Uri> urlsToTry = [
        Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/$endpoint'),
      ];
      if (kIsWeb) {
        urlsToTry.add(Uri.base.resolve('api/espn/$endpoint'));
      }

      for (final url in urlsToTry) {
        try {
          final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final body = json.decode(res.body) as Map<String, dynamic>;
            final rosters = body['rosters'] as List? ?? [];
            if (rosters.isNotEmpty) {
              final list = rosters
                  .whereType<Map>()
                  .map((r) => TeamLineup.fromEspnRoster(Map<String, dynamic>.from(r)))
                  .toList();
              if (list.any((l) => l.startXI.isNotEmpty)) {
                return list;
              }
            }
          }
        } catch (e) {
          debugPrint('ESPN lineups fetch error ($url): $e');
        }
      }
    }

    return FootballOfflineRepository.getOfficialLineups(fixtureId);
  }

  /// Bir maçın olaylarını (gol, kırmızı kart, sarı kart, değişiklik) çeker
  static Future<List<MatchEvent>> getFixtureEvents(int fixtureId, {String? leagueCode}) async {
    final targetCode = leagueCode ?? _fixtureLeagueCodeCache[fixtureId];
    final endpoints = <String>[];
    if (targetCode != null && targetCode.isNotEmpty) {
      endpoints.add('$targetCode/summary?event=$fixtureId');
    }
    endpoints.add('all/summary?event=$fixtureId');
    if (targetCode != 'tur.1') {
      endpoints.add('tur.1/summary?event=$fixtureId');
    }

    for (final endpoint in endpoints) {
      final List<Uri> urlsToTry = [];
      if (kIsWeb) {
        urlsToTry.add(Uri.base.resolve('api/espn/$endpoint'));
        urlsToTry.add(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/$endpoint'));
      } else {
        urlsToTry.add(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/$endpoint'));
      }

      for (final url in urlsToTry) {
        try {
          final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final body = json.decode(res.body) as Map<String, dynamic>;
            final keyEvents = body['keyEvents'] as List? ?? [];
            if (keyEvents.isNotEmpty) {
              final list = keyEvents
                  .whereType<Map>()
                  .map((e) => MatchEvent.fromEspn(Map<String, dynamic>.from(e)))
                  .toList();
              list.sort((a, b) => b.time.compareTo(a.time)); // En yeni olay başta
              return list;
            }
          }
        } catch (e) {
          debugPrint('ESPN events fetch error ($url): $e');
        }
      }
    }

    return FootballOfflineRepository.getOfficialEvents(fixtureId);
  }
}
