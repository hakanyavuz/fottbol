import 'dart:math' as math;
import '../models/volleyball_match.dart';

/// Voleybol Bilimsel Tahmin Motoru (Set Dağılımı, Sayı Baremi ve Kadro Eksik Etkisi)
class VolleyballEngine {
  /// İki voleybol takımı arasındaki maçın tüm olasılıklarını hesaplar
  static VolleyballPrediction calculatePrediction({
    required VolleyballTeam homeTeam,
    required VolleyballTeam awayTeam,
    required DateTime matchDate,
    String? leagueName,
  }) {
    final league = leagueName ?? homeTeam.league;

    // 1. Takım Güç Katsayılarının Hesaplanması (Hücum + Blok + Servis + Manşet)
    double homePower = _calculateTeamPower(homeTeam, isHome: true);
    double awayPower = _calculateTeamPower(awayTeam, isHome: false);

    // 2. Eksik Oyuncu Cezası (Yıldız smaçör/pasör yoksa güç %12 düşer)
    if (homeTeam.hasKeyPlayerMissing) {
      homePower *= 0.88;
    }
    if (awayTeam.hasKeyPlayerMissing) {
      awayPower *= 0.88;
    }

    // 3. Tek bir seti kazanma olasılığı P (Sigmoid Fonksiyonu)
    final double powerDiff = homePower - awayPower;
    final double pHomeSet = 1.0 / (1.0 + math.exp(-powerDiff / 14.0));
    final double pAwaySet = 1.0 - pHomeSet;

    // 4. Negatif Binom / Set Kombinasyon Olasılıkları
    // 3-0: Ev sahibi 3 set ardışık kazanır
    double p30 = math.pow(pHomeSet, 3).toDouble();
    // 3-1: 4 set oynanır, ev sahibi son seti kazanarak 3-1 yapar (C(3,1) * P^3 * Q)
    double p31 = (3 * math.pow(pHomeSet, 3) * pAwaySet).toDouble();
    // 3-2: 5 set oynanır (C(4,2) * P^3 * Q^2)
    double p32 = (6 * math.pow(pHomeSet, 3) * math.pow(pAwaySet, 2)).toDouble();

    // 0-3: Deplasman 3 set ardışık kazanır
    double p03 = math.pow(pAwaySet, 3).toDouble();
    // 1-3: Deplasman 3-1 kazanır
    double p13 = (3 * math.pow(pAwaySet, 3) * pHomeSet).toDouble();
    // 2-3: Deplasman 3-2 kazanır
    double p23 = (6 * math.pow(pAwaySet, 3) * math.pow(pHomeSet, 2)).toDouble();

    // Toplamı 1.0'a normalize et
    final totalSum = p30 + p31 + p32 + p23 + p13 + p03;
    p30 /= totalSum;
    p31 /= totalSum;
    p32 /= totalSum;
    p23 /= totalSum;
    p13 /= totalSum;
    p03 /= totalSum;

    final homeWinProb = (p30 + p31 + p32) * 100.0;
    final awayWinProb = (p03 + p13 + p23) * 100.0;

    final setProbMap = {
      '3-0': (p30 * 1000).round() / 10,
      '3-1': (p31 * 1000).round() / 10,
      '3-2': (p32 * 1000).round() / 10,
      '2-3': (p23 * 1000).round() / 10,
      '1-3': (p13 * 1000).round() / 10,
      '0-3': (p03 * 1000).round() / 10,
    };

    // En olası set skoru
    String mostLikelyScore = '3-1';
    double maxProb = -1.0;
    setProbMap.forEach((score, prob) {
      if (prob > maxProb) {
        maxProb = prob;
        mostLikelyScore = score;
      }
    });

    // 5. Toplam Sayı Beklentisi
    // 3-0 / 0-3 maçları ortalama 138 sayı
    // 3-1 / 1-3 maçları ortalama 182 sayı
    // 3-2 / 2-3 maçları ortalama 212 sayı
    final expectedTotalPoints = (p30 + p03) * 138.0 +
        (p31 + p13) * 182.0 +
        (p32 + p23) * 212.0;

    const double defaultThreshold = 178.5;
    // 4 set veya 5 sete uzama olasılığı
    final over35Prob = ((p31 + p13 + p32 + p23) * 1000).round() / 10;
    final over45Prob = ((p32 + p23) * 1000).round() / 10;

    // Bareme göre Üst / Alt Olasılığı
    final double overProb = math.min(95.0, math.max(10.0, 50.0 + (expectedTotalPoints - defaultThreshold) * 2.2));
    final double underProb = 100.0 - overProb;

    // Güven Skoru
    final maxSpread = (homeWinProb - awayWinProb).abs();
    final confidenceScore = math.min(96.0, 55.0 + (maxSpread * 0.45));

    // Taktik Anlatım Özeti
    final tacticalSummary = _generateTacticalSummary(
      home: homeTeam,
      away: awayTeam,
      homeProb: homeWinProb,
      mostLikelyScore: mostLikelyScore,
      expectedPoints: expectedTotalPoints,
      over35: over35Prob,
    );

    return VolleyballPrediction(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchDate: matchDate,
      leagueName: league,
      homeWinProbability: (homeWinProb * 10).round() / 10,
      awayWinProbability: (awayWinProb * 10).round() / 10,
      setScoreProbabilities: setProbMap,
      mostLikelySetScore: mostLikelyScore,
      totalPointsThreshold: defaultThreshold,
      overProbability: (overProb * 10).round() / 10,
      underProbability: (underProb * 10).round() / 10,
      expectedTotalPoints: (expectedTotalPoints * 10).round() / 10,
      over35SetsProbability: over35Prob,
      over45SetsProbability: over45Prob,
      tacticalSummary: tacticalSummary,
      confidenceScore: (confidenceScore * 10).round() / 10,
    );
  }

  static double _calculateTeamPower(VolleyballTeam team, {required bool isHome}) {
    // Ağırlıklar: Hücum %40, Blok %25, Servis %15, Manşet %20
    double score = (team.attackEfficiency * 0.40) +
        (team.blockPerSet * 12.0 * 0.25) +
        (team.acePerSet * 15.0 * 0.15) +
        (team.receptionQuality * 0.20);

    // Seri ve moral çarpanı
    score += (team.recentWinStreak * 0.8);

    // Ev sahibi salon ve seyirci avantajı (+3.5 puan)
    if (isHome) {
      score += 3.5;
    }

    return score;
  }

  static String _generateTacticalSummary({
    required VolleyballTeam home,
    required VolleyballTeam away,
    required double homeProb,
    required String mostLikelyScore,
    required double expectedPoints,
    required double over35,
  }) {
    final leader = homeProb >= 50.0 ? home.name : away.name;
    final margin = (homeProb - (100.0 - homeProb)).abs();

    String balance;
    if (margin > 30.0) {
      balance = '$leader hücum yüzdesi ve blok üstünlüğüyle maçı forse edecektir.';
    } else if (over35 > 65.0) {
      balance = 'İki takımın da servis karşılama kalitesi denk görünüyor. Karşılaşmanın en az 4 sete uzaması (%$over35 ihtimal) beklenmektedir.';
    } else {
      balance = 'Çekişmeli bir mücadele bekleniyor. Blok ve köşe hücumları belirleyici olacaktır.';
    }

    return 'Voleybol set simülasyonuna göre en olası skor $mostLikelyScore. $balance Beklenen toplam sayı: ${expectedPoints.toStringAsFixed(0)}.';
  }
}
