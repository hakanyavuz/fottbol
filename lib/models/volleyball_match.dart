/// Voleybol Takım Modeli
class VolleyballTeam {
  final int id;
  final String name;
  final String logo;
  final String league;
  final double attackEfficiency; // % (örn 48.5)
  final double blockPerSet; // set başına blok (örn 2.8)
  final double acePerSet; // set başına servis sayısı (örn 1.6)
  final double receptionQuality; // % mükemmel manşet (örn 52.0)
  final int recentWinStreak; // son maç galibiyet serisi
  final bool hasKeyPlayerMissing; // yıldız smaçör/pasör eksik mi?
  final String venue;

  const VolleyballTeam({
    required this.id,
    required this.name,
    required this.logo,
    required this.league,
    this.attackEfficiency = 45.0,
    this.blockPerSet = 2.2,
    this.acePerSet = 1.2,
    this.receptionQuality = 50.0,
    this.recentWinStreak = 2,
    this.hasKeyPlayerMissing = false,
    this.venue = 'Spor Salonu',
  });
}

/// Voleybol Tahmin Sonucu Modeli
class VolleyballPrediction {
  final VolleyballTeam homeTeam;
  final VolleyballTeam awayTeam;
  final DateTime matchDate;
  final String leagueName;

  // Maç Sonu Galibiyet Olasılıkları
  final double homeWinProbability; // %
  final double awayWinProbability; // %

  // En Olası Set Skoru Dağılımı
  final Map<String, double> setScoreProbabilities; // "3-0": 32%, "3-1": 28%, "3-2": 14% ...
  final String mostLikelySetScore; // Örn "3-1"

  // Toplam Sayı Baremi
  final double totalPointsThreshold; // Örn 178.5
  final double overProbability; // %
  final double underProbability; // %
  final double expectedTotalPoints; // Örn 182.4

  // Set Baremi
  final double over35SetsProbability; // % (En az 4 set oynanır mı?)
  final double over45SetsProbability; // % (5. sete (tie-break) uzar mı?)

  // Taktik Analiz ve Değerlendirme
  final String tacticalSummary;
  final double confidenceScore;

  const VolleyballPrediction({
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.leagueName,
    required this.homeWinProbability,
    required this.awayWinProbability,
    required this.setScoreProbabilities,
    required this.mostLikelySetScore,
    required this.totalPointsThreshold,
    required this.overProbability,
    required this.underProbability,
    required this.expectedTotalPoints,
    required this.over35SetsProbability,
    required this.over45SetsProbability,
    required this.tacticalSummary,
    required this.confidenceScore,
  });
}
