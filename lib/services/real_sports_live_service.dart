import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
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

  /// Dünya genelinde belirtilen tarihteki tüm gerçek maçları ve canlı skorları çeker.
  static Future<List<Fixture>> getLiveFixtures({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _formatDate(targetDate);
    final List<Fixture> allFixtures = [];

    // Tüm aktif ligleri paralel sorgula
    final futures = activeLeagues.map((cfg) => _fetchLeagueScoreboard(cfg, dateStr: dateStr));
    final results = await Future.wait(futures);

    for (final leagueList in results) {
      allFixtures.addAll(leagueList);
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
              final f = Fixture.fromEspn(
                Map<String, dynamic>.from(ev),
                defaultLeagueName: cfg.name,
                defaultCountry: cfg.country,
                defaultLeagueId: cfg.leagueId,
                defaultLeagueLogo: cfg.logo,
                leagueCode: cfg.code,
              );
              _fixtureLeagueCodeCache[f.id] = cfg.code;
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
