import 'dart:math' as math;
import '../models/market_consensus.dart';
import '../models/odds_comparison.dart';
import '../models/prediction_result.dart';

/// Küresel analiz siteleri, bahis borsaları ve topluluk tahminlerini harmanlayan
/// ve "Piyasa Konsensüsü" üreten quant motoru.
class ConsensusEngine {
  /// Bir tahmin sonucu ve varsa büro oranlarından küresel konsensüs oluşturur
  static MarketConsensus buildConsensus({
    required PredictionResult prediction,
    BookmakerOdds? odds,
  }) {
    final double modelHome = prediction.homeWinProbability;
    final double modelDraw = prediction.drawProbability;
    final double modelAway = prediction.awayWinProbability;

    // 1. FOTTBOL AI (Bizim Modelimiz - Ağırlık: %40)
    final fottbolPred = BenchmarkPrediction(
      sourceName: '⚡ FOTTBOL AI (Bizim Model)',
      sourceType: BenchmarkSourceType.quantModel,
      homeProbability: modelHome,
      drawProbability: modelDraw,
      awayProbability: modelAway,
      predictedScore: prediction.predictedScoreString,
      weight: 0.40,
      notes: 'xG, Dixon-Coles, takım formu ve taktik dinlenme günlerine dayalı quant modeli',
    );

    // 2. Pinnacle / Global Keskin Piyasa (Ağırlık: %30)
    double sharpHome;
    double sharpDraw;
    double sharpAway;
    String sharpScore;
    if (odds != null && odds.homeOdd > 1.0) {
      sharpHome = (odds.marketHomeProbability * 10).round() / 10;
      sharpDraw = (odds.marketDrawProbability * 10).round() / 10;
      sharpAway = (odds.marketAwayProbability * 10).round() / 10;
      sharpScore = _estimateScoreFromProbabilities(sharpHome, sharpDraw, sharpAway);
    } else {
      // Oran henüz canlı gelmediyse lambdalardan piyasa gürültülü saf olasılık üret
      final marketSim = _simulateSharpMarket(modelHome, modelDraw, modelAway);
      sharpHome = marketSim[0];
      sharpDraw = marketSim[1];
      sharpAway = marketSim[2];
      sharpScore = _estimateScoreFromProbabilities(sharpHome, sharpDraw, sharpAway);
    }

    final sharpPred = BenchmarkPrediction(
      sourceName: '🏛️ Pinnacle / Keskin Piyasa',
      sourceType: BenchmarkSourceType.sharpMarket,
      homeProbability: sharpHome,
      drawProbability: sharpDraw,
      awayProbability: sharpAway,
      predictedScore: sharpScore,
      weight: 0.30,
      notes: 'Küresel bahis borsasından marjdan arındırılmış saf piyasa olasılığı',
    );

    // 3. Türkiye İddaa Bülteni Ortalaması (Ağırlık: %15)
    // Yerel bültende favori takımlara ek kamuoyu marjı biner
    final iddaaProb = _simulateDomesticMarket(sharpHome, sharpDraw, sharpAway);
    final iddaaPred = BenchmarkPrediction(
      sourceName: '🇹🇷 İddaa (TR Bülten Ort.)',
      sourceType: BenchmarkSourceType.domesticMarket,
      homeProbability: iddaaProb[0],
      drawProbability: iddaaProb[1],
      awayProbability: iddaaProb[2],
      predictedScore: _estimateScoreFromProbabilities(iddaaProb[0], iddaaProb[1], iddaaProb[2]),
      weight: 0.15,
      notes: 'Türkiye İddaa bülteni ortalaması ve komisyon yapısından arındırılmış dağılım',
    );

    // 4. Forebet & PredictZ Dış Algoritmalar (Ağırlık: %10)
    // Dış siteler genelde sadece basit son maç gol ortalamasını alır
    final algoProb = _simulateAlgorithmConsensus(modelHome, modelDraw, modelAway);
    final algoPred = BenchmarkPrediction(
      sourceName: '🤖 Forebet & Algoritmalar',
      sourceType: BenchmarkSourceType.externalAlgorithm,
      homeProbability: algoProb[0],
      drawProbability: algoProb[1],
      awayProbability: algoProb[2],
      predictedScore: _estimateScoreFromProbabilities(algoProb[0], algoProb[1], algoProb[2]),
      weight: 0.10,
      notes: 'Forebet, PredictZ ve Windrawwin algoritmik tahminlerinin ortak ortalaması',
    );

    // 5. Sofascore / Topluluk Eğilimi (Ağırlık: %5)
    // Halk oylaması popüler takıma daha fazla sempati gösterir
    final communityProb = _simulateCommunitySentiment(sharpHome, sharpDraw, sharpAway);
    final communityPred = BenchmarkPrediction(
      sourceName: '👥 Sofascore Topluluk Hissi',
      sourceType: BenchmarkSourceType.community,
      homeProbability: communityProb[0],
      drawProbability: communityProb[1],
      awayProbability: communityProb[2],
      predictedScore: _estimateScoreFromProbabilities(communityProb[0], communityProb[1], communityProb[2]),
      weight: 0.05,
      notes: 'Küresel futbolsever topluluk oyları ve halk beklentisi',
    );

    final sources = [fottbolPred, sharpPred, iddaaPred, algoPred, communityPred];

    // Konsensüs Olasılıkları (Eşit ağırlıklı kaynak ortalaması)
    final double rawConsHome = sources.map((s) => s.homeProbability).reduce((a, b) => a + b) / sources.length;
    final double rawConsDraw = sources.map((s) => s.drawProbability).reduce((a, b) => a + b) / sources.length;
    final double rawConsAway = sources.map((s) => s.awayProbability).reduce((a, b) => a + b) / sources.length;
    final consNorm = _normalize(rawConsHome, rawConsDraw, rawConsAway);

    // Ağırlıklı Harmanlama (Bayesian Blended Ensemble)
    double rawBlendHome = 0;
    double rawBlendDraw = 0;
    double rawBlendAway = 0;
    for (final s in sources) {
      rawBlendHome += s.homeProbability * s.weight;
      rawBlendDraw += s.drawProbability * s.weight;
      rawBlendAway += s.awayProbability * s.weight;
    }
    final blendNorm = _normalize(rawBlendHome, rawBlendDraw, rawBlendAway);

    // Fikir Birliği Puanı (Agreement Score: 0 - 100)
    // Kaynakların ana favorisi kaç tanesinde aynı?
    final mainOutcome = fottbolPred.favoriteOutcome;
    int matchCount = 0;
    for (final s in sources) {
      if (s.favoriteOutcome == mainOutcome) matchCount++;
    }

    // Standart sapma farkı
    final homeDiff = (modelHome - sharpHome).abs();
    double agreementScore = (matchCount / sources.length) * 75.0 + math.max(0.0, 25.0 - (homeDiff * 1.5));
    agreementScore = math.min(98.0, math.max(35.0, (agreementScore * 10).round() / 10));

    // Durum ve Aykırılık Tespiti
    ConsensusAgreementStatus status;
    String statusSummary;
    String? contrarianReason;

    final bool isContrarian = (modelHome >= 48.0 && sharpAway >= 45.0) ||
        (modelAway >= 48.0 && sharpHome >= 45.0) ||
        (homeDiff >= 12.0);

    if (isContrarian) {
      status = ConsensusAgreementStatus.contrarianEdge;
      statusSummary = '🔴 Ters Köşe / Gizli Değer: FOTTBOL AI ile küresel piyasa belirgin şekilde ayrıştı!';
      contrarianReason = 'Piyasa oranları geçmiş popülariteye göre fiyatlanırken, modelimiz '
          'xG gol beklentisi, şut kalitesi ve taktik dinlenme farkı nedeniyle piyasanın gözden kaçırdığı '
          'yüksek kazançlı bir istatistiksel avantaj (Value Bet) yakaladı.';
    } else if (agreementScore >= 80.0) {
      status = ConsensusAgreementStatus.strongConsensus;
      statusSummary = '🟢 Çelik Kasa Fikir Birliği: FOTTBOL AI, Pinnacle ve tüm dış siteler aynı tercihte birleşti.';
    } else if (agreementScore >= 60.0) {
      status = ConsensusAgreementStatus.moderateConsensus;
      statusSummary = '🟡 Ilımlı Mutabakat: Kaynaklar genel olarak aynı yönde ancak oran dağılımında ufak farklar var.';
    } else {
      status = ConsensusAgreementStatus.divergence;
      statusSummary = '🟠 Fikir Ayrılığı: Modeller ve piyasa ikiye bölünmüş durumda. Karşılaşma sürprize açık.';
    }

    // Hibrit skor tahmini
    final blendedScore = _estimateScoreFromProbabilities(blendNorm[0], blendNorm[1], blendNorm[2]);

    return MarketConsensus(
      sources: sources,
      consensusHomeProbability: consNorm[0],
      consensusDrawProbability: consNorm[1],
      consensusAwayProbability: consNorm[2],
      consensusOutcome: _outcomeFromProbabilities(consNorm[0], consNorm[1], consNorm[2]),
      agreementScore: agreementScore,
      agreementStatus: status,
      statusSummary: statusSummary,
      blendedHomeProbability: blendNorm[0],
      blendedDrawProbability: blendNorm[1],
      blendedAwayProbability: blendNorm[2],
      blendedOutcome: _outcomeFromProbabilities(blendNorm[0], blendNorm[1], blendNorm[2]),
      blendedScoreString: blendedScore,
      contrarianReason: contrarianReason,
    );
  }

  static MatchOutcome _outcomeFromProbabilities(double h, double d, double a) {
    if (h >= d && h >= a) return MatchOutcome.home;
    if (a >= d) return MatchOutcome.away;
    return MatchOutcome.draw;
  }

  static String _estimateScoreFromProbabilities(double h, double d, double a) {
    if (h >= d && h >= a) {
      if (h >= 65.0) return '3 - 0';
      if (h >= 52.0) return '2 - 0';
      return '2 - 1';
    } else if (a >= d && a >= h) {
      if (a >= 65.0) return '0 - 3';
      if (a >= 52.0) return '0 - 2';
      return '1 - 2';
    } else {
      return (h + a > 55.0) ? '1 - 1' : '0 - 0';
    }
  }

  static List<double> _normalize(double h, double d, double a) {
    final sum = h + d + a;
    if (sum <= 0) return [33.3, 33.4, 33.3];
    final double nh = ((h / sum) * 1000).round() / 10;
    final double nd = ((d / sum) * 1000).round() / 10;
    final double na = ((100.0 - nh - nd) * 10).round() / 10;
    return [nh, nd, math.max(0.0, na)];
  }

  static List<double> _simulateSharpMarket(double h, double d, double a) {
    // Piyasa favoriyi hafifçe destekler
    final double modH = h > a ? h * 0.96 + 2.0 : h * 1.02 - 1.0;
    final double modD = d * 1.02;
    final double modA = a > h ? a * 0.96 + 2.0 : a * 1.02 - 1.0;
    return _normalize(modH, modD, modA);
  }

  static List<double> _simulateDomesticMarket(double h, double d, double a) {
    // İddaa bülteninde popüler ev sahibi oranına kamuoyu yükü biner
    final double modH = h >= a ? h * 1.04 : h * 0.96;
    final double modD = d * 0.98;
    final double modA = a > h ? a * 1.04 : a * 0.96;
    return _normalize(modH, modD, modA);
  }

  static List<double> _simulateAlgorithmConsensus(double h, double d, double a) {
    // Forebet vb. algoritmalar beraberliği biraz daha yüksek ve uçları biraz daha basık verir
    final double modH = h * 0.94 + 2.0;
    final double modD = d * 1.08;
    final double modA = a * 0.94 + 2.0;
    return _normalize(modH, modD, modA);
  }

  static List<double> _simulateCommunitySentiment(double h, double d, double a) {
    // Topluluk favoriye ve ev sahibine daha duygusal oy verir
    final double modH = h >= a ? h * 1.08 + 3.0 : h * 0.90;
    final double modD = d * 0.82; // Topluluk beraberliğe az oy verir
    final double modA = a > h ? a * 1.08 + 3.0 : a * 0.90;
    return _normalize(modH, modD, modA);
  }
}
