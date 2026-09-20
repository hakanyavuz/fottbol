import 'prediction_result.dart';

/// Büronun sunduğu 1X2 oranları
class BookmakerOdds {
  final String bookmakerName;
  final double homeOdd;
  final double drawOdd;
  final double awayOdd;
  final DateTime? updatedAt;

  const BookmakerOdds({
    required this.bookmakerName,
    required this.homeOdd,
    required this.drawOdd,
    required this.awayOdd,
    this.updatedAt,
  });

  /// Büronun kâr marjı (Overround / Vig)
  /// Örn: 1/2.10 + 1/3.40 + 1/3.50 = 0.476 + 0.294 + 0.286 = 1.056 (%105.6)
  double get overround => (1.0 / homeOdd) + (1.0 / drawOdd) + (1.0 / awayOdd);

  /// Overround yüzdesi (örn: 5.6)
  double get marginPercent => (overround - 1.0) * 100;

  /// Marjdan arındırılmış saf piyasa olasılığı - Ev Sahibi %
  double get marketHomeProbability => ((1.0 / homeOdd) / overround) * 100;

  /// Marjdan arındırılmış saf piyasa olasılığı - Beraberlik %
  double get marketDrawProbability => ((1.0 / drawOdd) / overround) * 100;

  /// Marjdan arındırılmış saf piyasa olasılığı - Deplasman %
  double get marketAwayProbability => ((1.0 / awayOdd) / overround) * 100;

  Map<String, dynamic> toJson() => {
    'bookmakerName': bookmakerName,
    'homeOdd': homeOdd,
    'drawOdd': drawOdd,
    'awayOdd': awayOdd,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory BookmakerOdds.fromJson(Map<String, dynamic> json) => BookmakerOdds(
    bookmakerName: json['bookmakerName'] ?? 'Piyasa',
    homeOdd: (json['homeOdd'] as num?)?.toDouble() ?? 2.0,
    drawOdd: (json['drawOdd'] as num?)?.toDouble() ?? 3.2,
    awayOdd: (json['awayOdd'] as num?)?.toDouble() ?? 3.5,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
  );
}

/// Değerli tercih (Value Bet) seçeneği
class ValueBetChoice {
  final MatchOutcome outcome;
  final double odd;
  final double modelProbability;
  final double marketProbability;
  final double probabilityDiff; // Model - Piyasa (yüzde puanı)
  final double expectedValue;   // EV = (P_model * Odd) - 1 (örn: +0.12 -> +%12)

  const ValueBetChoice({
    required this.outcome,
    required this.odd,
    required this.modelProbability,
    required this.marketProbability,
    required this.probabilityDiff,
    required this.expectedValue,
  });

  bool get isValue => probabilityDiff >= 4.0 || expectedValue >= 0.05;

  String get outcomeLabel {
    switch (outcome) {
      case MatchOutcome.home:
        return '1 (Ev Sahibi)';
      case MatchOutcome.draw:
        return 'X (Beraberlik)';
      case MatchOutcome.away:
        return '2 (Deplasman)';
    }
  }

  Map<String, dynamic> toJson() => {
    'outcome': outcome.name,
    'odd': odd,
    'modelProbability': modelProbability,
    'marketProbability': marketProbability,
    'probabilityDiff': probabilityDiff,
    'expectedValue': expectedValue,
  };

  factory ValueBetChoice.fromJson(Map<String, dynamic> json) => ValueBetChoice(
    outcome: MatchOutcome.values.firstWhere(
      (o) => o.name == json['outcome'],
      orElse: () => MatchOutcome.home,
    ),
    odd: (json['odd'] as num?)?.toDouble() ?? 1.0,
    modelProbability: (json['modelProbability'] as num?)?.toDouble() ?? 0.0,
    marketProbability: (json['marketProbability'] as num?)?.toDouble() ?? 0.0,
    probabilityDiff: (json['probabilityDiff'] as num?)?.toDouble() ?? 0.0,
    expectedValue: (json['expectedValue'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Model tahminleri ile bahis bürosu oranlarının karşılaştırması
class OddsComparison {
  final BookmakerOdds odds;
  final ValueBetChoice homeChoice;
  final ValueBetChoice drawChoice;
  final ValueBetChoice awayChoice;

  const OddsComparison({
    required this.odds,
    required this.homeChoice,
    required this.drawChoice,
    required this.awayChoice,
  });

  /// Model ve büro oranlarından karşılaştırma üretir
  factory OddsComparison.fromModelAndOdds({
    required BookmakerOdds odds,
    required double modelHomeProb,
    required double modelDrawProb,
    required double modelAwayProb,
  }) {
    ValueBetChoice buildChoice({
      required MatchOutcome outcome,
      required double odd,
      required double modelP,
      required double marketP,
    }) {
      final diff = modelP - marketP;
      final ev = (modelP / 100.0) * odd - 1.0;
      return ValueBetChoice(
        outcome: outcome,
        odd: odd,
        modelProbability: (modelP * 10).round() / 10,
        marketProbability: (marketP * 10).round() / 10,
        probabilityDiff: (diff * 10).round() / 10,
        expectedValue: (ev * 1000).round() / 1000,
      );
    }

    return OddsComparison(
      odds: odds,
      homeChoice: buildChoice(
        outcome: MatchOutcome.home,
        odd: odds.homeOdd,
        modelP: modelHomeProb,
        marketP: odds.marketHomeProbability,
      ),
      drawChoice: buildChoice(
        outcome: MatchOutcome.draw,
        odd: odds.drawOdd,
        modelP: modelDrawProb,
        marketP: odds.marketDrawProbability,
      ),
      awayChoice: buildChoice(
        outcome: MatchOutcome.away,
        odd: odds.awayOdd,
        modelP: modelAwayProb,
        marketP: odds.marketAwayProbability,
      ),
    );
  }

  List<ValueBetChoice> get allChoices => [homeChoice, drawChoice, awayChoice];

  /// En yüksek beklenen değere (EV) sahip seçenek
  ValueBetChoice get bestChoice {
    final list = [...allChoices]..sort((a, b) => b.expectedValue.compareTo(a.expectedValue));
    return list.first;
  }

  /// Modelin piyasaya göre belirgin avantaj gördüğü seçenekler
  List<ValueBetChoice> get valueBets => allChoices.where((c) => c.isValue).toList();

  bool get hasValueBet => valueBets.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'odds': odds.toJson(),
    'homeChoice': homeChoice.toJson(),
    'drawChoice': drawChoice.toJson(),
    'awayChoice': awayChoice.toJson(),
  };

  factory OddsComparison.fromJson(Map<String, dynamic> json) => OddsComparison(
    odds: BookmakerOdds.fromJson(Map<String, dynamic>.from(json['odds'] ?? {})),
    homeChoice: ValueBetChoice.fromJson(Map<String, dynamic>.from(json['homeChoice'] ?? {})),
    drawChoice: ValueBetChoice.fromJson(Map<String, dynamic>.from(json['drawChoice'] ?? {})),
    awayChoice: ValueBetChoice.fromJson(Map<String, dynamic>.from(json['awayChoice'] ?? {})),
  );
}
