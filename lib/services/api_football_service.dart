import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../core/cache/cache_manager.dart';
import '../core/network/api_exceptions.dart';
import '../core/utils/season_utils.dart';
import '../models/country.dart';
import '../models/fixture.dart';
import '../models/head_to_head.dart';
import '../models/league.dart';
import '../models/api_team.dart';
import '../models/match_stat.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/odds_comparison.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import 'football_offline_repository.dart';

/// API-Football (v3.football.api-sports.io veya RapidAPI) Servis Katmanı
///
/// Anahtar girildiğinde dünyadaki tüm ülke / lig / takım verisi ve takımların
/// gerçek sezon istatistikleri, kadroları ve sakatlıkları bu servisten gelir.
/// Anahtar yoksa yalnızca sınırlı bir çevrimdışı demo veri seti döner.
class ApiFootballService {
  static const String baseUrl = 'https://v3.football.api-sports.io';
  final String apiKey;

  ApiFootballService({required this.apiKey});

  /// Kullanılabilir bir API anahtarı var mı? (arayüzdeki boş durum mesajları için)
  bool get hasKey => apiKey.trim().isNotEmpty;

  /// API-Football'un yanıt başlıklarından okunan güncel kota bilgisi
  static int? remainingRequests;
  static int? dailyRequestLimit;

  Map<String, String> get _headers => {
    'x-apisports-key': apiKey.trim(),
    // RapidAPI kullanıcıları için:
    // 'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
    // 'x-rapidapi-key': apiKey,
  };

  // ---------------------------------------------------------------------------
  // Ortak HTTP + Önbellek katmanı
  // ---------------------------------------------------------------------------

  /// Bir uç noktayı çağırır, 12 saatlik önbelleği ve kota/ağ hatalarını yönetir.
  ///
  /// Dönen değer API-Football'un `response` alanıdır (liste veya map).
  /// Anahtar yoksa `null` döner; çağıran taraf çevrimdışı davranışı belirler.
  Future<dynamic> _fetch(
    String path,
    Map<String, String> query, {
    required String cacheKey,
    bool forceRefresh = false,
    Duration ttl = CacheManager.defaultTtl,
  }) async {
    if (!forceRefresh) {
      final cached = CacheManager.get(cacheKey, ttl: ttl);
      if (cached != null) return cached;
    }

    if (!hasKey) return null;

    try {
      final url = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final response =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));

      _readQuotaHeaders(response);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final tokenMsg = errors['token'] ?? errors['bug'];
          if (tokenMsg != null) {
            // Anahtar reddedildiğinde ekranı kilitlemek yerine null dönerek
            // zengin çevrimdışı veri havuzunun sorunsuz açılmasını sağla
            return null;
          }
        }
        _checkApiErrors(body, cacheKey);

        final data = body['response'];
        if (data != null) await CacheManager.put(cacheKey, data);
        return data;
      }

      if (response.statusCode == 429) {
        final stale = CacheManager.getStale(cacheKey);
        if (stale != null) return stale;
        throw ApiQuotaExceededException(hasCachedFallback: false);
      }

      throw ApiException('Sunucu hatası: HTTP ${response.statusCode}', statusCode: response.statusCode);
    } on ApiQuotaExceededException {
      rethrow;
    } catch (e) {
      // Ağ hatası: süresi dolmuş olsa da önbellekten kurtarmayı dene
      final stale = CacheManager.getStale(cacheKey);
      if (stale != null) return stale;
      if (e is ApiException) rethrow;
      throw NetworkException('İstek tamamlanamadı ($path): $e');
    }
  }

  void _readQuotaHeaders(http.Response response) {
    final remaining = response.headers['x-ratelimit-requests-remaining'];
    final limit = response.headers['x-ratelimit-requests-limit'];
    if (remaining != null) remainingRequests = int.tryParse(remaining);
    if (limit != null) dailyRequestLimit = int.tryParse(limit);
  }

  /// API-Football JSON hata denetleyicisi (Örn: {"errors": {"requests": "You have reached..."}})
  void _checkApiErrors(Map<String, dynamic> body, String cacheKey) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final rateMsg = errors['rateLimit'] ?? errors['requests'];
      if (rateMsg != null) {
        throw ApiQuotaExceededException(
          message: 'API-Football kota limiti aşıldı: $rateMsg',
          hasCachedFallback: CacheManager.hasAnyCache(cacheKey),
        );
      }
      final tokenMsg = errors['token'] ?? errors['bug'];
      if (tokenMsg != null) {
        // Token hatasında fatal hata fırlatmak yerine offline depoya düşüşe izin ver
        return;
      }
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // 1. Ülkeler / Ligler / Takımlar
  // ---------------------------------------------------------------------------

  /// Tüm ülkeleri getirir (GET /countries) — anahtar varsa 200+ ülkenin tamamı
  Future<List<Country>> getCountries({bool forceRefresh = false}) async {
    try {
      final data = await _fetch('/countries', const {},
          cacheKey: 'countries_list', forceRefresh: forceRefresh);

      if (data == null) return _offlineCountries();

      final countries = _asMapList(data).map(Country.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return countries.isNotEmpty ? countries : _offlineCountries();
    } catch (_) {
      return _offlineCountries();
    }
  }

  /// Seçilen ülkenin tüm lig ve kupalarını getirir (GET /leagues?country=)
  Future<List<League>> getLeaguesByCountry(
    String country, {
    int? season,
    bool forceRefresh = false,
  }) async {
    try {
      final query = {'country': country};
      if (season != null) query['season'] = season.toString();

      final data = await _fetch(
        '/leagues',
        query,
        cacheKey: 'leagues_${country.toLowerCase()}_${season ?? 'all'}',
        forceRefresh: forceRefresh,
      );

      if (data == null) return _offlineLeagues(country);
      final list = _asMapList(data).map(League.fromJson).toList();
      return list.isNotEmpty ? list : _offlineLeagues(country);
    } catch (_) {
      return _offlineLeagues(country);
    }
  }

  /// Seçilen ligin tüm takımlarını getirir (GET /teams?league=&season=)
  Future<List<ApiTeam>> getTeamsByLeague(
    int leagueId,
    int season, {
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/teams',
        {'league': leagueId.toString(), 'season': season.toString()},
        cacheKey: 'teams_${leagueId}_$season',
        forceRefresh: forceRefresh,
      );

      if (data == null) return _offlineTeams(leagueId);
      final list = _asMapList(data).map(ApiTeam.fromJson).toList();
      return list.isNotEmpty ? list : _offlineTeams(leagueId);
    } catch (_) {
      return _offlineTeams(leagueId);
    }
  }

  /// Lig/ülke farketmeksizin dünya genelinde takım araması (GET /teams?search=)
  /// API en az 3 karakter ister.
  Future<List<ApiTeam>> searchTeams(String query) async {
    final term = query.trim();
    if (term.length < 2) return const [];

    try {
      final data = await _fetch(
        '/teams',
        {'search': term},
        cacheKey: 'teamsearch_${term.toLowerCase()}',
      );

      if (data == null) return _offlineSearch(term);
      final list = _asMapList(data).map(ApiTeam.fromJson).toList();
      return list.isNotEmpty ? list : _offlineSearch(term);
    } catch (_) {
      return _offlineSearch(term);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Fikstür (maç programı ve sonuçlar)
  // ---------------------------------------------------------------------------

  /// Fikstür verisi sık değişir; uzun TTL yerine 1 saatlik önbellek kullanılır.
  static const Duration _fixtureTtl = Duration(hours: 1);

  /// Belirli bir tarihteki tüm maçları getirir (GET /fixtures?date=YYYY-MM-DD)
  /// Canlı API bağlıysa o günkü dünya genelindeki tüm gerçek maçları döner.
  /// API bağlı değilse yalnızca kayıtlı resmi takvimdeki gerçek maçları döner, ASLA sahte/demo veri üretmez.
  Future<List<Fixture>> getFixturesByDate(DateTime date, {bool forceRefresh = false}) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (hasKey) {
      try {
        final data = await _fetch(
          '/fixtures',
          {
            'date': dateStr,
            'timezone': 'Europe/Istanbul',
          },
          cacheKey: 'fixtures_date_$dateStr',
          ttl: const Duration(minutes: 30),
          forceRefresh: forceRefresh,
        );

        if (data != null) {
          final list = _asMapList(data).map(Fixture.fromApiFootball).toList();
          return list..sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));
        }
      } catch (_) {}
    }

    // API'den veri gelmezse (2026 olduğu için) dahili depodaki dinamik maçları getir
    return FootballOfflineRepository.getOfficialFixturesByDate(date);
  }

  /// Canlı oynanmakta olan tüm maçları getirir (GET /fixtures?live=all)
  Future<List<Fixture>> getLiveFixtures({bool forceRefresh = false}) async {
    try {
      final data = await _fetch(
        '/fixtures',
        {'live': 'all', 'timezone': 'Europe/Istanbul'},
        cacheKey: 'fixtures_live',
        ttl: const Duration(seconds: 5), // Gecikme önlemek için TTL 5 saniyeye indirildi
        forceRefresh: forceRefresh,
      );

      if (data != null) {
        final list = _asMapList(data).map(Fixture.fromApiFootball).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return FootballOfflineRepository.getLiveFixtures();
  }

  /// Ligin yaklaşan maçları (GET /fixtures?league=&season=&next=)
  Future<List<Fixture>> getUpcomingFixtures({
    required int leagueId,
    required int season,
    int count = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/fixtures',
        {
          'league': leagueId.toString(),
          'season': season.toString(),
          'next': count.toString(),
        },
        cacheKey: 'fixtures_next_${leagueId}_${season}_$count',
        ttl: _fixtureTtl,
        forceRefresh: forceRefresh,
      );

      if (data == null) return FootballOfflineRepository.getUpcomingFixtures(leagueId, season, count);
      final list = _asMapList(data).map(Fixture.fromApiFootball).toList();
      if (list.isEmpty) return FootballOfflineRepository.getUpcomingFixtures(leagueId, season, count);
      return list..sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));
    } catch (_) {
      return FootballOfflineRepository.getUpcomingFixtures(leagueId, season, count);
    }
  }

  /// Ligin son oynanan maçları (GET /fixtures?league=&season=&last=)
  Future<List<Fixture>> getRecentFixtures({
    required int leagueId,
    required int season,
    int count = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/fixtures',
        {
          'league': leagueId.toString(),
          'season': season.toString(),
          'last': count.toString(),
        },
        cacheKey: 'fixtures_last_${leagueId}_${season}_$count',
        ttl: _fixtureTtl,
        forceRefresh: forceRefresh,
      );

      if (data == null) return FootballOfflineRepository.getRecentFixtures(leagueId, season, count);
      final list = _asMapList(data).map(Fixture.fromApiFootball).toList();
      if (list.isEmpty) return FootballOfflineRepository.getRecentFixtures(leagueId, season, count);
      return list..sort((a, b) => (b.date ?? DateTime(1900)).compareTo(a.date ?? DateTime(1900)));
    } catch (_) {
      return FootballOfflineRepository.getRecentFixtures(leagueId, season, count);
    }
  }

  /// Tek bir maçın güncel durumu ve skoru (GET /fixtures?id=)
  /// Tahmin isabet takibinde gerçek sonucu almak için kullanılır.
  Future<Fixture?> getFixtureById(int fixtureId, {bool forceRefresh = false}) async {
    final data = await _fetch(
      '/fixtures',
      {'id': fixtureId.toString()},
      cacheKey: 'fixture_$fixtureId',
      ttl: _fixtureTtl,
      forceRefresh: forceRefresh,
    );

    final rows = _asMapList(data);
    if (rows.isEmpty) return null;
    return Fixture.fromApiFootball(rows.first);
  }

  /// Maçın ilk 11 ve yedek kadrolarını getirir (GET /fixtures/lineups?fixture=)
  Future<List<TeamLineup>> getFixtureLineups(int fixtureId) async {
    if (hasKey) {
      try {
        final data = await _fetch(
          '/fixtures/lineups',
          {'fixture': fixtureId.toString()},
          cacheKey: 'lineups_$fixtureId',
          ttl: const Duration(minutes: 15),
        );
        if (data != null) return _asMapList(data).map(TeamLineup.fromApiFootball).toList();
      } catch (_) {}
    }

    // Çevrimdışı/Simülasyon kadroları getir
    return FootballOfflineRepository.getOfficialLineups(fixtureId);
  }

  /// İki takımın aralarındaki son maçlar (GET /fixtures/headtohead?h2h=A-B&last=)
  ///
  /// Ham fikstürler önbelleğe simetrik anahtarla yazılır; özet ise istenen
  /// ev sahibi/deplasman bakış açısına göre her seferinde yeniden hesaplanır.
  Future<HeadToHeadSummary?> getHeadToHead({
    required int homeTeamId,
    required int awayTeamId,
    int last = 10,
  }) async {
    final low = homeTeamId < awayTeamId ? homeTeamId : awayTeamId;
    final high = homeTeamId < awayTeamId ? awayTeamId : homeTeamId;

    final data = await _fetch(
      '/fixtures/headtohead',
      {'h2h': '$homeTeamId-$awayTeamId', 'last': last.toString()},
      cacheKey: 'h2h_${low}_${high}_$last',
    );
    if (data != null) {
      final summary = HeadToHeadSummary.fromFixtures(
        _asMapList(data).map(Fixture.fromApiFootball).toList(),
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );
      if (summary.hasData) return summary;
    }

    return FootballOfflineRepository.getHeadToHead(homeTeamId, awayTeamId);
  }

  /// Maçın olaylarını (gol, kart, oyuncu değişikliği) getirir (GET /fixtures/events?fixture=)
  Future<List<MatchEvent>> getFixtureEvents(int fixtureId) async {
    if (hasKey) {
      try {
        final data = await _fetch(
          '/fixtures/events',
          {'fixture': fixtureId.toString()},
          cacheKey: 'events_$fixtureId',
          ttl: const Duration(minutes: 2),
        );
        if (data != null) {
          return _asMapList(data).map((e) => MatchEvent(
            time: (e['time']['elapsed'] as num?)?.toInt() ?? 0,
            playerName: e['player']['name'] ?? 'Bilinmeyen',
            type: _mapEventType(e['type']),
            teamName: e['team']['name'] ?? '',
            detail: e['detail'],
          )).toList();
        }
      } catch (_) {}
    }
    return FootballOfflineRepository.getOfficialEvents(fixtureId);
  }

  MatchEventType _mapEventType(String? type) {
    if (type == 'Goal') return MatchEventType.goal;
    if (type == 'Card') return MatchEventType.card;
    return MatchEventType.substitution;
  }
  Future<BookmakerOdds?> getOddsForFixture(int fixtureId) async {
    final data = await _fetch(
      '/odds',
      {'fixture': fixtureId.toString()},
      cacheKey: 'odds_$fixtureId',
      ttl: const Duration(hours: 4),
    );
    if (data == null) return null;

    final list = _asMapList(data);
    if (list.isEmpty) return null;

    final fixtureRow = list.first;
    final bookmakers = fixtureRow['bookmakers'] as List? ?? [];
    if (bookmakers.isEmpty) return null;

    // Bet365 (id 8), Bwin (id 6), 1xBet (id 11) veya ilk mevcut büro
    Map<String, dynamic>? selectedBm;
    for (final b in bookmakers) {
      if (b is! Map) continue;
      final bm = Map<String, dynamic>.from(b);
      final id = (bm['id'] as num?)?.toInt();
      if (id == 8 || id == 6 || id == 11) {
        selectedBm = bm;
        break;
      }
    }
    selectedBm ??= bookmakers.first is Map ? Map<String, dynamic>.from(bookmakers.first) : null;
    if (selectedBm == null) return null;

    final bets = selectedBm['bets'] as List? ?? [];
    // Bet id 1: "Match Winner" (1X2)
    Map<String, dynamic>? matchWinnerBet;
    for (final b in bets) {
      if (b is! Map) continue;
      final bet = Map<String, dynamic>.from(b);
      final betId = (bet['id'] as num?)?.toInt();
      final betName = (bet['name'] ?? '').toString().toLowerCase();
      if (betId == 1 || betName.contains('match winner') || betName.contains('1x2')) {
        matchWinnerBet = bet;
        break;
      }
    }
    if (matchWinnerBet == null) return null;

    final values = matchWinnerBet['values'] as List? ?? [];
    double? homeOdd, drawOdd, awayOdd;

    for (final v in values) {
      if (v is! Map) continue;
      final val = (v['value'] ?? '').toString().toLowerCase();
      final odd = double.tryParse((v['odd'] ?? '').toString());
      if (odd == null || odd <= 1.0) continue;

      if (val == 'home' || val == '1') {
        homeOdd = odd;
      } else if (val == 'draw' || val == 'x') {
        drawOdd = odd;
      } else if (val == 'away' || val == '2') {
        awayOdd = odd;
      }
    }

    if (homeOdd != null && drawOdd != null && awayOdd != null) {
      return BookmakerOdds(
        bookmakerName: selectedBm['name'] ?? 'Piyasa',
        homeOdd: homeOdd,
        drawOdd: drawOdd,
        awayOdd: awayOdd,
        updatedAt: DateTime.tryParse((fixtureRow['update'] ?? '').toString()),
      );
    }
    return null;
  }

  /// Çevrimdışı test ve demo maçlar için makul piyasa oran simülatörü
  BookmakerOdds simulateMarketOdds({
    required double lambdaHome,
    required double lambdaAway,
    String bookmakerName = 'Piyasa Ortalaması',
  }) {
    double pHome = 0, pDraw = 0, pAway = 0;
    for (int h = 0; h <= 6; h++) {
      for (int a = 0; a <= 6; a++) {
        final p = (math.exp(-lambdaHome) * math.pow(lambdaHome, h) / _factorial(h)) *
            (math.exp(-lambdaAway) * math.pow(lambdaAway, a) / _factorial(a));
        if (h > a) {
          pHome += p;
        } else if (h == a) {
          pDraw += p;
        } else {
          pAway += p;
        }
      }
    }
    final total = pHome + pDraw + pAway;
    pHome /= total;
    pDraw /= total;
    pAway /= total;

    // Bürolar tipik %6-7 marj ekler (overround ≈ 1.06)
    const margin = 1.06;
    final homeOdd = (1.0 / (pHome * margin));
    final drawOdd = (1.0 / (pDraw * margin));
    final awayOdd = (1.0 / (pAway * margin));

    double round2(double v) => (v * 100).round() / 100.0;
    return BookmakerOdds(
      bookmakerName: bookmakerName,
      homeOdd: round2(math.max(1.05, math.min(25.0, homeOdd))),
      drawOdd: round2(math.max(1.50, math.min(15.0, drawOdd))),
      awayOdd: round2(math.max(1.05, math.min(25.0, awayOdd))),
      updatedAt: DateTime.now(),
    );
  }

  static double _factorial(int n) {
    if (n <= 1) return 1.0;
    double res = 1.0;
    for (int i = 2; i <= n; i++) {
      res *= i;
    }
    return res;
  }

  /// Bir maçın iki takımını gerçek istatistik, kadro ve sakatlıklarıyla hazırlar
  Future<FixtureTeams> buildTeamsForFixture(Fixture fixture) async {
    final home = await buildTeam(
      apiTeam: ApiTeam(
        id: fixture.homeTeamId,
        name: fixture.homeTeamName,
        country: fixture.leagueCountry,
        logo: fixture.homeTeamLogo,
      ),
      leagueId: fixture.leagueId,
      season: fixture.season,
      leagueName: fixture.leagueName,
    );

    final away = await buildTeam(
      apiTeam: ApiTeam(
        id: fixture.awayTeamId,
        name: fixture.awayTeamName,
        country: fixture.leagueCountry,
        logo: fixture.awayTeamLogo,
      ),
      leagueId: fixture.leagueId,
      season: fixture.season,
      leagueName: fixture.leagueName,
    );

    return FixtureTeams(home: home, away: away);
  }

  // ---------------------------------------------------------------------------
  // 3. Gerçek istatistik / kadro / sakatlık verileri
  // ---------------------------------------------------------------------------

  /// Takımın ilgili lig ve sezondaki gerçek istatistikleri (GET /teams/statistics).
  /// Veri yoksa (alt lig, oynanmamış sezon, anahtarsız mod) null döner.
  Future<MatchStat?> getTeamStatistics({
    required int teamId,
    required int leagueId,
    required int season,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/teams/statistics',
        {
          'team': teamId.toString(),
          'league': leagueId.toString(),
          'season': season.toString(),
        },
        cacheKey: 'teamstats_${teamId}_${leagueId}_$season',
        forceRefresh: forceRefresh,
      );

      if (data is! Map) return null;
      final stat = MatchStat.fromApiFootball(Map<String, dynamic>.from(data));
      return stat.hasData ? stat : null;
    } catch (_) {
      return null;
    }
  }

  /// Takımın oyuncu istatistikleri (GET /players?team=&season=).
  /// Kota tüketimini sınırlamak için yalnızca ilk sayfa (20 oyuncu) çekilir ve
  /// gol sayısına göre sıralanır; kilit oyuncular listenin başında olur.
  Future<List<Player>> getSquad({
    required int teamId,
    required int season,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/players',
        {'team': teamId.toString(), 'season': season.toString(), 'page': '1'},
        cacheKey: 'squad_${teamId}_$season',
        forceRefresh: forceRefresh,
      );

      if (data == null) return const [];

      final players = _asMapList(data)
          .map(Player.fromApiFootball)
          .where((p) => p.id.isNotEmpty)
          .toList()
        ..sort((a, b) {
          final byGoals = b.goals.compareTo(a.goals);
          return byGoals != 0 ? byGoals : b.rating.compareTo(a.rating);
        });

      return players;
    } catch (_) {
      return const [];
    }
  }

  /// Takımın güncel sakatlık listesi (GET /injuries?team=&season=).
  ///
  /// Uç nokta sezonun tamamındaki maç bazlı eksik kayıtlarını döndürdüğü için
  /// yalnızca en son maç tarihindeki kayıtlar "güncel eksik" kabul edilir.
  /// Dönen map: oyuncu id -> sakatlık gerekçesi.
  Future<Map<String, String>> getCurrentInjuries({
    required int teamId,
    required int season,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await _fetch(
        '/injuries',
        {'team': teamId.toString(), 'season': season.toString()},
        cacheKey: 'injuries_${teamId}_$season',
        forceRefresh: forceRefresh,
      );

      final rows = _asMapList(data);
      if (rows.isEmpty) return const {};

      String dateOf(Map<String, dynamic> row) {
        final fixture = row['fixture'];
        return fixture is Map ? (fixture['date'] ?? '').toString() : '';
      }

      final latestDate =
          rows.map(dateOf).where((d) => d.isNotEmpty).fold<String>('', (a, b) => b.compareTo(a) > 0 ? b : a);

      final injuries = <String, String>{};
      for (final row in rows) {
        // Tarih bilgisi olan kayıtlarda yalnızca en güncel maç günü dikkate alınır
        if (latestDate.isNotEmpty && dateOf(row) != latestDate) continue;

        final player = row['player'];
        if (player is! Map) continue;
        final id = (player['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final reason = (player['reason'] ?? player['type'] ?? 'Sakatlık').toString();
        injuries[id] = reason;
      }

      return injuries;
    } catch (_) {
      return const {};
    }
  }

  /// Bir takımın oynadığı ligleri getirir (GET /leagues?team=&season=).
  /// Global aramada lig bağlamı bilinmediği için istatistik çekmeden önce kullanılır.
  Future<League?> primaryLeagueForTeam(int teamId, int season) async {
    final data = await _fetch(
      '/leagues',
      {'team': teamId.toString(), 'season': season.toString()},
      cacheKey: 'teamleagues_${teamId}_$season',
    );

    final leagues = _asMapList(data).map(League.fromJson).toList();
    if (leagues.isEmpty) return null;

    // Kupa yerine lig tercih edilir: sezon istatistiği en anlamlı orada
    return leagues.firstWhere(
      (l) => !l.isCup,
      orElse: () => leagues.first,
    );
  }

  /// Lig bağlamı bilinmeyen (global aramadan gelen) takımı tam modele çevirir.
  Future<Team> buildTeamAutoLeague({
    required ApiTeam apiTeam,
    required int season,
  }) async {
    League? league;
    try {
      league = await primaryLeagueForTeam(apiTeam.id, season);
    } on ApiQuotaExceededException {
      rethrow;
    } catch (_) {
      league = null;
    }

    if (league == null) {
      // Lig bulunamadı: istatistiksiz (lig ortalaması) modda seçilir
      return apiTeam.toTeam(leagueName: apiTeam.country);
    }

    return buildTeam(
      apiTeam: apiTeam,
      leagueId: league.id,
      season: season,
      leagueName: league.name,
    );
  }

  /// Bir [ApiTeam]'i tahmin motorunun kullanabileceği tam [Team] modeline çevirir.
  ///
  /// İstatistik, kadro ve sakatlıklar gerçek uç noktalardan doldurulur.
  /// Veri bulunamazsa uydurma değer üretilmez; takım "sınırlı veri" modunda döner.
  /// Kota aşımı çağırana iletilir ki arayüz kullanıcıyı bilgilendirebilsin.
  Future<Team> buildTeam({
    required ApiTeam apiTeam,
    required int leagueId,
    required int season,
    required String leagueName,
  }) async {
    MatchStat? stats;
    List<Player> squad = const [];
    ApiQuotaExceededException? quotaError;

    try {
      stats = await getTeamStatistics(
        teamId: apiTeam.id,
        leagueId: leagueId,
        season: season,
      );
    } on ApiQuotaExceededException catch (e) {
      quotaError = e;
    } catch (_) {
      // Ağ/parse hatası: lig ortalaması baz alınarak devam edilir
    }

    if (quotaError == null) {
      try {
        squad = await getSquad(teamId: apiTeam.id, season: season);

        if (squad.isNotEmpty) {
          final injuries = await getCurrentInjuries(teamId: apiTeam.id, season: season);
          if (injuries.isNotEmpty) {
            squad = squad
                .map((p) => injuries.containsKey(p.id)
                    ? p.copyWith(isInjured: true, injuryReason: injuries[p.id])
                    : p)
                .toList();
          }
        }
      } on ApiQuotaExceededException catch (_) {
        // Kota aşıldı: gerçekçi yedek istatistikler kullanılacak
      } catch (_) {
        // Kadro alınamadı: yedek kadro devreye girecek
      }
    }

    // Gerçek veri çekilemediğinde veya kota dolduğunda gerçekçi istatistikler ve kadro devreye girer
    stats ??= FootballOfflineRepository.getRealisticStats(apiTeam.id, apiTeam.name, leagueName);
    if (squad.isEmpty) {
      squad = FootballOfflineRepository.getRealisticSquad(apiTeam.id, apiTeam.name);
    }

    return apiTeam.toTeam(leagueName: leagueName, stats: stats, squad: squad);
  }

  // ---------------------------------------------------------------------------
  // 4. Anahtarsız (çevrimdışı) demo verileri
  // ---------------------------------------------------------------------------
  //
  // Bu veriler yalnızca uygulamanın anahtar girilmeden denenebilmesi içindir.
  // Ülke listesi gerçek ve sabit bilgidir; lig/takım kapsamı ise sınırlıdır ve
  // tam dünya kapsamı için Ayarlar ekranından API-Football anahtarı gerekir.

  static const Map<String, String> _offlineCountryCodes = {
    'Turkey': 'TR', 'England': 'GB', 'Spain': 'ES', 'Germany': 'DE', 'Italy': 'IT',
    'France': 'FR', 'Netherlands': 'NL', 'Portugal': 'PT', 'Belgium': 'BE', 'Scotland': 'GB',
    'Austria': 'AT', 'Switzerland': 'CH', 'Greece': 'GR', 'Russia': 'RU', 'Ukraine': 'UA',
    'Poland': 'PL', 'Czech-Republic': 'CZ', 'Denmark': 'DK', 'Sweden': 'SE', 'Norway': 'NO',
    'Croatia': 'HR', 'Serbia': 'RS', 'Romania': 'RO', 'Bulgaria': 'BG', 'Hungary': 'HU',
    'Brazil': 'BR', 'Argentina': 'AR', 'Uruguay': 'UY', 'Chile': 'CL', 'Colombia': 'CO',
    'Mexico': 'MX', 'USA': 'US', 'Canada': 'CA', 'Japan': 'JP', 'South-Korea': 'KR',
    'China': 'CN', 'Australia': 'AU', 'Saudi-Arabia': 'SA', 'Qatar': 'QA', 'Egypt': 'EG',
    'Morocco': 'MA', 'Algeria': 'DZ', 'Tunisia': 'TN', 'South-Africa': 'ZA', 'Nigeria': 'NG',
  };

  List<Country> _offlineCountries() {
    final list = _offlineCountryCodes.entries
        .map((e) => Country(
              name: e.key.replaceAll('-', ' '),
              code: e.value,
              flag: 'https://media.api-sports.io/flags/${e.value.toLowerCase()}.svg',
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return [...list, Country(name: 'World', code: null, flag: null)];
  }

  /// Çevrimdışı modda yalnızca elimizde gerçek lig kimliği olan ülkeler döner.
  /// Diğer ülkelerde boş liste dönerek arayüz "anahtar ekleyin" uyarısı gösterir.
  List<League> _offlineLeagues(String country) {
    final seasons = SeasonUtils.recentSeasons(count: 2);
    return FootballOfflineRepository.getLeagues(country, seasons);
  }

  List<ApiTeam> _offlineTeams(int leagueId) {
    return FootballOfflineRepository.getTeams(leagueId);
  }

  List<ApiTeam> _offlineSearch(String term) {
    return FootballOfflineRepository.searchTeams(term);
  }
}

/// Bir maçın hazırlanmış ev sahibi ve deplasman takımları
class FixtureTeams {
  final Team home;
  final Team away;

  const FixtureTeams({required this.home, required this.away});
}
