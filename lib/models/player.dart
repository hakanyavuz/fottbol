/// Futbolcu model sınıfı (gol, asist, form ve sakatlık durumu)
class Player {
  final String id;
  final String name;
  final String position; // Kaleci, Defans, Orta Saha, Forvet
  final int goals;
  final int assists;
  final int matchesPlayed;
  final double rating; // 10 üzerinden sezonluk/son maç performansı
  final bool isInjured; // Sakatlık durumu (algoritmayı doğrudan etkiler)
  final String? injuryReason;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.goals,
    required this.assists,
    required this.matchesPlayed,
    required this.rating,
    this.isInjured = false,
    this.injuryReason,
  });

  /// Sakatlık durumunun takımın hücum veya savunma gücüne negatif etkisi katsayısı.
  /// [teamGoals] verilirse oyuncunun gol payı doğrudan dikkate alınır (azami %20 ceza).
  double dynamicAttackPenalty([int? teamGoals]) {
    if (!isInjured) return 0.0;
    if (teamGoals != null && teamGoals > 0 && goals > 0) {
      final share = goals / teamGoals;
      return (share * 0.45).clamp(0.04, 0.20);
    }
    if (position == 'Forvet' && goals >= 5) return 0.14;
    if (position == 'Orta Saha' && assists >= 4) return 0.09;
    return 0.03;
  }

  double get attackPenalty => dynamicAttackPenalty();

  double get defensePenalty {
    if (!isInjured) return 0.0;
    if (position == 'Kaleci' && rating >= 7.0) return 0.16; // As kaleci yoksa %16 savunma zafiyeti
    if (position == 'Defans' && rating >= 7.0) return 0.12; // Kilit stoper yoksa %12 zafiyet
    if (position == 'Defans') return 0.06;
    return 0.02;
  }

  /// Sakatlık durumu değiştirilmiş yeni bir kopya üretir.
  /// Oyuncu sakat değilse gerekçe otomatik temizlenir.
  Player copyWith({bool? isInjured, String? injuryReason}) {
    final injured = isInjured ?? this.isInjured;
    return Player(
      id: id,
      name: name,
      position: position,
      goals: goals,
      assists: assists,
      matchesPlayed: matchesPlayed,
      rating: rating,
      isInjured: injured,
      injuryReason: injured ? (injuryReason ?? this.injuryReason) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position,
    'goals': goals,
    'assists': assists,
    'matchesPlayed': matchesPlayed,
    'rating': rating,
    'isInjured': isInjured,
    'injuryReason': injuryReason,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    position: json['position'] ?? 'Orta Saha',
    goals: json['goals'] ?? 0,
    assists: json['assists'] ?? 0,
    matchesPlayed: json['matchesPlayed'] ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 6.5,
    isInjured: json['isInjured'] ?? false,
    injuryReason: json['injuryReason'],
  );

  /// API-Football `GET /players?team=&season=` yanıtındaki tek bir kaydı çevirir.
  /// Yanıt: `{ "player": {...}, "statistics": [ { "games": {...}, "goals": {...} } ] }`
  factory Player.fromApiFootball(Map<String, dynamic> json) {
    final p = json['player'] is Map ? json['player'] as Map : const {};
    final statsList = json['statistics'] is List ? json['statistics'] as List : const [];
    final s = statsList.isNotEmpty && statsList.first is Map
        ? statsList.first as Map
        : const {};
    final games = s['games'] is Map ? s['games'] as Map : const {};
    final goals = s['goals'] is Map ? s['goals'] as Map : const {};

    return Player(
      id: (p['id'] ?? '').toString(),
      name: (p['name'] ?? 'Bilinmeyen Oyuncu').toString(),
      position: mapPosition(games['position'] as String?),
      goals: (goals['total'] as num?)?.toInt() ?? 0,
      assists: (goals['assists'] as num?)?.toInt() ?? 0,
      matchesPlayed: (games['appearences'] as num?)?.toInt() ?? 0,
      // Rating string olarak gelir ("7.324567"); süre almamış oyuncuda null olur.
      rating: double.tryParse('${games['rating'] ?? ''}') ?? 0.0,
    );
  }

  /// İngilizce pozisyon adlarını uygulamanın kullandığı Türkçe karşılıklara çevirir.
  static String mapPosition(String? pos) {
    if (pos == null) return 'Orta Saha';
    final p = pos.toLowerCase();
    if (p.contains('goalkeeper') || p.contains('keeper')) return 'Kaleci';
    if (p.contains('defen') || p.contains('back')) return 'Defans';
    // "Attacking Midfield" gibi bileşik adlarda orta saha kontrolü önce gelmeli
    if (p.contains('midfield')) return 'Orta Saha';
    if (p.contains('attack') ||
        p.contains('forward') ||
        p.contains('offence') ||
        p.contains('striker') ||
        p.contains('wing')) {
      return 'Forvet';
    }
    return 'Orta Saha';
  }
}
