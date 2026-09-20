import 'match_stat.dart';
import 'player.dart';

/// Futbol Takımı Model Sınıfı
class Team {
  /// [dataSource] değerleri. Tek ana kaynak API-Football'dur.
  static const String sourceApiFootball = 'api-football';
  static const String sourceMock = 'mock';

  final String id;
  final String name;
  final String shortName;
  final String crestUrl; // Takım logosu URL'i
  final String league;
  final String venue; // Stadyum
  final MatchStat stats;
  final List<Player> squad;

  /// Takımın hangi veri kaynağından geldiği
  final String dataSource;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.crestUrl,
    required this.league,
    required this.venue,
    required this.stats,
    required this.squad,
    this.dataSource = sourceApiFootball,
  });

  /// Sayısal API-Football kimliği (tüm takımlarda H2H ve istatistik sorgusu çalışır)
  int? get apiFootballId => int.tryParse(id);

  /// Baş harf gösterimleri için güvenli kısaltma (boş isimde çökmez)
  String get initial {
    final source = shortName.trim().isNotEmpty ? shortName.trim() : name.trim();
    return source.isNotEmpty ? source.substring(0, 1).toUpperCase() : '?';
  }

  /// Takımın kilit golcüsü
  Player? get topScorer {
    if (squad.isEmpty) return null;
    final sorted = List<Player>.from(squad)
      ..sort((a, b) => b.goals.compareTo(a.goals));
    return sorted.first;
  }

  /// Takımın kilit asistçisi
  Player? get topAssistProvider {
    if (squad.isEmpty) return null;
    final sorted = List<Player>.from(squad)
      ..sort((a, b) => b.assists.compareTo(a.assists));
    return sorted.first;
  }

  /// Sakat oyuncu sayısı
  int get injuredCount => squad.where((p) => p.isInjured).length;

  /// Sakat oyuncuların listesi
  List<Player> get injuredPlayers => squad.where((p) => p.isInjured).toList();

  /// Kadro veya istatistik güncellemelerinde paylaşılan nesneyi bozmadan kopya üretir
  Team copyWith({MatchStat? stats, List<Player>? squad}) => Team(
    id: id,
    name: name,
    shortName: shortName,
    crestUrl: crestUrl,
    league: league,
    venue: venue,
    stats: stats ?? this.stats,
    squad: squad ?? this.squad,
    dataSource: dataSource,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'crestUrl': crestUrl,
    'league': league,
    'venue': venue,
    'stats': stats.toJson(),
    'squad': squad.map((p) => p.toJson()).toList(),
    'dataSource': dataSource,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    shortName: json['shortName'] ?? '',
    crestUrl: json['crestUrl'] ?? '',
    league: json['league'] ?? '',
    venue: json['venue'] ?? '',
    stats: MatchStat.fromJson(json['stats'] ?? {}),
    squad: (json['squad'] as List? ?? [])
        .map((p) => Player.fromJson(p))
        .toList(),
    dataSource: json['dataSource'] ?? sourceApiFootball,
  );
}
