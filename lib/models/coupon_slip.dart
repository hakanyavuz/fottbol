import 'dart:math' as math;
import 'prediction_result.dart';
import 'volleyball_match.dart';
import 'basketball_match.dart';

/// Kupondaki tek bir maç tercihi
class CouponItem {
  final String matchTitle;
  final String leagueName;
  final DateTime? matchDate;
  final String selectionLabel; // Örn: "Galatasaray Galibiyeti (1)"
  final double odds; // Örn: 1.45
  final double confidenceScore;
  final String riskCategory;
  final PredictionResult? prediction;
  final String sportEmoji;
  final bool? forcedIsWon;

  /// Tahmin sonucuna göre bu tercihin tutup tutmadığını kontrol eder
  bool? get isWon {
    if (forcedIsWon != null) return forcedIsWon;
    if (prediction == null || !prediction!.hasResult) return null;
    
    final h = prediction!.actualHomeGoals!;
    final a = prediction!.actualAwayGoals!;
    final label = selectionLabel.toLowerCase();

    if (label.contains('ms 1') || (label.contains('kazanır') && label.contains(prediction!.homeTeam.name.toLowerCase()))) {
      return h > a;
    }
    if (label.contains('ms 2') || (label.contains('kazanır') && label.contains(prediction!.awayTeam.name.toLowerCase()))) {
      return a > h;
    }
    if (label.contains('ms x') || label.contains('beraberlik')) {
      return h == a;
    }
    if (label.contains('2.5 gol üstü')) {
      return (h + a) > 2.5;
    }
    if (label.contains('karşılıklı gol var') || label.contains('kg')) {
      return h > 0 && a > 0;
    }
    
    return null;
  }

  const CouponItem({
    required this.matchTitle,
    required this.leagueName,
    this.matchDate,
    required this.selectionLabel,
    required this.odds,
    required this.confidenceScore,
    required this.riskCategory,
    this.prediction,
    this.sportEmoji = '⚽',
    this.forcedIsWon,
  });

  Map<String, dynamic> toJson() => {
    'matchTitle': matchTitle,
    'leagueName': leagueName,
    'matchDate': matchDate?.toIso8601String(),
    'selectionLabel': selectionLabel,
    'odds': odds,
    'confidenceScore': confidenceScore,
    'riskCategory': riskCategory,
    'sportEmoji': sportEmoji,
    'isWon': isWon,
    'prediction': prediction?.toJson(),
  };

  factory CouponItem.fromJson(Map<String, dynamic> json) => CouponItem(
    matchTitle: json['matchTitle'] ?? '',
    leagueName: json['leagueName'] ?? '',
    matchDate: json['matchDate'] != null ? DateTime.tryParse(json['matchDate']) : null,
    selectionLabel: json['selectionLabel'] ?? '',
    odds: (json['odds'] as num?)?.toDouble() ?? 1.0,
    confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 50.0,
    riskCategory: json['riskCategory'] ?? 'İdeal',
    sportEmoji: json['sportEmoji'] ?? '⚽',
    forcedIsWon: json['isWon'] as bool?,
    prediction: json['prediction'] != null ? PredictionResult.fromJson(json['prediction']) : null,
  );
}

/// Akıllı Kupon Modeli (Banko, İdeal, Sürpriz)
class CouponSlip {
  final String id;
  final DateTime date;
  final String title;
  final String category; // "Banko (Düşük Risk)", "İdeal Denge", "Sürpriz / Yüksek Kazanç"
  final List<CouponItem> items;
  final double totalOdds;
  final double combinedConfidenceScore;
  final String? aiAnalysis;

  /// Kuponun genel durumu: 'winning', 'lost', 'pending', 'partial'
  String get status {
    if (items.any((it) => it.isWon == false)) return 'lost';
    if (items.isNotEmpty && items.every((it) => it.isWon == true)) return 'winning';
    if (items.any((it) => it.isWon == true)) return 'partial';
    return 'pending';
  }

  /// Gerçek Çarpımsal Bileşik Başarı İhtimali (%): P1 * P2 * ... * Pn
  double get jointProbabilityPercentage {
    if (items.isEmpty) return 0.0;
    double joint = 1.0;
    for (final it in items) {
      final p = (it.confidenceScore / 100.0).clamp(0.05, 0.98);
      joint *= p;
    }
    return (joint * 100.0);
  }

  /// Beklenen Matematiksel Değer (Expected Value / EV): (JointProb * TotalOdds - 1) * 100
  double get expectedValuePercentage {
    if (items.isEmpty || totalOdds <= 1.0) return 0.0;
    final jointProb = jointProbabilityPercentage / 100.0;
    return ((jointProb * totalOdds) - 1.0) * 100.0;
  }

  /// Kupon için Kelly Kasa Yönetimi Önerisi (%): (p * b - q) / b
  /// Çoklu kombinede varyans koruması için 1/4 Kelly (Quarter-Kelly) uygulanır.
  double get kellyStakeRecommendation {
    if (items.isEmpty || totalOdds <= 1.01) return 0.0;
    final p = jointProbabilityPercentage / 100.0;
    final b = totalOdds - 1.0;
    final q = 1.0 - p;
    final fullKelly = (b * p - q) / b;
    if (fullKelly <= 0) return 0.5;
    final quarterKelly = (fullKelly * 0.25) * 100.0;
    return quarterKelly.clamp(0.5, 3.0);
  }

  CouponSlip({
    String? id,
    DateTime? date,
    required this.title,
    required this.category,
    required this.items,
    required this.totalOdds,
    required this.combinedConfidenceScore,
    this.aiAnalysis,
  })  : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
        date = date ?? DateTime.now();

  /// CopyWith metodu (AI analizi sonradan eklemek için)
  CouponSlip copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? category,
    List<CouponItem>? items,
    double? totalOdds,
    double? combinedConfidenceScore,
    String? aiAnalysis,
  }) {
    return CouponSlip(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      category: category ?? this.category,
      items: items ?? this.items,
      totalOdds: totalOdds ?? this.totalOdds,
      combinedConfidenceScore: combinedConfidenceScore ?? this.combinedConfidenceScore,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'category': category,
    'totalOdds': totalOdds,
    'combinedConfidenceScore': combinedConfidenceScore,
    'aiAnalysis': aiAnalysis,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory CouponSlip.fromJson(Map<String, dynamic> json) => CouponSlip(
    id: json['id']?.toString(),
    date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    title: json['title'] ?? 'Akıllı Kupon',
    category: json['category'] ?? 'İdeal',
    totalOdds: (json['totalOdds'] as num?)?.toDouble() ?? 1.0,
    combinedConfidenceScore: (json['combinedConfidenceScore'] as num?)?.toDouble() ?? 50.0,
    aiAnalysis: json['aiAnalysis'] as String?,
    items: (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => CouponItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  /// Bir tahmin havuzundan otomatik kuponlar oluşturur
  static List<CouponSlip> generateSlips(List<PredictionResult> predictions) {
    if (predictions.isEmpty) return const [];

    final bankoItems = <CouponItem>[];
    final idealItems = <CouponItem>[];
    final surprizItems = <CouponItem>[];

    for (final p in predictions) {
      final odds = p.oddsComparison?.odds;
      final hOdds = odds?.homeOdd ?? 1.50;
      final dOdds = odds?.drawOdd ?? 3.40;
      final aOdds = odds?.awayOdd ?? 2.80;

      final matchTitle = '${p.homeTeam.name} - ${p.awayTeam.name}';
      final league = p.homeTeam.league;

      // 1. Banko Tercih Analizi (Güven Skoru >= 75%)
      if (p.confidenceScore >= 74.0) {
        if (p.homeWinProbability >= 58.0) {
          bankoItems.add(
            CouponItem(
              matchTitle: matchTitle,
              leagueName: league,
              matchDate: p.matchDate,
              selectionLabel: '${p.homeTeam.name} Kazanır (MS 1)',
              odds: hOdds,
              confidenceScore: p.confidenceScore,
              riskCategory: 'Banko',
              prediction: p,
            ),
          );
        } else if (p.awayWinProbability >= 55.0) {
          bankoItems.add(
            CouponItem(
              matchTitle: matchTitle,
              leagueName: league,
              matchDate: p.matchDate,
              selectionLabel: '${p.awayTeam.name} Kazanır (MS 2)',
              odds: aOdds,
              confidenceScore: p.confidenceScore,
              riskCategory: 'Banko',
              prediction: p,
            ),
          );
        }
      }

      // 2. İdeal Denge (Gol ve KG Seçenekleri)
      if (p.over25Probability >= 62.0) {
        idealItems.add(
          CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: '2.5 Gol Üstü',
            odds: odds?.over25Odd ?? 1.65,
            confidenceScore: p.over25Probability,
            riskCategory: 'İdeal',
            prediction: p,
          ),
        );
      } else if (p.bothTeamsToScoreProbability >= 60.0) {
        idealItems.add(
          CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: 'Karşılıklı Gol Var (KG)',
            odds: 1.70,
            confidenceScore: p.bothTeamsToScoreProbability,
            riskCategory: 'İdeal',
            prediction: p,
          ),
        );
      }

      // 3. Sürpriz / Değerli Tercihler
      if (p.drawProbability >= 30.0 && dOdds >= 3.10) {
        surprizItems.add(
          CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: 'Beraberlik (MS X)',
            odds: dOdds,
            confidenceScore: p.drawProbability,
            riskCategory: 'Sürpriz',
            prediction: p,
          ),
        );
      }
    }

    final slips = <CouponSlip>[];

    // Banko Kupon
    if (bankoItems.isNotEmpty) {
      final selected = bankoItems.take(3).toList();
      double totalO = 1.0;
      double totalC = 0.0;
      for (final it in selected) {
        totalO *= it.odds;
        totalC += it.confidenceScore;
      }
      slips.add(
        CouponSlip(
          title: 'Günün Güvenilir Banko Kuponu',
          category: 'Banko (Düşük Risk)',
          items: selected,
          totalOdds: (totalO * 100).round() / 100,
          combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
        ),
      );
    }

    // İdeal Denge Kuponu
    if (idealItems.isNotEmpty) {
      final selected = idealItems.take(3).toList();
      double totalO = 1.0;
      double totalC = 0.0;
      for (final it in selected) {
        totalO *= it.odds;
        totalC += it.confidenceScore;
      }
      slips.add(
        CouponSlip(
          title: 'Günün Dengeli Gol Kuponu',
          category: 'İdeal Denge (Orta Risk)',
          items: selected,
          totalOdds: (totalO * 100).round() / 100,
          combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
        ),
      );
    }

    // Sürpriz / Yüksek Oran Kuponu
    if (surprizItems.isNotEmpty) {
      final selected = surprizItems.take(2).toList();
      double totalO = 1.0;
      double totalC = 0.0;
      for (final it in selected) {
        totalO *= it.odds;
        totalC += it.confidenceScore;
      }
      slips.add(
        CouponSlip(
          title: 'Günün Yüksek Oran Değer Kuponu',
          category: 'Sürpriz (Yüksek Oran)',
          items: selected,
          totalOdds: (totalO * 100).round() / 100,
          combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
        ),
      );
    }

    // Eğer hiçbir kupon kategorisine tam oturmadıysa ama o gün maçlar varsa:
    // O günün en yüksek olasılıklı maçlarından bir Günün Seçimleri kuponu oluştur
    if (slips.isEmpty && predictions.isNotEmpty) {
      final fallbackItems = <CouponItem>[];
      for (final p in predictions) {
        final odds = p.oddsComparison?.odds;
        final hOdds = odds?.homeOdd ?? 1.60;
        final aOdds = odds?.awayOdd ?? 2.40;
        final dOdds = odds?.drawOdd ?? 3.20;
        final matchTitle = '${p.homeTeam.name} - ${p.awayTeam.name}';
        final league = p.homeTeam.league;

        if (p.homeWinProbability >= p.awayWinProbability && p.homeWinProbability >= p.drawProbability) {
          fallbackItems.add(CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: '${p.homeTeam.name} Kazanır (MS 1)',
            odds: hOdds,
            confidenceScore: p.homeWinProbability,
            riskCategory: 'Günün Seçimi',
            prediction: p,
          ));
        } else if (p.awayWinProbability >= p.homeWinProbability && p.awayWinProbability >= p.drawProbability) {
          fallbackItems.add(CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: '${p.awayTeam.name} Kazanır (MS 2)',
            odds: aOdds,
            confidenceScore: p.awayWinProbability,
            riskCategory: 'Günün Seçimi',
            prediction: p,
          ));
        } else {
          fallbackItems.add(CouponItem(
            matchTitle: matchTitle,
            leagueName: league,
            matchDate: p.matchDate,
            selectionLabel: 'Beraberlik (MS X)',
            odds: dOdds,
            confidenceScore: p.drawProbability,
            riskCategory: 'Günün Seçimi',
            prediction: p,
          ));
        }
      }
      fallbackItems.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
      final selected = fallbackItems.take(3).toList();
      double totalO = 1.0;
      double totalC = 0.0;
      for (final it in selected) {
        totalO *= it.odds;
        totalC += it.confidenceScore;
      }
      slips.add(
        CouponSlip(
          title: 'Günün Maç Tercihleri Kuponu',
          category: 'Günün Seçimleri',
          items: selected,
          totalOdds: (totalO * 100).round() / 100,
          combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
        ),
      );
    }

    return slips;
  }

  /// Voleybol maçları için akıllı kuponlar üretir
  static List<CouponSlip> generateVolleyballSlips(List<VolleyballPrediction> predictions) {
    if (predictions.isEmpty) return const [];

    final items = <CouponItem>[];
    for (final p in predictions) {
      final matchTitle = '${p.homeTeam.name} - ${p.awayTeam.name}';
      if (p.homeWinProbability >= 62.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '${p.homeTeam.name} Galibiyeti',
          odds: (100.0 / p.homeWinProbability * 0.90 * 100).round() / 100,
          confidenceScore: p.homeWinProbability,
          riskCategory: 'Banko',
          sportEmoji: '🏐',
        ));
      } else if (p.awayWinProbability >= 62.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '${p.awayTeam.name} Galibiyeti',
          odds: (100.0 / p.awayWinProbability * 0.90 * 100).round() / 100,
          confidenceScore: p.awayWinProbability,
          riskCategory: 'Banko',
          sportEmoji: '🏐',
        ));
      }

      if (p.over35SetsProbability >= 65.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '3.5 Set Üstü (En az 4 set)',
          odds: 1.45,
          confidenceScore: p.over35SetsProbability,
          riskCategory: 'İdeal',
          sportEmoji: '🏐',
        ));
      }
    }

    if (items.isEmpty) {
      for (final p in predictions) {
        final winner = p.homeWinProbability >= p.awayWinProbability ? p.homeTeam.name : p.awayTeam.name;
        final prob = math.max(p.homeWinProbability, p.awayWinProbability);
        items.add(CouponItem(
          matchTitle: '${p.homeTeam.name} - ${p.awayTeam.name}',
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '$winner (Set: ${p.mostLikelySetScore})',
          odds: 1.55,
          confidenceScore: prob,
          riskCategory: 'Günün Seçimi',
          sportEmoji: '🏐',
        ));
      }
    }

    items.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    final selected = items.take(3).toList();
    if (selected.isEmpty) return const [];

    double totalO = 1.0;
    double totalC = 0.0;
    for (final it in selected) {
      totalO *= it.odds;
      totalC += it.confidenceScore;
    }

    return [
      CouponSlip(
        title: '🏐 Günün Voleybol Kuponu',
        category: 'Voleybol Seçimleri',
        items: selected,
        totalOdds: (totalO * 100).round() / 100,
        combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
      ),
    ];
  }

  /// Basketbol maçları için akıllı kuponlar üretir
  static List<CouponSlip> generateBasketballSlips(List<BasketballPrediction> predictions) {
    if (predictions.isEmpty) return const [];

    final items = <CouponItem>[];
    for (final p in predictions) {
      final matchTitle = '${p.homeTeam.name} - ${p.awayTeam.name}';
      if (p.homeWinProbability >= 60.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '${p.homeTeam.name} Kazanır (Handikap: ${p.suggestedHandicap})',
          odds: 1.65,
          confidenceScore: p.homeWinProbability,
          riskCategory: 'Banko',
          sportEmoji: '🏀',
        ));
      } else if (p.awayWinProbability >= 60.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '${p.awayTeam.name} Kazanır',
          odds: 1.75,
          confidenceScore: p.awayWinProbability,
          riskCategory: 'Banko',
          sportEmoji: '🏀',
        ));
      }

      if (p.overProbability >= 60.0) {
        items.add(CouponItem(
          matchTitle: matchTitle,
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '${p.totalPointsThreshold} Sayı Üstü',
          odds: 1.70,
          confidenceScore: p.overProbability,
          riskCategory: 'İdeal',
          sportEmoji: '🏀',
        ));
      }
    }

    if (items.isEmpty) {
      for (final p in predictions) {
        final winner = p.homeWinProbability >= p.awayWinProbability ? p.homeTeam.name : p.awayTeam.name;
        items.add(CouponItem(
          matchTitle: '${p.homeTeam.name} - ${p.awayTeam.name}',
          leagueName: p.leagueName,
          matchDate: p.matchDate,
          selectionLabel: '$winner Maç Galibi',
          odds: 1.60,
          confidenceScore: math.max(p.homeWinProbability, p.awayWinProbability),
          riskCategory: 'Günün Seçimi',
          sportEmoji: '🏀',
        ));
      }
    }

    items.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    final selected = items.take(3).toList();
    if (selected.isEmpty) return const [];

    double totalO = 1.0;
    double totalC = 0.0;
    for (final it in selected) {
      totalO *= it.odds;
      totalC += it.confidenceScore;
    }

    return [
      CouponSlip(
        title: '🏀 Günün Basketbol Kuponu',
        category: 'Basketbol Seçimleri',
        items: selected,
        totalOdds: (totalO * 100).round() / 100,
        combinedConfidenceScore: (totalC / selected.length * 10).round() / 10,
      ),
    ];
  }
}
