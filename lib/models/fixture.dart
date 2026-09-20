import 'sport_type.dart';

/// API-Football maç (fikstür) modeli — `GET /fixtures`
///
/// Yanıt yapısı:
/// ```
/// { "fixture": { "id", "date", "status": { "short", "long", "elapsed" }, "venue": {...} },
///   "league":  { "id", "name", "country", "logo", "season", "round" },
///   "teams":   { "home": { "id", "name", "logo", "winner" }, "away": {...} },
///   "goals":   { "home", "away" },
///   "score":   { "halftime": {...}, "fulltime": {...} } }
/// ```
class Fixture {
  final int id;
  final DateTime? date;
  final String statusShort; // NS, 1H, HT, 2H, FT, AET, PEN, PST, CANC...
  final String statusLong;
  final int? elapsed;

  final int leagueId;
  final String leagueName;
  final String leagueLogo;
  final String leagueCountry;
  final int season;
  final String round;

  final int homeTeamId;
  final String homeTeamName;
  final String homeTeamLogo;

  final int awayTeamId;
  final String awayTeamName;
  final String awayTeamLogo;

  final int? homeGoals;
  final int? awayGoals;

  final int homeRedCards;
  final int awayRedCards;
  final int homeYellowCards;
  final int awayYellowCards;
  final String leagueCode;

  final String? venueName;
  final String? referee;
  final SportType sportType;

  Fixture({
    required this.id,
    this.date,
    required this.statusShort,
    this.statusLong = '',
    this.elapsed,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogo = '',
    this.leagueCountry = '',
    required this.season,
    this.round = '',
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogo = '',
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogo = '',
    this.homeGoals,
    this.awayGoals,
    this.homeRedCards = 0,
    this.awayRedCards = 0,
    this.homeYellowCards = 0,
    this.awayYellowCards = 0,
    this.leagueCode = '',
    this.venueName,
    this.referee,
    this.sportType = SportType.soccer,
  });

  Fixture copyWith({
    int? id,
    DateTime? date,
    String? statusShort,
    String? statusLong,
    int? elapsed,
    int? leagueId,
    String? leagueName,
    String? leagueLogo,
    String? leagueCountry,
    int? season,
    String? round,
    int? homeTeamId,
    String? homeTeamName,
    String? homeTeamLogo,
    int? awayTeamId,
    String? awayTeamName,
    String? awayTeamLogo,
    int? homeGoals,
    int? awayGoals,
    int? homeRedCards,
    int? awayRedCards,
    int? homeYellowCards,
    int? awayYellowCards,
    String? leagueCode,
    String? venueName,
    String? referee,
    SportType? sportType,
  }) {
    return Fixture(
      id: id ?? this.id,
      date: date ?? this.date,
      statusShort: statusShort ?? this.statusShort,
      statusLong: statusLong ?? this.statusLong,
      elapsed: elapsed ?? this.elapsed,
      leagueId: leagueId ?? this.leagueId,
      leagueName: leagueName ?? this.leagueName,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      leagueCountry: leagueCountry ?? this.leagueCountry,
      season: season ?? this.season,
      round: round ?? this.round,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
      homeRedCards: homeRedCards ?? this.homeRedCards,
      awayRedCards: awayRedCards ?? this.awayRedCards,
      homeYellowCards: homeYellowCards ?? this.homeYellowCards,
      awayYellowCards: awayYellowCards ?? this.awayYellowCards,
      leagueCode: leagueCode ?? this.leagueCode,
      venueName: venueName ?? this.venueName,
      referee: referee ?? this.referee,
      sportType: sportType ?? this.sportType,
    );
  }

  /// Maç oynandı ve kesin sonuç belli mi? (normal süre, uzatma veya penaltı)
  bool get isFinished => const ['FT', 'AET', 'PEN'].contains(statusShort);

  /// Henüz başlamamış mı?
  bool get isUpcoming => const ['TBD', 'NS'].contains(statusShort);

  /// Şu anda oynanıyor mu?
  bool get isLive => const ['1H', 'HT', '2H', 'ET', 'BT', 'P', 'LIVE', 'INT'].contains(statusShort);

  /// Ertelendi / iptal edildi mi? (sonuç asla gelmeyebilir)
  bool get isCancelled => const ['PST', 'CANC', 'ABD', 'AWD', 'WO'].contains(statusShort);

  bool get hasScore => homeGoals != null && awayGoals != null;

  String get scoreString => hasScore ? '$homeGoals - $awayGoals' : '-';

  String get matchup => '$homeTeamName - $awayTeamName';

  /// Durumun Türkçe kısa karşılığı
  String get statusLabel {
    if (isLive) return elapsed != null ? "$elapsed'" : 'Canlı';
    if (isFinished) return statusShort == 'FT' ? 'Bitti' : 'Bitti ($statusShort)';
    if (isCancelled) return statusShort == 'PST' ? 'Ertelendi' : 'İptal';
    
    // Saat geçmiş ama hala NS (Başlamadı) görünüyorsa 'Oynanıyor' veya 'Bitti' uyarısı ver
    if (statusShort == 'NS' && date != null && DateTime.now().isAfter(date!)) {
      final diff = DateTime.now().difference(date!);
      if (diff.inMinutes < 120) return 'Oynanıyor';
      return 'Sonuç Bekleniyor';
    }

    return 'Oynanmadı';
  }

  factory Fixture.fromApiFootball(Map<String, dynamic> json) {
    Map<String, dynamic> branch(dynamic parent, String key) {
      if (parent is Map && parent[key] is Map) {
        return Map<String, dynamic>.from(parent[key] as Map);
      }
      return <String, dynamic>{};
    }

    final fixture = branch(json, 'fixture');
    final status = branch(fixture, 'status');
    final venue = branch(fixture, 'venue');
    final league = branch(json, 'league');
    final teams = branch(json, 'teams');
    final home = branch(teams, 'home');
    final away = branch(teams, 'away');
    final goals = branch(json, 'goals');

    return Fixture(
      id: (fixture['id'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse('${fixture['date'] ?? ''}')?.toLocal(),
      statusShort: (status['short'] ?? 'NS').toString(),
      statusLong: (status['long'] ?? '').toString(),
      elapsed: (status['elapsed'] as num?)?.toInt(),
      leagueId: (league['id'] as num?)?.toInt() ?? 0,
      leagueName: (league['name'] ?? 'Lig').toString(),
      leagueLogo: (league['logo'] ?? '').toString(),
      leagueCountry: (league['country'] ?? '').toString(),
      season: (league['season'] as num?)?.toInt() ?? 0,
      round: (league['round'] ?? '').toString(),
      homeTeamId: (home['id'] as num?)?.toInt() ?? 0,
      homeTeamName: (home['name'] ?? '').toString(),
      homeTeamLogo: (home['logo'] ?? '').toString(),
      awayTeamId: (away['id'] as num?)?.toInt() ?? 0,
      awayTeamName: (away['name'] ?? '').toString(),
      awayTeamLogo: (away['logo'] ?? '').toString(),
      homeGoals: (goals['home'] as num?)?.toInt(),
      awayGoals: (goals['away'] as num?)?.toInt(),
      venueName: venue['name']?.toString(),
      referee: fixture['referee']?.toString(),
    );
  }

  /// Tahmin motoruna girecek `ApiTeam` benzeri sade takım bilgisi
  Map<String, dynamic> get homeTeamJson => {
    'id': homeTeamId,
    'name': homeTeamName,
    'logo': homeTeamLogo,
    'country': leagueCountry,
  };

  Map<String, dynamic> get awayTeamJson => {
    'id': awayTeamId,
    'name': awayTeamName,
    'logo': awayTeamLogo,
    'country': leagueCountry,
  };

  factory Fixture.fromVolleyballApi(Map<String, dynamic> json) {
    Map<String, dynamic> branch(dynamic parent, String key) {
      if (parent is Map && parent[key] is Map) {
        return Map<String, dynamic>.from(parent[key] as Map);
      }
      return <String, dynamic>{};
    }

    final league = branch(json, 'league');
    final country = branch(json, 'country');
    final teams = branch(json, 'teams');
    final home = branch(teams, 'home');
    final away = branch(teams, 'away');
    final status = branch(json, 'status');
    final scores = branch(json, 'scores');

    return Fixture(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse('${json['date'] ?? ''}')?.toLocal(),
      statusShort: (status['short'] ?? 'NS').toString(),
      statusLong: (status['long'] ?? '').toString(),
      leagueId: (league['id'] as num?)?.toInt() ?? 0,
      leagueName: (league['name'] ?? 'Voleybol Ligi').toString(),
      leagueLogo: (league['logo'] ?? '').toString(),
      leagueCountry: (country['name'] ?? '').toString(),
      season: (league['season'] as num?)?.toInt() ?? 2026,
      homeTeamId: (home['id'] as num?)?.toInt() ?? 0,
      homeTeamName: (home['name'] ?? 'Ev Sahibi').toString(),
      homeTeamLogo: (home['logo'] ?? '').toString(),
      awayTeamId: (away['id'] as num?)?.toInt() ?? 0,
      awayTeamName: (away['name'] ?? 'Deplasman').toString(),
      awayTeamLogo: (away['logo'] ?? '').toString(),
      homeGoals: (scores['home'] as num?)?.toInt(),
      awayGoals: (scores['away'] as num?)?.toInt(),
      sportType: SportType.volleyball,
    );
  }

  factory Fixture.fromBasketballApi(Map<String, dynamic> json) {
    Map<String, dynamic> branch(dynamic parent, String key) {
      if (parent is Map && parent[key] is Map) {
        return Map<String, dynamic>.from(parent[key] as Map);
      }
      return <String, dynamic>{};
    }

    final league = branch(json, 'league');
    final country = branch(json, 'country');
    final teams = branch(json, 'teams');
    final home = branch(teams, 'home');
    final away = branch(teams, 'away');
    final status = branch(json, 'status');
    final scores = branch(json, 'scores');

    return Fixture(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse('${json['date'] ?? ''}')?.toLocal(),
      statusShort: (status['short'] ?? 'NS').toString(),
      statusLong: (status['long'] ?? '').toString(),
      leagueId: (league['id'] as num?)?.toInt() ?? 0,
      leagueName: (league['name'] ?? 'Basketbol Ligi').toString(),
      leagueLogo: (league['logo'] ?? '').toString(),
      leagueCountry: (country['name'] ?? '').toString(),
      season: (league['season'] as num?)?.toInt() ?? 2026,
      homeTeamId: (home['id'] as num?)?.toInt() ?? 0,
      homeTeamName: (home['name'] ?? 'Ev Sahibi').toString(),
      homeTeamLogo: (home['logo'] ?? '').toString(),
      awayTeamId: (away['id'] as num?)?.toInt() ?? 0,
      awayTeamName: (away['name'] ?? 'Deplasman').toString(),
      awayTeamLogo: (away['logo'] ?? '').toString(),
      homeGoals: (scores['home'] is Map ? (scores['home']['total'] as num?)?.toInt() : (scores['home'] as num?)?.toInt()),
      awayGoals: (scores['away'] is Map ? (scores['away']['total'] as num?)?.toInt() : (scores['away'] as num?)?.toInt()),
      sportType: SportType.basketball,
    );
  }

  factory Fixture.fromEspn(
    Map<String, dynamic> json, {
    required String defaultLeagueName,
    required String defaultCountry,
    required int defaultLeagueId,
    required String defaultLeagueLogo,
    required String leagueCode,
  }) {
    final competitionList = json['competitions'] as List? ?? [];
    final competition = competitionList.isNotEmpty && competitionList.first is Map
        ? Map<String, dynamic>.from(competitionList.first as Map)
        : <String, dynamic>{};

    final competitors = competition['competitors'] as List? ?? [];
    Map<String, dynamic> homeComp = {};
    Map<String, dynamic> awayComp = {};

    for (final c in competitors) {
      if (c is Map) {
        if (c['homeAway'] == 'home') {
          homeComp = Map<String, dynamic>.from(c);
        } else {
          awayComp = Map<String, dynamic>.from(c);
        }
      }
    }

    final homeTeam = homeComp['team'] is Map ? Map<String, dynamic>.from(homeComp['team']) : {};
    final awayTeam = awayComp['team'] is Map ? Map<String, dynamic>.from(awayComp['team']) : {};

    final status = json['status'] is Map ? Map<String, dynamic>.from(json['status']) : {};
    final statusType = status['type'] is Map ? Map<String, dynamic>.from(status['type']) : {};
    final state = statusType['state']?.toString() ?? 'pre';
    final typeName = statusType['name']?.toString() ?? '';
    final completed = statusType['completed'] == true;

    String statusShort;
    if (completed || state == 'post') {
      statusShort = 'FT';
    } else if (state == 'in') {
      if (typeName.contains('HALFTIME') || typeName.contains('STATUS_HALFTIME')) {
        statusShort = 'HT';
      } else {
        final period = (status['period'] as num?)?.toInt() ?? 1;
        statusShort = period == 1 ? '1H' : '2H';
      }
    } else {
      statusShort = 'NS';
    }

    int? elapsed;
    final displayClock = status['displayClock']?.toString();
    if (displayClock != null && displayClock.isNotEmpty) {
      final digits = RegExp(r'^\d+').stringMatch(displayClock);
      if (digits != null) elapsed = int.tryParse(digits);
    }
    if (elapsed == null && status['clock'] is num) {
      elapsed = ((status['clock'] as num).toDouble() / 60.0).round();
    }

    // Kart sayılarını details dizisinden say
    int homeReds = 0;
    int awayReds = 0;
    int homeYellows = 0;
    int awayYellows = 0;

    final homeTeamIdStr = (homeTeam['id'] ?? '').toString();
    final awayTeamIdStr = (awayTeam['id'] ?? '').toString();

    final details = competition['details'] as List? ?? [];
    for (final d in details) {
      if (d is Map) {
        final typeText = (d['type'] is Map ? d['type']['text'] : '').toString().toLowerCase();
        final teamId = (d['team'] is Map ? d['team']['id'] : '').toString();
        final isRed = d['redCard'] == true || typeText.contains('red card');
        final isYellow = d['yellowCard'] == true || typeText.contains('yellow card');

        if (teamId == homeTeamIdStr) {
          if (isRed) homeReds++;
          if (isYellow) homeYellows++;
        } else if (teamId == awayTeamIdStr) {
          if (isRed) awayReds++;
          if (isYellow) awayYellows++;
        }
      }
    }

    final venue = competition['venue'] is Map ? competition['venue']['displayName']?.toString() : null;

    return Fixture(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      date: DateTime.tryParse('${json['date'] ?? ''}')?.toLocal(),
      statusShort: statusShort,
      statusLong: (statusType['description'] ?? '').toString(),
      elapsed: elapsed,
      leagueId: defaultLeagueId,
      leagueName: defaultLeagueName,
      leagueLogo: defaultLeagueLogo,
      leagueCountry: defaultCountry,
      season: 2026,
      homeTeamId: int.tryParse(homeTeamIdStr) ?? 0,
      homeTeamName: (homeTeam['displayName'] ?? homeTeam['name'] ?? 'Ev Sahibi').toString(),
      homeTeamLogo: (homeTeam['logo'] ?? '').toString(),
      awayTeamId: int.tryParse(awayTeamIdStr) ?? 0,
      awayTeamName: (awayTeam['displayName'] ?? awayTeam['name'] ?? 'Deplasman').toString(),
      awayTeamLogo: (awayTeam['logo'] ?? '').toString(),
      homeGoals: int.tryParse((homeComp['score'] ?? '').toString()),
      awayGoals: int.tryParse((awayComp['score'] ?? '').toString()),
      homeRedCards: homeReds,
      awayRedCards: awayReds,
      homeYellowCards: homeYellows,
      awayYellowCards: awayYellows,
      leagueCode: leagueCode,
      venueName: venue,
      sportType: SportType.soccer,
    );
  }
}
