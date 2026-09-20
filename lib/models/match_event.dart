enum MatchEventType { goal, card, substitution }

class MatchEvent {
  final int time;
  final String playerName;
  final MatchEventType type;
  final String? detail; // "Yellow Card", "Red Card", "Icardi (In)" vb.
  final String teamName;

  MatchEvent({
    required this.time,
    required this.playerName,
    required this.type,
    required this.teamName,
    this.detail,
  });

  String get icon {
    switch (type) {
      case MatchEventType.goal: return '⚽';
      case MatchEventType.card: return detail?.contains('Red') == true ? '🟥' : '🟨';
      case MatchEventType.substitution: return '🔄';
    }
  }

  factory MatchEvent.fromEspn(Map<String, dynamic> json, {String defaultTeam = ''}) {
    final typeObj = json['type'] as Map? ?? {};
    final typeText = (typeObj['text'] ?? '').toString();
    final clock = json['clock'] as Map? ?? {};
    final clockStr = (clock['displayValue'] ?? '').toString();
    final digits = RegExp(r'^\d+').stringMatch(clockStr);
    final time = digits != null ? int.tryParse(digits) ?? 0 : ((clock['value'] as num?)?.toDouble() ?? 0) ~/ 60;

    MatchEventType eventType = MatchEventType.substitution;
    final lower = typeText.toLowerCase();
    if (lower.contains('goal')) {
      eventType = MatchEventType.goal;
    } else if (lower.contains('card')) {
      eventType = MatchEventType.card;
    }

    final athletes = json['athletesInvolved'] as List? ?? [];
    String playerName = 'Oyuncu';
    if (athletes.isNotEmpty && athletes.first is Map) {
      playerName = (athletes.first['displayName'] ?? athletes.first['shortName'] ?? 'Oyuncu').toString();
    } else {
      final text = (json['text'] ?? '').toString();
      if (text.contains('(')) {
        playerName = text.split('(').first.trim();
      }
    }

    final teamObj = json['team'] as Map? ?? {};
    final teamName = (teamObj['displayName'] ?? teamObj['name'] ?? defaultTeam).toString();

    return MatchEvent(
      time: time,
      playerName: playerName,
      type: eventType,
      teamName: teamName,
      detail: typeText.isNotEmpty ? typeText : json['text']?.toString(),
    );
  }
}
