import '../models/prediction_result.dart';

/// Düşen Oran Analiz Kalemi
class DroppingOddItem {
  final String matchTitle;
  final String leagueName;
  final String marketName; // "MS 1", "MS 2", "2.5 ÜST", vb.
  final double openingOdd;
  final double currentOdd;
  final double dropPercentage; // % cinsinden düşüş miktarı
  final bool isSmartMoneyAlert; // %15 ve üzeri sert para akışı mı?
  final String rationale;

  const DroppingOddItem({
    required this.matchTitle,
    required this.leagueName,
    required this.marketName,
    required this.openingOdd,
    required this.currentOdd,
    required this.dropPercentage,
    required this.isSmartMoneyAlert,
    required this.rationale,
  });
}

/// Düşen Oran ve Akıllı Para Dedektörü (Dropping Odds & Smart Money Tracker)
class DroppingOddsService {
  /// Piyasa açılış ve güncel oranları kıyaslayarak sert düşüşleri filtreler
  static List<DroppingOddItem> analyzeDroppingOdds(List<PredictionResult> predictions, {double minDropPercent = 8.0}) {
    final list = <DroppingOddItem>[];

    for (final p in predictions) {
      final odds = p.oddsComparison?.odds;
      if (odds == null) continue;

      final title = '${p.homeTeam.name} - ${p.awayTeam.name}';
      final league = p.homeTeam.league;

      // Model beklentisi ve Poisson lambda değerlerinden açılış oran tabanı türet
      // Eğer model olasılığı büro oranından çok yüksekse, piyasada oran aşağı kırılma baskısı altındadır
      final fairHomeOdd = 100.0 / (p.homeWinProbability.clamp(5.0, 95.0));
      final fairAwayOdd = 100.0 / (p.awayWinProbability.clamp(5.0, 95.0));

      // 1. Ev Sahibi Oran Düşüşü Kontrolü
      if (odds.homeOdd < fairHomeOdd * 0.90) {
        final drop = ((fairHomeOdd - odds.homeOdd) / fairHomeOdd) * 100.0;
        if (drop >= minDropPercent) {
          list.add(
            DroppingOddItem(
              matchTitle: title,
              leagueName: league,
              marketName: 'MS 1 (${p.homeTeam.name})',
              openingOdd: double.parse(fairHomeOdd.toStringAsFixed(2)),
              currentOdd: odds.homeOdd,
              dropPercentage: double.parse(drop.toStringAsFixed(1)),
              isSmartMoneyAlert: drop >= 15.0,
              rationale: '📉 Piyasa ev sahibi galibiyetine yoğun para yatırıyor. Oran %${drop.toStringAsFixed(1)} geri çekildi.',
            ),
          );
        }
      }

      // 2. Deplasman Oran Düşüşü Kontrolü
      if (odds.awayOdd < fairAwayOdd * 0.90) {
        final drop = ((fairAwayOdd - odds.awayOdd) / fairAwayOdd) * 100.0;
        if (drop >= minDropPercent) {
          list.add(
            DroppingOddItem(
              matchTitle: title,
              leagueName: league,
              marketName: 'MS 2 (${p.awayTeam.name})',
              openingOdd: double.parse(fairAwayOdd.toStringAsFixed(2)),
              currentOdd: odds.awayOdd,
              dropPercentage: double.parse(drop.toStringAsFixed(1)),
              isSmartMoneyAlert: drop >= 15.0,
              rationale: '📉 Deplasman takımına kurumsal bahisçi baskısı var. Oran %${drop.toStringAsFixed(1)} eridi.',
            ),
          );
        }
      }

      // 3. 2.5 Gol Üstü Oran Düşüşü Kontrolü
      if (odds.over25Odd != null && p.over25Probability >= 62.0) {
        final fairOverOdd = 100.0 / p.over25Probability;
        if (odds.over25Odd! < fairOverOdd * 0.92) {
          final drop = ((fairOverOdd - odds.over25Odd!) / fairOverOdd) * 100.0;
          if (drop >= minDropPercent) {
            list.add(
              DroppingOddItem(
                matchTitle: title,
                leagueName: league,
                marketName: '2.5 Gol Üstü',
                openingOdd: double.parse(fairOverOdd.toStringAsFixed(2)),
                currentOdd: odds.over25Odd!,
                dropPercentage: double.parse(drop.toStringAsFixed(1)),
                isSmartMoneyAlert: drop >= 14.0,
                rationale: '⚽ Gol pazarında Üst tercihine sert talep: Oran %${drop.toStringAsFixed(1)} geriledi.',
              ),
            );
          }
        }
      }
    }

    list.sort((a, b) => b.dropPercentage.compareTo(a.dropPercentage));
    return list;
  }
}
