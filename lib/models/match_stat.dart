import '../core/constants/league_constants.dart';

/// Takımın lig ve sezonluk detaylı istatistikleri
class MatchStat {
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsScored;
  final int goalsConceded;

  // İç Saha (Ev Sahibi) İstatistikleri
  final int homePlayed;
  final int homeWon;
  final int homeDrawn;
  final int homeLost;
  final int homeGoalsScored;
  final int homeGoalsConceded;

  // Dış Saha (Deplasman) İstatistikleri
  final int awayPlayed;
  final int awayWon;
  final int awayDrawn;
  final int awayLost;
  final int awayGoalsScored;
  final int awayGoalsConceded;

  // Oyun ve Şut İstatistikleri
  // Bu üç metrik takım bazlı sezon uç noktalarında yer almaz; veri yoksa null
  // kalır ve arayüzde uydurma değer yerine "veri yok" gösterilir.
  final double? avgPossession; // Topla oynama %
  final double? avgShotsPerGame;
  final double? avgShotsOnTarget;

  final int cleanSheets; // Gol yemediği maç sayısı

  // Son 5-10 Maç Form Dizisi, en yeni maç başta (Örn: ['W', 'W', 'D', 'W', 'L'])
  final List<String> recentForm;

  const MatchStat({
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsScored,
    required this.goalsConceded,
    required this.homePlayed,
    required this.homeWon,
    required this.homeDrawn,
    required this.homeLost,
    required this.homeGoalsScored,
    required this.homeGoalsConceded,
    required this.awayPlayed,
    required this.awayWon,
    required this.awayDrawn,
    required this.awayLost,
    required this.awayGoalsScored,
    required this.awayGoalsConceded,
    this.avgPossession,
    this.avgShotsPerGame,
    this.avgShotsOnTarget,
    required this.cleanSheets,
    required this.recentForm,
  });

  /// Gerçek sezon istatistiği çekilemediğinde kullanılan boş kayıt.
  /// Tüm ortalama getter'ları lig ortalamasına düştüğü için tahmin uydurma bir
  /// skora değil, saf lig ortalamasına yakınsar.
  factory MatchStat.unknown() => const MatchStat(
    played: 0,
    won: 0,
    drawn: 0,
    lost: 0,
    goalsScored: 0,
    goalsConceded: 0,
    homePlayed: 0,
    homeWon: 0,
    homeDrawn: 0,
    homeLost: 0,
    homeGoalsScored: 0,
    homeGoalsConceded: 0,
    awayPlayed: 0,
    awayWon: 0,
    awayDrawn: 0,
    awayLost: 0,
    awayGoalsScored: 0,
    awayGoalsConceded: 0,
    cleanSheets: 0,
    recentForm: [],
  );

  /// Gerçek maç verisi var mı? (false ise ortalamalar lig baz değerlerine düşer)
  bool get hasData => played > 0;

  /// Topla oynama / şut metrikleri mevcut mu?
  bool get hasTacticalMetrics =>
      avgPossession != null || avgShotsPerGame != null || avgShotsOnTarget != null;

  // Ortalamalar (veri yoksa lig ortalaması)
  double get avgGoalsScored => played > 0 ? goalsScored / played : LeagueConstants.avgGoals;
  double get avgGoalsConceded => played > 0 ? goalsConceded / played : LeagueConstants.avgGoals;

  double get avgHomeGoalsScored =>
      homePlayed > 0 ? homeGoalsScored / homePlayed : LeagueConstants.avgHomeGoals;
  double get avgHomeGoalsConceded =>
      homePlayed > 0 ? homeGoalsConceded / homePlayed : LeagueConstants.avgAwayGoals;

  double get avgAwayGoalsScored =>
      awayPlayed > 0 ? awayGoalsScored / awayPlayed : LeagueConstants.avgAwayGoals;
  double get avgAwayGoalsConceded =>
      awayPlayed > 0 ? awayGoalsConceded / awayPlayed : LeagueConstants.avgHomeGoals;

  double get winRate => played > 0 ? (won / played) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'goalsScored': goalsScored,
    'goalsConceded': goalsConceded,
    'homePlayed': homePlayed,
    'homeWon': homeWon,
    'homeDrawn': homeDrawn,
    'homeLost': homeLost,
    'homeGoalsScored': homeGoalsScored,
    'homeGoalsConceded': homeGoalsConceded,
    'awayPlayed': awayPlayed,
    'awayWon': awayWon,
    'awayDrawn': awayDrawn,
    'awayLost': awayLost,
    'awayGoalsScored': awayGoalsScored,
    'awayGoalsConceded': awayGoalsConceded,
    'avgPossession': avgPossession,
    'avgShotsPerGame': avgShotsPerGame,
    'avgShotsOnTarget': avgShotsOnTarget,
    'cleanSheets': cleanSheets,
    'recentForm': recentForm,
  };

  factory MatchStat.fromJson(Map<String, dynamic> json) => MatchStat(
    played: json['played'] ?? 0,
    won: json['won'] ?? 0,
    drawn: json['drawn'] ?? 0,
    lost: json['lost'] ?? 0,
    goalsScored: json['goalsScored'] ?? 0,
    goalsConceded: json['goalsConceded'] ?? 0,
    homePlayed: json['homePlayed'] ?? 0,
    homeWon: json['homeWon'] ?? 0,
    homeDrawn: json['homeDrawn'] ?? 0,
    homeLost: json['homeLost'] ?? 0,
    homeGoalsScored: json['homeGoalsScored'] ?? 0,
    homeGoalsConceded: json['homeGoalsConceded'] ?? 0,
    awayPlayed: json['awayPlayed'] ?? 0,
    awayWon: json['awayWon'] ?? 0,
    awayDrawn: json['awayDrawn'] ?? 0,
    awayLost: json['awayLost'] ?? 0,
    awayGoalsScored: json['awayGoalsScored'] ?? 0,
    awayGoalsConceded: json['awayGoalsConceded'] ?? 0,
    avgPossession: (json['avgPossession'] as num?)?.toDouble(),
    avgShotsPerGame: (json['avgShotsPerGame'] as num?)?.toDouble(),
    avgShotsOnTarget: (json['avgShotsOnTarget'] as num?)?.toDouble(),
    cleanSheets: json['cleanSheets'] ?? 0,
    recentForm: List<String>.from(json['recentForm'] ?? []),
  );

  /// API-Football `GET /teams/statistics` yanıtını modele çevirir.
  ///
  /// Yanıt yapısı: `fixtures.played.{home,away,total}`, `goals.for.total.{...}`,
  /// `goals.against.total.{...}`, `clean_sheet.{...}`, `form` (eskiden yeniye "WDLWW").
  factory MatchStat.fromApiFootball(Map<String, dynamic> json) {
    Map? branch(dynamic parent, String key) => parent is Map ? parent[key] as Map? : null;
    int leaf(dynamic group, String key) =>
        group is Map ? (group[key] as num?)?.toInt() ?? 0 : 0;

    final fixtures = branch(json, 'fixtures');
    final goals = branch(json, 'goals');
    final goalsFor = branch(branch(goals, 'for'), 'total');
    final goalsAgainst = branch(branch(goals, 'against'), 'total');
    final cleanSheet = branch(json, 'clean_sheet');

    final played = branch(fixtures, 'played');
    final wins = branch(fixtures, 'wins');
    final draws = branch(fixtures, 'draws');
    final loses = branch(fixtures, 'loses');

    // API-Football form dizisi eskiden yeniye sıralıdır; motor en yeni maçı başta
    // beklediği için son 5 maç ters çevrilerek alınır.
    final rawForm = (json['form'] as String? ?? '')
        .split('')
        .where((c) => c.trim().isNotEmpty)
        .toList();
    final last5 = rawForm.length > 5 ? rawForm.sublist(rawForm.length - 5) : rawForm;

    return MatchStat(
      played: leaf(played, 'total'),
      won: leaf(wins, 'total'),
      drawn: leaf(draws, 'total'),
      lost: leaf(loses, 'total'),
      goalsScored: leaf(goalsFor, 'total'),
      goalsConceded: leaf(goalsAgainst, 'total'),
      homePlayed: leaf(played, 'home'),
      homeWon: leaf(wins, 'home'),
      homeDrawn: leaf(draws, 'home'),
      homeLost: leaf(loses, 'home'),
      homeGoalsScored: leaf(goalsFor, 'home'),
      homeGoalsConceded: leaf(goalsAgainst, 'home'),
      awayPlayed: leaf(played, 'away'),
      awayWon: leaf(wins, 'away'),
      awayDrawn: leaf(draws, 'away'),
      awayLost: leaf(loses, 'away'),
      awayGoalsScored: leaf(goalsFor, 'away'),
      awayGoalsConceded: leaf(goalsAgainst, 'away'),
      cleanSheets: leaf(cleanSheet, 'total'),
      recentForm: last5.reversed.toList(),
    );
  }

  /// Standings puan durumu satırlarından (TOTAL / HOME / AWAY tabloları)
  /// tek bir takımın istatistiğini üretir.
  factory MatchStat.fromStandingsRows({
    required Map<String, dynamic> total,
    Map<String, dynamic>? home,
    Map<String, dynamic>? away,
  }) {
    int val(Map<String, dynamic>? row, String key) => (row?[key] as num?)?.toInt() ?? 0;

    // football-data form alanı "W,D,L,W,W" biçimindedir ve eskiden yeniye sıralıdır.
    final rawForm = (total['form'] as String? ?? '')
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final last5 = rawForm.length > 5 ? rawForm.sublist(rawForm.length - 5) : rawForm;

    return MatchStat(
      played: val(total, 'playedGames'),
      won: val(total, 'won'),
      drawn: val(total, 'draw'),
      lost: val(total, 'lost'),
      goalsScored: val(total, 'goalsFor'),
      goalsConceded: val(total, 'goalsAgainst'),
      homePlayed: val(home, 'playedGames'),
      homeWon: val(home, 'won'),
      homeDrawn: val(home, 'draw'),
      homeLost: val(home, 'lost'),
      homeGoalsScored: val(home, 'goalsFor'),
      homeGoalsConceded: val(home, 'goalsAgainst'),
      awayPlayed: val(away, 'playedGames'),
      awayWon: val(away, 'won'),
      awayDrawn: val(away, 'draw'),
      awayLost: val(away, 'lost'),
      awayGoalsScored: val(away, 'goalsFor'),
      awayGoalsConceded: val(away, 'goalsAgainst'),
      // Puan durumu clean sheet vermez; bilinmiyor olarak 0 bırakılır.
      cleanSheets: 0,
      recentForm: last5.reversed.toList(),
    );
  }
}
