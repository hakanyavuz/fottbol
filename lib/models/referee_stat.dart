/// Hakem İstatistikleri ve Maç Yönetim Eğilim Modeli
class RefereeStat {
  final String name;
  final int matchesCount;
  final double avgYellowCards;
  final double avgRedCards;
  final double avgFouls;
  final double avgPenalties;
  final double homeWinPercentage;
  final double awayWinPercentage;
  final double drawPercentage;

  const RefereeStat({
    required this.name,
    this.matchesCount = 25,
    this.avgYellowCards = 4.5,
    this.avgRedCards = 0.20,
    this.avgFouls = 26.0,
    this.avgPenalties = 0.35,
    this.homeWinPercentage = 44.0,
    this.drawPercentage = 28.0,
    this.awayWinPercentage = 28.0,
  });

  /// Hakemin kart sertlik derecesi: "Sert", "Dengeli", "Müsamahakar"
  String get strictnessRating {
    if (avgYellowCards >= 5.0 || avgRedCards >= 0.28) return 'Sert / Kartına Sadık';
    if (avgYellowCards <= 3.8 && avgRedCards <= 0.15) return 'Müsamahakar / Akıcı Oyun';
    return 'Dengeli / Standart';
  }

  /// Hakemin penaltı eğilimi yüksek mi?
  bool get hasHighPenaltyTendency => avgPenalties >= 0.40;

  Map<String, dynamic> toJson() => {
    'name': name,
    'matchesCount': matchesCount,
    'avgYellowCards': avgYellowCards,
    'avgRedCards': avgRedCards,
    'avgFouls': avgFouls,
    'avgPenalties': avgPenalties,
    'homeWinPercentage': homeWinPercentage,
    'drawPercentage': drawPercentage,
    'awayWinPercentage': awayWinPercentage,
  };

  factory RefereeStat.fromJson(Map<String, dynamic> json) => RefereeStat(
    name: json['name'] ?? '',
    matchesCount: (json['matchesCount'] as num?)?.toInt() ?? 25,
    avgYellowCards: (json['avgYellowCards'] as num?)?.toDouble() ?? 4.5,
    avgRedCards: (json['avgRedCards'] as num?)?.toDouble() ?? 0.20,
    avgFouls: (json['avgFouls'] as num?)?.toDouble() ?? 26.0,
    avgPenalties: (json['avgPenalties'] as num?)?.toDouble() ?? 0.35,
    homeWinPercentage: (json['homeWinPercentage'] as num?)?.toDouble() ?? 44.0,
    drawPercentage: (json['drawPercentage'] as num?)?.toDouble() ?? 28.0,
    awayWinPercentage: (json['awayWinPercentage'] as num?)?.toDouble() ?? 28.0,
  );

  /// İsme göre resmi hakem profili üretir
  static RefereeStat forName(String rawName) {
    final clean = rawName.replaceAll(RegExp(r'\([A-Z]\)'), '').trim();
    final lower = clean.toLowerCase();

    if (lower.contains('atilla') || lower.contains('karaoğlan')) {
      return RefereeStat(
        name: clean,
        matchesCount: 32,
        avgYellowCards: 5.4,
        avgRedCards: 0.31,
        avgFouls: 28.5,
        avgPenalties: 0.47,
        homeWinPercentage: 46.0,
        drawPercentage: 25.0,
        awayWinPercentage: 29.0,
      );
    }
    if (lower.contains('halil umut') || lower.contains('meler')) {
      return RefereeStat(
        name: clean,
        matchesCount: 38,
        avgYellowCards: 4.8,
        avgRedCards: 0.24,
        avgFouls: 25.0,
        avgPenalties: 0.38,
        homeWinPercentage: 48.0,
        drawPercentage: 26.0,
        awayWinPercentage: 26.0,
      );
    }
    if (lower.contains('ali şansalan')) {
      return RefereeStat(
        name: clean,
        matchesCount: 29,
        avgYellowCards: 5.1,
        avgRedCards: 0.28,
        avgFouls: 27.2,
        avgPenalties: 0.41,
        homeWinPercentage: 43.0,
        drawPercentage: 27.0,
        awayWinPercentage: 30.0,
      );
    }
    if (lower.contains('yasin kol')) {
      return RefereeStat(
        name: clean,
        matchesCount: 26,
        avgYellowCards: 4.3,
        avgRedCards: 0.18,
        avgFouls: 24.5,
        avgPenalties: 0.32,
        homeWinPercentage: 45.0,
        drawPercentage: 29.0,
        awayWinPercentage: 26.0,
      );
    }
    if (lower.contains('mehmet türkmen')) {
      return RefereeStat(
        name: clean,
        matchesCount: 22,
        avgYellowCards: 4.6,
        avgRedCards: 0.22,
        avgFouls: 26.0,
        avgPenalties: 0.36,
        homeWinPercentage: 44.0,
        drawPercentage: 28.0,
        awayWinPercentage: 28.0,
      );
    }
    if (lower.contains('michael oliver')) {
      return RefereeStat(
        name: clean,
        matchesCount: 35,
        avgYellowCards: 3.9,
        avgRedCards: 0.14,
        avgFouls: 21.0,
        avgPenalties: 0.34,
        homeWinPercentage: 47.0,
        drawPercentage: 24.0,
        awayWinPercentage: 29.0,
      );
    }
    if (lower.contains('sánchez martínez') || lower.contains('martinez')) {
      return RefereeStat(
        name: clean,
        matchesCount: 30,
        avgYellowCards: 5.6,
        avgRedCards: 0.33,
        avgFouls: 29.0,
        avgPenalties: 0.42,
        homeWinPercentage: 50.0,
        drawPercentage: 23.0,
        awayWinPercentage: 27.0,
      );
    }
    if (lower.contains('turgut') || lower.contains('doman')) {
      return RefereeStat(
        name: clean,
        matchesCount: 31,
        avgYellowCards: 4.7,
        avgRedCards: 0.22,
        avgFouls: 26.5,
        avgPenalties: 0.35,
        homeWinPercentage: 45.0,
        drawPercentage: 27.0,
        awayWinPercentage: 28.0,
      );
    }

    // Varsayılan lig ortalaması hakem profili
    return RefereeStat(name: clean.isEmpty ? 'Resmi Hakem' : clean);
  }
}
