import 'prediction_result.dart';

/// Değerli Bahis (Value Bet) Modeli
///
/// Model olasılığı ile piyasa örtük olasılığı (1 / Oran) arasındaki pozitif marjı temsil eder.
class ValueBet {
  final String matchTitle;
  final String leagueName;
  final DateTime? matchDate;
  final String selectionLabel; // "Ev Sahibi Galibiyeti (1)", "2.5 Gol Üstü", vb.
  final double marketOdds; // Piyasa Oranı (örn: 2.10)
  final double modelProbability; // Model Tahmin Yüzdesi (örn: 58.5)
  final double impliedProbability; // 1 / Oran * 100 (örn: 47.6)
  final double edgePercentage; // Model % - İmplied % (örn: +10.9%)
  final String riskCategory; // "Banko", "Dengeli", "Sürpriz Değer"
  final PredictionResult prediction;

  const ValueBet({
    required this.matchTitle,
    required this.leagueName,
    this.matchDate,
    required this.selectionLabel,
    required this.marketOdds,
    required this.modelProbability,
    required this.impliedProbability,
    required this.edgePercentage,
    required this.riskCategory,
    required this.prediction,
  });

  /// Kelly Kriteri Formülü: f* = (b * p - q) / b
  /// b = (Oran - 1), p = model olasılığı, q = (1 - p)
  /// Spor quant yönetiminde 1/2 Kelly (Half-Kelly) güvenli kasa oranıdır.
  double get kellyStakePercentage {
    if (marketOdds <= 1.01) return 0.0;
    final b = marketOdds - 1.0;
    final p = modelProbability / 100.0;
    final q = 1.0 - p;
    final fullKelly = (b * p - q) / b;
    if (fullKelly <= 0) return 0.0;
    // 1/2 Kelly (güvenli risk), %0.5 ile %5.0 arasında sınırlandırılır
    double halfKelly = (fullKelly * 0.5) * 100.0;

    // Şike/manipülasyon riski olan liglerde (Türkiye, İtalya, Fransa) %30 kasa koruma indirimi (maks %2.5)
    if (prediction.isHighManipulationRisk) {
      halfKelly *= 0.70;
      return halfKelly.clamp(0.5, 2.5);
    }

    return halfKelly.clamp(0.5, 5.0);
  }

  /// Bir tahmin sonucundan piyasa oranlarını kıyaslayarak potansiyel Value Bet'leri çıkarır
  static List<ValueBet> findValueBets(PredictionResult p, {double minEdge = 4.0}) {
    final odds = p.oddsComparison;
    if (odds == null) return const [];

    final list = <ValueBet>[];
    final matchName = '${p.homeTeam.name} - ${p.awayTeam.name}';
    final league = p.homeTeam.league;

    void evaluate({
      required String label,
      required double modelProb,
      required double oddsValue,
    }) {
      if (oddsValue <= 1.01) return;
      final implied = (1.0 / oddsValue) * 100.0;
      final edge = modelProb - implied;

      if (edge >= minEdge) {
        String risk = 'Dengeli';
        if (modelProb >= 65.0) {
          risk = 'Banko Değer';
        } else if (oddsValue >= 2.40) {
          risk = 'Sürpriz / Yüksek Oran';
        }

        list.add(
          ValueBet(
            matchTitle: matchName,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: label,
            marketOdds: oddsValue,
            modelProbability: modelProb,
            impliedProbability: implied,
            edgePercentage: edge,
            riskCategory: risk,
            prediction: p,
          ),
        );
      }
    }

    // 1X2 Piyasa Kıyaslaması
    evaluate(
      label: '${p.homeTeam.name} Galibiyeti (1)',
      modelProb: p.homeWinProbability,
      oddsValue: odds.odds.homeOdd,
    );
    evaluate(
      label: 'Beraberlik (X)',
      modelProb: p.drawProbability,
      oddsValue: odds.odds.drawOdd,
    );
    evaluate(
      label: '${p.awayTeam.name} Galibiyeti (2)',
      modelProb: p.awayWinProbability,
      oddsValue: odds.odds.awayOdd,
    );

    // Kenar avantajına (Edge) göre en karlıdan en aza sırala
    list.sort((a, b) => b.edgePercentage.compareTo(a.edgePercentage));
    return list;
  }
}
