class TeamLineup {
  final int teamId;
  final String teamName;
  final String teamLogo;
  final String? formation;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;

  TeamLineup({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    this.formation,
    required this.startXI,
    required this.substitutes,
  });

  factory TeamLineup.fromApiFootball(Map<String, dynamic> json) {
    final team = json['team'] as Map? ?? {};
    final startXIJson = json['startXI'] as List? ?? [];
    final substitutesJson = json['substitutes'] as List? ?? [];

    return TeamLineup(
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'] ?? '',
      formation: json['formation'],
      startXI: startXIJson.map((p) => LineupPlayer.fromApiFootball(p['player'])).toList(),
      substitutes: substitutesJson.map((p) => LineupPlayer.fromApiFootball(p['player'])).toList(),
    );
  }

  factory TeamLineup.fromEspnRoster(Map<String, dynamic> json) {
    final team = json['team'] as Map? ?? {};
    final roster = json['roster'] as List? ?? [];

    final startXI = <LineupPlayer>[];
    final substitutes = <LineupPlayer>[];

    for (final item in roster) {
      if (item is Map) {
        final player = LineupPlayer.fromEspn(Map<String, dynamic>.from(item));
        final isStarter = item['starter'] == true;
        if (isStarter) {
          startXI.add(player);
        } else {
          substitutes.add(player);
        }
      }
    }

    return TeamLineup(
      teamId: int.tryParse((team['id'] ?? '0').toString()) ?? 0,
      teamName: (team['displayName'] ?? team['name'] ?? '').toString(),
      teamLogo: (team['logo'] ?? '').toString(),
      formation: null,
      startXI: startXI,
      substitutes: substitutes,
    );
  }
}

class LineupPlayer {
  final int id;
  final String name;
  final int? number;
  final String? pos;
  final String? grid;

  LineupPlayer({
    required this.id,
    required this.name,
    this.number,
    this.pos,
    this.grid,
  });

  factory LineupPlayer.fromApiFootball(Map<String, dynamic> json) {
    return LineupPlayer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      number: json['number'],
      pos: json['pos'],
      grid: json['grid'],
    );
  }

  factory LineupPlayer.fromEspn(Map<String, dynamic> json) {
    final athlete = json['athlete'] as Map? ?? {};
    final posMap = json['position'] as Map? ?? {};

    return LineupPlayer(
      id: int.tryParse((athlete['id'] ?? '0').toString()) ?? 0,
      name: (athlete['displayName'] ?? athlete['fullName'] ?? athlete['shortName'] ?? '').toString(),
      number: int.tryParse((json['jersey'] ?? '').toString()),
      pos: (posMap['abbreviation'] ?? posMap['name'] ?? '').toString(),
      grid: null,
    );
  }
}
