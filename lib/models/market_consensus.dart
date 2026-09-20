import 'prediction_result.dart';

/// Dış tahmin kaynağının türü
enum BenchmarkSourceType {
  quantModel,        // FOTTBOL AI (Kendi Bağımsız Modelimiz)
  sharpMarket,       // Pinnacle / Betfair (Küresel Keskin Bahis Borsası)
  domesticMarket,    // Türkiye İddaa Bülteni (Yerel Piyasa Ortalama)
  externalAlgorithm, // Forebet, PredictZ, Windrawwin (Küresel Algoritma Konsensüsü)
  community,         // Sofascore, Transfermarkt vb. (Topluluk ve Halk Oyları)
}

/// Tek bir referans tahmin kaynağının sunduğu veriler
class BenchmarkPrediction {
  final String sourceName;
  final BenchmarkSourceType sourceType;
  final double homeProbability;
  final double drawProbability;
  final double awayProbability;
  final String? predictedScore;
  final double weight; // Konsensüs harmanındaki ağırlığı (örn: 0.40)
  final String? notes; // Kısa analiz notu

  const BenchmarkPrediction({
    required this.sourceName,
    required this.sourceType,
    required this.homeProbability,
    required this.drawProbability,
    required this.awayProbability,
    this.predictedScore,
    this.weight = 0.20,
    this.notes,
  });

  /// Bu kaynağın öne çıkardığı 1X2 tercihi
  MatchOutcome get favoriteOutcome {
    if (homeProbability >= drawProbability && homeProbability >= awayProbability) {
      return MatchOutcome.home;
    }
    if (awayProbability >= drawProbability) {
      return MatchOutcome.away;
    }
    return MatchOutcome.draw;
  }

  Map<String, dynamic> toJson() => {
    'sourceName': sourceName,
    'sourceType': sourceType.name,
    'homeProbability': homeProbability,
    'drawProbability': drawProbability,
    'awayProbability': awayProbability,
    'predictedScore': predictedScore,
    'weight': weight,
    'notes': notes,
  };

  factory BenchmarkPrediction.fromJson(Map<String, dynamic> json) => BenchmarkPrediction(
    sourceName: json['sourceName'] ?? 'Kaynak',
    sourceType: BenchmarkSourceType.values.firstWhere(
      (t) => t.name == json['sourceType'],
      orElse: () => BenchmarkSourceType.externalAlgorithm,
    ),
    homeProbability: (json['homeProbability'] as num?)?.toDouble() ?? 33.3,
    drawProbability: (json['drawProbability'] as num?)?.toDouble() ?? 33.3,
    awayProbability: (json['awayProbability'] as num?)?.toDouble() ?? 33.3,
    predictedScore: json['predictedScore'],
    weight: (json['weight'] as num?)?.toDouble() ?? 0.20,
    notes: json['notes'],
  );
}

/// Modeller ve piyasa arasındaki mutabakat / fikir birliği seviyesi
enum ConsensusAgreementStatus {
  strongConsensus, // 🟢 Güçlü Fikir Birliği (%80+ Mutabakat, Süper Banko)
  moderateConsensus, // 🟡 Ilımlı Mutabakat (%60-79 Fikir Birliği, Dengeli)
  divergence, // 🟠 Fikir Ayrılığı (Piyasa ve Yapay Zeka Çatışıyor)
  contrarianEdge, // 🔴 Ters Köşe / Gizli Değer (Piyasa Yanılıyor, FOTTBOL Değer Yakaladı)
}

/// Tüm küresel kaynakların kıyaslandığı ve hibrit sonucun üretildiği konsensüs nesnesi
class MarketConsensus {
  final List<BenchmarkPrediction> sources;
  final double consensusHomeProbability;
  final double consensusDrawProbability;
  final double consensusAwayProbability;
  final MatchOutcome consensusOutcome;
  final double agreementScore; // 0.0 - 100.0 arası uyum puanı
  final ConsensusAgreementStatus agreementStatus;
  final String statusSummary;
  
  // Ağırlıklı Harmanlanmış (Hibrit Ensemble) Nihai Olasılıklar
  final double blendedHomeProbability;
  final double blendedDrawProbability;
  final double blendedAwayProbability;
  final MatchOutcome blendedOutcome;
  final String blendedScoreString;
  final String? contrarianReason;

  const MarketConsensus({
    required this.sources,
    required this.consensusHomeProbability,
    required this.consensusDrawProbability,
    required this.consensusAwayProbability,
    required this.consensusOutcome,
    required this.agreementScore,
    required this.agreementStatus,
    required this.statusSummary,
    required this.blendedHomeProbability,
    required this.blendedDrawProbability,
    required this.blendedAwayProbability,
    required this.blendedOutcome,
    required this.blendedScoreString,
    this.contrarianReason,
  });

  Map<String, dynamic> toJson() => {
    'sources': sources.map((s) => s.toJson()).toList(),
    'consensusHomeProbability': consensusHomeProbability,
    'consensusDrawProbability': consensusDrawProbability,
    'consensusAwayProbability': consensusAwayProbability,
    'consensusOutcome': consensusOutcome.name,
    'agreementScore': agreementScore,
    'agreementStatus': agreementStatus.name,
    'statusSummary': statusSummary,
    'blendedHomeProbability': blendedHomeProbability,
    'blendedDrawProbability': blendedDrawProbability,
    'blendedAwayProbability': blendedAwayProbability,
    'blendedOutcome': blendedOutcome.name,
    'blendedScoreString': blendedScoreString,
    'contrarianReason': contrarianReason,
  };

  factory MarketConsensus.fromJson(Map<String, dynamic> json) => MarketConsensus(
    sources: (json['sources'] as List<dynamic>?)
            ?.map((e) => BenchmarkPrediction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
    consensusHomeProbability: (json['consensusHomeProbability'] as num?)?.toDouble() ?? 33.3,
    consensusDrawProbability: (json['consensusDrawProbability'] as num?)?.toDouble() ?? 33.3,
    consensusAwayProbability: (json['consensusAwayProbability'] as num?)?.toDouble() ?? 33.3,
    consensusOutcome: MatchOutcome.values.firstWhere(
      (o) => o.name == json['consensusOutcome'],
      orElse: () => MatchOutcome.home,
    ),
    agreementScore: (json['agreementScore'] as num?)?.toDouble() ?? 70.0,
    agreementStatus: ConsensusAgreementStatus.values.firstWhere(
      (s) => s.name == json['agreementStatus'],
      orElse: () => ConsensusAgreementStatus.moderateConsensus,
    ),
    statusSummary: json['statusSummary'] ?? 'Konsensüs değerlendirildi.',
    blendedHomeProbability: (json['blendedHomeProbability'] as num?)?.toDouble() ?? 33.3,
    blendedDrawProbability: (json['blendedDrawProbability'] as num?)?.toDouble() ?? 33.3,
    blendedAwayProbability: (json['blendedAwayProbability'] as num?)?.toDouble() ?? 33.3,
    blendedOutcome: MatchOutcome.values.firstWhere(
      (o) => o.name == json['blendedOutcome'],
      orElse: () => MatchOutcome.home,
    ),
    blendedScoreString: json['blendedScoreString'] ?? '1 - 1',
    contrarianReason: json['contrarianReason'],
  );
}
