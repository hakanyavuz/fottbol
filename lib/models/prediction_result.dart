import 'head_to_head.dart';
import 'team.dart';
import 'odds_comparison.dart';
import 'referee_stat.dart';
import 'market_consensus.dart';
import '../services/specialized_markets_engine.dart';

/// Olası skor ve ihtimali tutan yardımcı sınıf
class ScoreProbability {
  final int homeGoals;
  final int awayGoals;
  final double probability; // Yüzdelik (örn: 14.2)

  ScoreProbability({
    required this.homeGoals,
    required this.awayGoals,
    required this.probability,
  });

  String get scoreString => '$homeGoals - $awayGoals';

  Map<String, dynamic> toJson() => {
    'homeGoals': homeGoals,
    'awayGoals': awayGoals,
    'probability': probability,
  };

  factory ScoreProbability.fromJson(Map<String, dynamic> json) => ScoreProbability(
    homeGoals: json['homeGoals'] ?? 0,
    awayGoals: json['awayGoals'] ?? 0,
    probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Maç sonucu (1 / X / 2)
enum MatchOutcome {
  home('1'),
  draw('X'),
  away('2');

  const MatchOutcome(this.label);
  final String label;

  static MatchOutcome fromGoals(int homeGoals, int awayGoals) {
    if (homeGoals > awayGoals) return MatchOutcome.home;
    if (homeGoals < awayGoals) return MatchOutcome.away;
    return MatchOutcome.draw;
  }
}

/// Tahmin çıktısı ve detaylı analiz modeli
class PredictionResult {
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final int predictedHomeGoals;
  final int predictedAwayGoals;
  final double lambdaHome; // Ev Sahibi Beklenen Gol (xG)
  final double lambdaAway; // Deplasman Beklenen Gol (xG)

  // Maç Sonucu Olasılıkları (1 - X - 2)
  final double homeWinProbability; // Ev Galibiyeti %
  final double drawProbability;    // Beraberlik %
  final double awayWinProbability; // Deplasman Galibiyeti %

  // Ek Bahis/İstatistik Olasılıkları
  final double over25Probability; // 2.5 Üst %
  final double bothTeamsToScoreProbability; // Karşılıklı Gol Var (KG Var) %

  // En yüksek olasılıklı 3 skor sıralaması
  final List<ScoreProbability> topScores;

  // İstatistiksel algoritmanın ürettiği gerekçeler (Adım adım Türkçe açıklamalar)
  final List<String> mathematicalRationale;

  // Gemini AI tarafından üretilen doğal dilde uzman taktiksel analiz
  String? geminiTacticalAnalysis;

  // Alt liglerde oyuncu verisi eksikse fallback modu bayrağı
  final bool isSparseData;

  /// 0-5 gol aralığındaki tam skor olasılık matrisi (yüzde, normalize).
  /// `scoreMatrix[h][a]` = ev sahibi h, deplasman a gol. Eski kayıtlarda boştur.
  final List<List<double>> scoreMatrix;

  /// Kullanılan Dixon-Coles katsayısı (0 = saf Poisson)
  final double dixonColesRho;

  /// Aralarındaki maçların özeti (veri yoksa null)
  final HeadToHeadSummary? headToHead;

  final DateTime createdAt;

  // --- Gerçek maç bağlamı (fikstürden üretilen tahminlerde dolu) ---

  /// API-Football maç kimliği; sonucun sonradan çekilebilmesi için saklanır
  final int? fixtureId;

  /// Maçın oynanacağı tarih
  final DateTime? matchDate;

  // --- Maç oynandıktan sonra doldurulan gerçek sonuç ---
  int? actualHomeGoals;
  int? actualAwayGoals;
  String? fixtureStatus; // FT, PST, NS...
  DateTime? resultCheckedAt;

  /// Bahis oranları ve piyasa kıyaslaması (varsa)
  OddsComparison? oddsComparison;

  /// Küresel analiz programları ve bahis büroları konsensüs kıyaslaması
  MarketConsensus? consensus;

  /// Güven Skoru (0 - 100%)
  final double confidenceScore;

  /// Risk Seviyesi: "Banko", "Dengeli", "Sürpriz / Yüksek Risk"
  final String riskLevel;

  /// Dinlenme Günleri (Fikstür Sıklığı / Yorgunluk Analizi)
  final int? homeRestDays;
  final int? awayRestDays;

  /// Şut İsabet ve xG Verimlilik Oranı
  final double? homeShotEfficiency;
  final double? awayShotEfficiency;

  /// Maçın resmi hakemi ve yönetim istatistikleri
  final RefereeStat? refereeStat;

  /// Türkiye, İtalya, Fransa lig ve kupalarında şike / manipülasyon ve yüksek varyans koruma filtresi
  final bool isHighManipulationRisk;
  final String? manipulationRiskRegion;

  /// Club Elo Küresel Takım Güç Endeksi
  final double? homeElo;
  final double? awayElo;
  final double? eloDifference;

  /// Maç Önü veya Canlı Beklenen Gol (xG) Kalite Metriği
  final double? homeXg;
  final double? awayXg;

  /// Akıllı Çoklu Bahis Tercihleri
  final String primaryPick; // Örn: "MS 1 (Ev Sahibi)"
  final double primaryPickConfidence; // Örn: 74.5
  final String secondaryPick; // Örn: "2.5 Üst" veya "KG Var"
  final String safetyPick; // Örn: "1X Çifte Şans"
  final double expectedValue; // Model beklenti değeri EV
  final bool isValueBet; // EV > 1.05 ise true

  /// Özel Pazarlar: Kart ve Korner Tahminleri
  final CardCornerPrediction? cardCornerPrediction;

  /// Kabus Rakip (Bogey Team) ve Ters Eşleşme Analizi
  final BogeyAnalysis? bogeyAnalysis;

  PredictionResult({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.predictedHomeGoals,
    required this.predictedAwayGoals,
    required this.lambdaHome,
    required this.lambdaAway,
    required this.homeWinProbability,
    required this.drawProbability,
    required this.awayWinProbability,
    required this.over25Probability,
    required this.bothTeamsToScoreProbability,
    required this.topScores,
    required this.mathematicalRationale,
    this.geminiTacticalAnalysis,
    this.isSparseData = false,
    this.scoreMatrix = const [],
    this.dixonColesRho = 0,
    this.headToHead,
    this.confidenceScore = 70.0,
    this.riskLevel = 'Dengeli',
    this.homeRestDays,
    this.awayRestDays,
    this.homeShotEfficiency,
    this.awayShotEfficiency,
    this.refereeStat,
    this.fixtureId,
    this.matchDate,
    this.actualHomeGoals,
    this.actualAwayGoals,
    this.fixtureStatus,
    this.resultCheckedAt,
    this.oddsComparison,
    this.consensus,
    this.isHighManipulationRisk = false,
    this.manipulationRiskRegion,
    this.homeElo,
    this.awayElo,
    this.eloDifference,
    this.homeXg,
    this.awayXg,
    this.primaryPick = 'MS 1 (Ev Sahibi)',
    this.primaryPickConfidence = 65.0,
    this.secondaryPick = '2.5 Üst',
    this.safetyPick = '1X Çifte Şans',
    this.expectedValue = 1.0,
    this.isValueBet = false,
    this.cardCornerPrediction,
    this.bogeyAnalysis,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get predictedScoreString => '$predictedHomeGoals - $predictedAwayGoals';

  // ---------------------------------------------------------------------------
  // İsabet değerlendirmesi
  // ---------------------------------------------------------------------------

  /// Gerçek maç sonucu kaydedildi mi?
  bool get hasResult => actualHomeGoals != null && actualAwayGoals != null;

  /// Tahmin maç başlamadan önce mi yapıldı?
  /// Başladıktan sonra yapılan tahminler isabet karnesine dahil edilmez;
  /// aksi halde sonucu bilinen maçlar karneyi yapay olarak şişirir.
  bool get isPreMatch => matchDate == null || createdAt.isBefore(matchDate!);

  /// İsabet karnesine sayılabilir mi? (gerçek maça bağlı, maç öncesi yapılmış, sonucu belli)
  bool get isScorable => fixtureId != null && isPreMatch && hasResult;

  /// Sonucu beklenen (oynanmış ama henüz kontrol edilmemiş) bir maç mı?
  bool get isAwaitingResult =>
      !hasResult &&
      fixtureId != null &&
      matchDate != null &&
      isPreMatch &&
      matchDate!.isBefore(DateTime.now()) &&
      !const ['PST', 'CANC', 'ABD', 'AWD', 'WO'].contains(fixtureStatus);

  String get actualScoreString => hasResult ? '$actualHomeGoals - $actualAwayGoals' : '-';

  /// Modelin öne çıkardığı maç sonucu (en yüksek olasılıklı 1X2 seçeneği)
  MatchOutcome get predictedOutcome {
    if (homeWinProbability >= drawProbability && homeWinProbability >= awayWinProbability) {
      return MatchOutcome.home;
    }
    if (awayWinProbability >= drawProbability) return MatchOutcome.away;
    return MatchOutcome.draw;
  }

  MatchOutcome? get actualOutcome =>
      hasResult ? MatchOutcome.fromGoals(actualHomeGoals!, actualAwayGoals!) : null;

  /// Tahmin edilen skor birebir tuttu mu?
  bool? get isExactScoreHit => hasResult
      ? predictedHomeGoals == actualHomeGoals && predictedAwayGoals == actualAwayGoals
      : null;

  /// Maç sonucu (1X2) tuttu mu?
  bool? get isOutcomeHit => hasResult ? predictedOutcome == actualOutcome : null;

  /// 2.5 Üst/Alt tahmini tuttu mu?
  bool? get isOver25Hit {
    if (!hasResult) return null;
    final predictedOver = over25Probability >= 50;
    final actualOver = (actualHomeGoals! + actualAwayGoals!) > 2;
    return predictedOver == actualOver;
  }

  /// Karşılıklı gol tahmini tuttu mu?
  bool? get isBttsHit {
    if (!hasResult) return null;
    final predictedBtts = bothTeamsToScoreProbability >= 50;
    final actualBtts = actualHomeGoals! > 0 && actualAwayGoals! > 0;
    return predictedBtts == actualBtts;
  }

  /// İlk 3 tercih arasında gerçek skor var mıydı?
  bool? get isTop3ScoreHit {
    if (!hasResult) return null;
    return topScores.any((s) => s.homeGoals == actualHomeGoals && s.awayGoals == actualAwayGoals);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'homeTeam': homeTeam.toJson(),
    'awayTeam': awayTeam.toJson(),
    'predictedHomeGoals': predictedHomeGoals,
    'predictedAwayGoals': predictedAwayGoals,
    'lambdaHome': lambdaHome,
    'lambdaAway': lambdaAway,
    'homeWinProbability': homeWinProbability,
    'drawProbability': drawProbability,
    'awayWinProbability': awayWinProbability,
    'over25Probability': over25Probability,
    'bothTeamsToScoreProbability': bothTeamsToScoreProbability,
    'topScores': topScores.map((s) => s.toJson()).toList(),
    'mathematicalRationale': mathematicalRationale,
    'geminiTacticalAnalysis': geminiTacticalAnalysis,
    'isSparseData': isSparseData,
    'scoreMatrix': scoreMatrix,
    'dixonColesRho': dixonColesRho,
    'headToHead': headToHead?.toJson(),
    'confidenceScore': confidenceScore,
    'riskLevel': riskLevel,
    'homeRestDays': homeRestDays,
    'awayRestDays': awayRestDays,
    'homeShotEfficiency': homeShotEfficiency,
    'awayShotEfficiency': awayShotEfficiency,
    'refereeStat': refereeStat?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'fixtureId': fixtureId,
    'matchDate': matchDate?.toIso8601String(),
    'actualHomeGoals': actualHomeGoals,
    'actualAwayGoals': actualAwayGoals,
    'fixtureStatus': fixtureStatus,
    'resultCheckedAt': resultCheckedAt?.toIso8601String(),
    'oddsComparison': oddsComparison?.toJson(),
    'consensus': consensus?.toJson(),
    'isHighManipulationRisk': isHighManipulationRisk,
    'manipulationRiskRegion': manipulationRiskRegion,
    'homeElo': homeElo,
    'awayElo': awayElo,
    'eloDifference': eloDifference,
    'homeXg': homeXg,
    'awayXg': awayXg,
    'primaryPick': primaryPick,
    'primaryPickConfidence': primaryPickConfidence,
    'secondaryPick': secondaryPick,
    'safetyPick': safetyPick,
    'expectedValue': expectedValue,
    'isValueBet': isValueBet,
    'cardCornerPrediction': cardCornerPrediction?.toJson(),
    'bogeyAnalysis': bogeyAnalysis?.toJson(),
  };

  factory PredictionResult.fromJson(Map<String, dynamic> json) => PredictionResult(
    id: json['id'] ?? '',
    homeTeam: Team.fromJson(json['homeTeam'] ?? {}),
    awayTeam: Team.fromJson(json['awayTeam'] ?? {}),
    predictedHomeGoals: json['predictedHomeGoals'] ?? 0,
    predictedAwayGoals: json['predictedAwayGoals'] ?? 0,
    lambdaHome: (json['lambdaHome'] as num?)?.toDouble() ?? 1.0,
    lambdaAway: (json['lambdaAway'] as num?)?.toDouble() ?? 1.0,
    homeWinProbability: (json['homeWinProbability'] as num?)?.toDouble() ?? 33.3,
    drawProbability: (json['drawProbability'] as num?)?.toDouble() ?? 33.3,
    awayWinProbability: (json['awayWinProbability'] as num?)?.toDouble() ?? 33.3,
    over25Probability: (json['over25Probability'] as num?)?.toDouble() ?? 50.0,
    bothTeamsToScoreProbability:
        (json['bothTeamsToScoreProbability'] as num?)?.toDouble() ?? 50.0,
    topScores: (json['topScores'] as List? ?? [])
        .map((s) => ScoreProbability.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList(),
    mathematicalRationale: List<String>.from(json['mathematicalRationale'] ?? []),
    geminiTacticalAnalysis: json['geminiTacticalAnalysis'],
    isSparseData: json['isSparseData'] ?? false,
    scoreMatrix: (json['scoreMatrix'] as List? ?? [])
        .whereType<List>()
        .map((row) => row.map((v) => (v as num).toDouble()).toList())
        .toList(),
    dixonColesRho: (json['dixonColesRho'] as num?)?.toDouble() ?? 0,
    headToHead: json['headToHead'] is Map
        ? HeadToHeadSummary.fromJson(Map<String, dynamic>.from(json['headToHead'] as Map))
        : null,
    confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 70.0,
    riskLevel: json['riskLevel'] ?? 'Dengeli',
    homeRestDays: (json['homeRestDays'] as num?)?.toInt(),
    awayRestDays: (json['awayRestDays'] as num?)?.toInt(),
    homeShotEfficiency: (json['homeShotEfficiency'] as num?)?.toDouble(),
    awayShotEfficiency: (json['awayShotEfficiency'] as num?)?.toDouble(),
    refereeStat: json['refereeStat'] is Map
        ? RefereeStat.fromJson(Map<String, dynamic>.from(json['refereeStat'] as Map))
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    fixtureId: (json['fixtureId'] as num?)?.toInt(),
    matchDate: json['matchDate'] != null ? DateTime.tryParse(json['matchDate']) : null,
    actualHomeGoals: (json['actualHomeGoals'] as num?)?.toInt(),
    actualAwayGoals: (json['actualAwayGoals'] as num?)?.toInt(),
    fixtureStatus: json['fixtureStatus'],
    resultCheckedAt: json['resultCheckedAt'] != null
        ? DateTime.tryParse(json['resultCheckedAt'])
        : null,
    oddsComparison: json['oddsComparison'] is Map
        ? OddsComparison.fromJson(Map<String, dynamic>.from(json['oddsComparison'] as Map))
        : null,
    consensus: json['consensus'] is Map
        ? MarketConsensus.fromJson(Map<String, dynamic>.from(json['consensus'] as Map))
        : null,
    isHighManipulationRisk: json['isHighManipulationRisk'] ?? false,
    manipulationRiskRegion: json['manipulationRiskRegion'],
    homeElo: (json['homeElo'] as num?)?.toDouble(),
    awayElo: (json['awayElo'] as num?)?.toDouble(),
    eloDifference: (json['eloDifference'] as num?)?.toDouble(),
    homeXg: (json['homeXg'] as num?)?.toDouble(),
    awayXg: (json['awayXg'] as num?)?.toDouble(),
    primaryPick: json['primaryPick'] ?? 'MS 1 (Ev Sahibi)',
    primaryPickConfidence: (json['primaryPickConfidence'] as num?)?.toDouble() ?? 65.0,
    secondaryPick: json['secondaryPick'] ?? '2.5 Üst',
    safetyPick: json['safetyPick'] ?? '1X Çifte Şans',
    expectedValue: (json['expectedValue'] as num?)?.toDouble() ?? 1.0,
    isValueBet: json['isValueBet'] ?? false,
    cardCornerPrediction: json['cardCornerPrediction'] is Map
        ? CardCornerPrediction.fromJson(Map<String, dynamic>.from(json['cardCornerPrediction'] as Map))
        : null,
    bogeyAnalysis: json['bogeyAnalysis'] is Map
        ? BogeyAnalysis.fromJson(Map<String, dynamic>.from(json['bogeyAnalysis'] as Map))
        : null,
  );
}

/// Bir tahmin listesinin isabet karnesi
class PredictionAccuracy {
  final int settled; // Sonucu belli olan tahmin sayısı
  final int exactScoreHits;
  final int outcomeHits;
  final int top3ScoreHits;
  final int over25Hits;
  final int bttsHits;

  const PredictionAccuracy({
    required this.settled,
    required this.exactScoreHits,
    required this.outcomeHits,
    required this.top3ScoreHits,
    required this.over25Hits,
    required this.bttsHits,
  });

  bool get hasData => settled > 0;

  double _rate(int hits) => settled > 0 ? (hits / settled) * 100 : 0;

  double get exactScoreRate => _rate(exactScoreHits);
  double get outcomeRate => _rate(outcomeHits);
  double get top3ScoreRate => _rate(top3ScoreHits);
  double get over25Rate => _rate(over25Hits);
  double get bttsRate => _rate(bttsHits);

  /// Maç öncesi yapılmış ve sonucu belli olan tahminlerden karne üretir
  factory PredictionAccuracy.from(Iterable<PredictionResult> predictions) {
    final settledList = predictions.where((p) => p.isScorable).toList();

    int count(bool? Function(PredictionResult) test) =>
        settledList.where((p) => test(p) == true).length;

    return PredictionAccuracy(
      settled: settledList.length,
      exactScoreHits: count((p) => p.isExactScoreHit),
      outcomeHits: count((p) => p.isOutcomeHit),
      top3ScoreHits: count((p) => p.isTop3ScoreHit),
      over25Hits: count((p) => p.isOver25Hit),
      bttsHits: count((p) => p.isBttsHit),
    );
  }
}
