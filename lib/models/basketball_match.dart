/// Basketbol Takım Modeli
class BasketballTeam {
  final int id;
  final String name;
  final String logo;
  final String league;
  final double pace; // Hücum temposu (pozisyon sayısı, örn EuroLeague 71.5, NBA 99.0)
  final double offensiveRating; // 100 pozisyon başına atılan sayı (örn 114.5)
  final double defensiveRating; // 100 pozisyon başına yenilen sayı (örn 108.2)
  final double threePointPercentage; // 3 sayı yüzdesi (örn 37.5)
  final int restDays; // dinlenme gün sayısı
  final bool hasKeyPlayerMissing; // yıldız oyun kurucu / pivot eksik mi?
  final String venue;

  const BasketballTeam({
    required this.id,
    required this.name,
    required this.logo,
    required this.league,
    this.pace = 72.0,
    this.offensiveRating = 112.0,
    this.defensiveRating = 110.0,
    this.threePointPercentage = 36.0,
    this.restDays = 3,
    this.hasKeyPlayerMissing = false,
    this.venue = 'Basketbol Salonu',
  });
}

/// Basketbol Tahmin Sonucu Modeli
class BasketballPrediction {
  final BasketballTeam homeTeam;
  final BasketballTeam awayTeam;
  final DateTime matchDate;
  final String leagueName;

  final double homeWinProbability; // %
  final double awayWinProbability; // %

  final double expectedHomeScore;
  final double expectedAwayScore;
  final double expectedTotalScore;

  final double totalPointsThreshold; // Örn 163.5
  final double overProbability; // %
  final double underProbability; // %

  final double suggestedHandicap; // Örn -4.5
  final String tacticalSummary;
  final double confidenceScore;

  const BasketballPrediction({
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.leagueName,
    required this.homeWinProbability,
    required this.awayWinProbability,
    required this.expectedHomeScore,
    required this.expectedAwayScore,
    required this.expectedTotalScore,
    required this.totalPointsThreshold,
    required this.overProbability,
    required this.underProbability,
    required this.suggestedHandicap,
    required this.tacticalSummary,
    required this.confidenceScore,
  });
}
