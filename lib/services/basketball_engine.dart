import 'dart:math' as math;
import '../models/basketball_match.dart';

/// Basketbol Bilimsel Tahmin Motoru (Pace, Hücum/Savunma Verimliliği ve Sayı Dağılımı)
class BasketballEngine {
  /// İki basketbol takımı arasındaki maçın tüm olasılıklarını hesaplar
  static BasketballPrediction calculatePrediction({
    required BasketballTeam homeTeam,
    required BasketballTeam awayTeam,
    required DateTime matchDate,
    String? leagueName,
  }) {
    final league = leagueName ?? homeTeam.league;

    // 1. Beklenen Hücum Temposu (Pozisyon Sayısı)
    final double expectedPace = (homeTeam.pace + awayTeam.pace) / 2.0;

    // 2. 100 Pozisyon Başına Hücum Güçleri (Offensive & Defensive Rating)
    double homeOvr = (homeTeam.offensiveRating + awayTeam.defensiveRating) / 2.0;
    double awayOvr = (awayTeam.offensiveRating + homeTeam.defensiveRating) / 2.0;

    // Ev Sahibi Saha Avantajı (+3.2 sayı 100 pozisyonda)
    homeOvr += 3.2;

    // 3. Dinlenme & Yorgunluk Etkisi (Back-to-back yorgunluğu)
    if (homeTeam.restDays <= 1) homeOvr -= 2.0;
    if (awayTeam.restDays <= 1) awayOvr -= 2.5;

    // 4. Eksik Oyuncu Etkisi (Yıldız oyuncu yoksa -5.5 sayı)
    if (homeTeam.hasKeyPlayerMissing) homeOvr -= 5.5;
    if (awayTeam.hasKeyPlayerMissing) awayOvr -= 5.5;

    // 5. Beklenen Skorlar
    final double homeScore = (homeOvr / 100.0) * expectedPace;
    final double awayScore = (awayOvr / 100.0) * expectedPace;
    final double totalScore = homeScore + awayScore;

    // 6. Sayı Farkı (Spread) ve Normal Dağılım ile Galibiyet Olasılığı
    final double spread = homeScore - awayScore;
    // Basketbolda sayı farkı standart sapması ~11.5 sayıdır
    final double zScore = spread / 11.5;
    final double homeWinProb = _cumulativeNormalDistribution(zScore) * 100.0;
    final double awayWinProb = 100.0 - homeWinProb;

    // 7. Toplam Sayı Baremi ve Üst/Alt Olasılığı
    final double roundedThreshold = (totalScore.roundToDouble()) + 0.5;
    final double overZ = (totalScore - roundedThreshold) / 12.0;
    final double overProb = _cumulativeNormalDistribution(overZ) * 100.0;
    final double underProb = 100.0 - overProb;

    // Önerilen Handikap
    final double handicap = -(spread.roundToDouble()) + 0.5;

    // Güven Skoru
    final confidence = math.min(95.0, math.max(50.0, 50.0 + spread.abs() * 2.2));

    // Taktik Anlatım Özeti
    final leader = spread >= 0 ? homeTeam.name : awayTeam.name;
    final tacticalSummary = '$leader tempo ve hücum verimliliğiyle öne çıkıyor. Beklenen maç skoru: ${homeScore.round()} - ${awayScore.round()} (Toplam: ${totalScore.round()} sayı).';

    return BasketballPrediction(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchDate: matchDate,
      leagueName: league,
      homeWinProbability: (homeWinProb * 10).round() / 10,
      awayWinProbability: (awayWinProb * 10).round() / 10,
      expectedHomeScore: (homeScore * 10).round() / 10,
      expectedAwayScore: (awayScore * 10).round() / 10,
      expectedTotalScore: (totalScore * 10).round() / 10,
      totalPointsThreshold: roundedThreshold,
      overProbability: (overProb * 10).round() / 10,
      underProbability: (underProb * 10).round() / 10,
      suggestedHandicap: handicap,
      tacticalSummary: tacticalSummary,
      confidenceScore: (confidence * 10).round() / 10,
    );
  }

  /// Standart Normal Kümülatif Dağılım Fonksiyonu Phi(z)
  static double _cumulativeNormalDistribution(double z) {
    return 0.5 * (1.0 + _erf(z / math.sqrt(2.0)));
  }

  /// Gauss Hata Fonksiyonu Yaklaşımı (Abramowitz & Stegun)
  static double _erf(double x) {
    final double sign = x < 0 ? -1.0 : 1.0;
    const double a1 = 0.254829592;
    const double a2 = -0.284496736;
    const double a3 = 1.421413741;
    const double a4 = -1.453152027;
    const double a5 = 1.061405429;
    const double p = 0.3275911;

    final double t = 1.0 / (1.0 + p * x.abs());
    final double y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }
}
