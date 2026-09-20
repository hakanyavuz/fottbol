import 'dart:math' as math;
import '../core/utils/math_utils.dart';

class InPlayAnalysis {
  final double homeWinProb;
  final double drawProb;
  final double awayWinProb;
  final String momentum; // "Ev Sahibi Baskılı", "Dengeli", "Deplasman Tehlikeli"
  final String? cardRationale;
  final double lambdaHomeRem;
  final double lambdaAwayRem;

  InPlayAnalysis({
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
    required this.momentum,
    this.cardRationale,
    this.lambdaHomeRem = 0.0,
    this.lambdaAwayRem = 0.0,
  });
}

class InPlayEngine {
  /// Canlı maç verilerine, kırmızı/sarı kart durumuna ve kadro eksiklerine göre
  /// anlık Poisson olasılıklarını hesaplar.
  static InPlayAnalysis calculateLiveProbabilities({
    required int currentHomeGoals,
    required int currentAwayGoals,
    required int elapsedMinutes,
    required double preMatchLambdaHome,
    required double preMatchLambdaAway,
    int homeRedCards = 0,
    int awayRedCards = 0,
    int homeYellowCards = 0,
    int awayYellowCards = 0,
    int missingKeyStartersHome = 0,
    int missingKeyStartersAway = 0,
    String homeTeamName = 'Ev Sahibi',
    String awayTeamName = 'Deplasman',
  }) {
    // 1. Kalan süreyi hesapla (Maksimum 95 dk kabul edelim)
    int remainingMinutes = math.max(0, 90 - elapsedMinutes);
    if (remainingMinutes == 0 && elapsedMinutes < 90) remainingMinutes = 5; // Uzatmalar için pay

    // 2. Kırmızı Kart ve Eksik Oyuncu Çarpanları
    double homeMultiplier = 1.0;
    double awayMultiplier = 1.0;
    final List<String> impactNotes = [];

    if (homeRedCards == 1) {
      homeMultiplier *= 0.65; // 10 kişi kalan takımın gol beklentisi -%35 düşer
      awayMultiplier *= 1.25; // Sayısal üstünlükteki rakip takımın gol beklentisi +%25 artar
      impactNotes.add('🟥 $homeTeamName 10 kişi (-%35 hücum, $awayTeamName +%25 avantaj)');
    } else if (homeRedCards >= 2) {
      homeMultiplier *= 0.40;
      awayMultiplier *= 1.50;
      impactNotes.add('🟥 $homeTeamName $homeRedCards kırmızı kart (-%60 hücum, rakip +%50)');
    }

    if (awayRedCards == 1) {
      awayMultiplier *= 0.65;
      homeMultiplier *= 1.25;
      impactNotes.add('🟥 $awayTeamName 10 kişi (-%35 hücum, $homeTeamName +%25 avantaj)');
    } else if (awayRedCards >= 2) {
      awayMultiplier *= 0.40;
      homeMultiplier *= 1.50;
      impactNotes.add('🟥 $awayTeamName $awayRedCards kırmızı kart (-%60 hücum, rakip +%50)');
    }

    if (homeYellowCards >= 3) {
      homeMultiplier *= 0.96; // Kart sınırında ve temkinli savunma
    }
    if (awayYellowCards >= 3) {
      awayMultiplier *= 0.96;
    }

    if (missingKeyStartersHome > 0) {
      final pen = (missingKeyStartersHome * 0.12).clamp(0.05, 0.25);
      homeMultiplier *= (1.0 - pen);
      impactNotes.add('🏥 $homeTeamName $missingKeyStartersHome kilit eksik (-%${(pen * 100).toStringAsFixed(0)})');
    }
    if (missingKeyStartersAway > 0) {
      final pen = (missingKeyStartersAway * 0.12).clamp(0.05, 0.25);
      awayMultiplier *= (1.0 - pen);
      impactNotes.add('🏥 $awayTeamName $missingKeyStartersAway kilit eksik (-%${(pen * 100).toStringAsFixed(0)})');
    }

    // 3. Kalan süre için yeni lambda (gol beklentisi) hesapla
    double lambdaHomeRem = preMatchLambdaHome * (remainingMinutes / 90.0) * homeMultiplier;
    double lambdaAwayRem = preMatchLambdaAway * (remainingMinutes / 90.0) * awayMultiplier;

    // 4. Kalan sürede atılacak gollerin dağılımını hesapla (6x6 Poisson matrisi)
    double homeWinRem = 0, drawRem = 0, awayWinRem = 0;
    double totalProb = 0;

    for (int h = 0; h <= 5; h++) {
      for (int a = 0; a <= 5; a++) {
        double p = MathUtils.poissonProbability(h, lambdaHomeRem) * 
                   MathUtils.poissonProbability(a, lambdaAwayRem);
        
        int finalHome = currentHomeGoals + h;
        int finalAway = currentAwayGoals + a;

        if (finalHome > finalAway) {
          homeWinRem += p;
        } else if (finalHome == finalAway) {
          drawRem += p;
        } else {
          awayWinRem += p;
        }

        totalProb += p;
      }
    }

    // Normalizasyon
    if (totalProb > 0) {
      homeWinRem = (homeWinRem / totalProb) * 100;
      drawRem = (drawRem / totalProb) * 100;
      awayWinRem = (awayWinRem / totalProb) * 100;
    }

    // Momentum analizi
    String momentum = "Dengeli Oyun";
    if (homeRedCards > awayRedCards) {
      momentum = "⚡ $awayTeamName Sayısal Üstünlükle Baskıda";
    } else if (awayRedCards > homeRedCards) {
      momentum = "⚡ $homeTeamName Sayısal Üstünlükle Baskıda";
    } else if (lambdaHomeRem > lambdaAwayRem * 1.35) {
      momentum = "$homeTeamName Baskısı";
    } else if (lambdaAwayRem > lambdaHomeRem * 1.35) {
      momentum = "$awayTeamName Tehlikeli";
    }

    return InPlayAnalysis(
      homeWinProb: homeWinRem,
      drawProb: drawRem,
      awayWinProb: awayWinRem,
      momentum: momentum,
      cardRationale: impactNotes.isNotEmpty ? impactNotes.join(' • ') : null,
      lambdaHomeRem: lambdaHomeRem,
      lambdaAwayRem: lambdaAwayRem,
    );
  }
}
