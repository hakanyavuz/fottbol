import 'dart:math' as math;
import '../core/constants/league_constants.dart';
import '../core/utils/math_utils.dart';
import '../models/prediction_result.dart';

/// Kalibrasyon sonuç özeti modeli
class CalibrationResult {
  final int settledCount;
  final int h2hMatchesCount;
  final double calibratedRho;
  final double defaultRho;
  final double calibratedH2hWeight;
  final double defaultH2hWeight;
  final bool isDataCalibrated;
  final double rhoLogLikelihoodGain;
  final double h2hMseReductionPercent;

  const CalibrationResult({
    required this.settledCount,
    required this.h2hMatchesCount,
    required this.calibratedRho,
    required this.defaultRho,
    required this.calibratedH2hWeight,
    required this.defaultH2hWeight,
    required this.isDataCalibrated,
    this.rhoLogLikelihoodGain = 0.0,
    this.h2hMseReductionPercent = 0.0,
  });

  factory CalibrationResult.uncalibrated() => const CalibrationResult(
        settledCount: 0,
        h2hMatchesCount: 0,
        calibratedRho: LeagueConstants.dixonColesRho,
        defaultRho: LeagueConstants.dixonColesRho,
        calibratedH2hWeight: LeagueConstants.maxHeadToHeadWeight,
        defaultH2hWeight: LeagueConstants.maxHeadToHeadWeight,
        isDataCalibrated: false,
      );

  String get summaryText {
    if (!isDataCalibrated) {
      return 'Yeterli sonuçlanmış maç verisi olmadığından model literatür varsayımlarıyla (ρ: $defaultRho, H2H: %${(defaultH2hWeight * 100).toInt()}) çalışıyor.';
    }
    return '$settledCount maçlık gerçek sonuç verisinden kalibre edildi: ρ = ${calibratedRho.toStringAsFixed(2)}, H2H Ağırlığı = %${(calibratedH2hWeight * 100).toStringAsFixed(0)}.';
  }
}

class _CalibratedParam {
  final double value;
  final double logLikelihoodGain;

  const _CalibratedParam({required this.value, required this.logLikelihoodGain});
}

class _CalibratedH2hParam {
  final double value;
  final int sampleCount;
  final double mseReductionPercent;

  const _CalibratedH2hParam({
    required this.value,
    required this.sampleCount,
    required this.mseReductionPercent,
  });
}

/// Gerçek sonuçlanmış maçlardan Dixon-Coles ρ ve H2H ağırlıklarını optimize eden kalibratör
class ModelCalibrator {
  static const double defaultRho = LeagueConstants.dixonColesRho;
  static const double defaultH2hWeight = LeagueConstants.maxHeadToHeadWeight;

  /// Geçmiş tahmin listesinden veri odaklı kalibrasyonu hesaplar
  static CalibrationResult calibrate(List<PredictionResult> predictions) {
    final scorable = predictions.where((p) => p.isScorable).toList();
    if (scorable.isEmpty) {
      return CalibrationResult.uncalibrated();
    }

    final rhoResult = _calibrateRho(scorable);
    final h2hResult = _calibrateH2hWeight(scorable);

    return CalibrationResult(
      settledCount: scorable.length,
      h2hMatchesCount: h2hResult.sampleCount,
      calibratedRho: rhoResult.value,
      defaultRho: defaultRho,
      calibratedH2hWeight: h2hResult.value,
      defaultH2hWeight: defaultH2hWeight,
      isDataCalibrated: scorable.length >= 5,
      rhoLogLikelihoodGain: rhoResult.logLikelihoodGain,
      h2hMseReductionPercent: h2hResult.mseReductionPercent,
    );
  }

  /// Gerçek maç sonuçları üzerinden Dixon-Coles ρ değerini MLE ile hesaplar
  static _CalibratedParam _calibrateRho(List<PredictionResult> matches) {
    if (matches.length < 3) {
      return const _CalibratedParam(value: defaultRho, logLikelihoodGain: 0);
    }

    double bestRho = defaultRho;
    double maxLL = double.negativeInfinity;
    final double baselineLL = _calculateLogLikelihood(matches, 0.0);

    for (double testRho = -0.28; testRho <= 0.001; testRho += 0.005) {
      final ll = _calculateLogLikelihood(matches, testRho);
      if (ll > maxLL) {
        maxLL = ll;
        bestRho = testRho;
      }
    }

    // Bayesyen büzülme (Prior: defaultRho, ağırlık 10 maç)
    const double priorWeight = 10.0;
    final double blendedRho =
        (priorWeight * defaultRho + matches.length * bestRho) / (priorWeight + matches.length);

    final gain = maxLL - baselineLL;
    return _CalibratedParam(
      value: (blendedRho * 100).round() / 100,
      logLikelihoodGain: gain > 0 ? gain : 0,
    );
  }

  static double _calculateLogLikelihood(List<PredictionResult> matches, double rho) {
    double totalLL = 0.0;
    for (final m in matches) {
      final h = m.actualHomeGoals!;
      final a = m.actualAwayGoals!;
      final lh = m.lambdaHome;
      final la = m.lambdaAway;

      final tau = MathUtils.dixonColesTau(h, a, lh, la, MathUtils.clampRho(rho, lh, la));
      if (tau > 0) {
        totalLL += math.log(tau);
      } else {
        totalLL -= 100.0;
      }
    }
    return totalLL;
  }

  /// H2H ağırlığını MSE minimizasyonu ile optimize eder
  static _CalibratedH2hParam _calibrateH2hWeight(List<PredictionResult> matches) {
    final withH2h = matches.where((m) => m.headToHead != null && m.headToHead!.hasData).toList();
    if (withH2h.length < 3) {
      return _CalibratedH2hParam(
        value: defaultH2hWeight,
        sampleCount: withH2h.length,
        mseReductionPercent: 0,
      );
    }

    double bestW = defaultH2hWeight;
    double minMse = double.infinity;
    final double baselineMse = _calculateMse(withH2h, 0.0);

    for (double testW = 0.0; testW <= 0.351; testW += 0.01) {
      final mse = _calculateMse(withH2h, testW);
      if (mse < minMse) {
        minMse = mse;
        bestW = testW;
      }
    }

    // Bayesyen büzülme
    const double priorWeight = 6.0;
    final double blendedW =
        (priorWeight * defaultH2hWeight + withH2h.length * bestW) / (priorWeight + withH2h.length);

    final double mseReduction = baselineMse > 0 ? ((baselineMse - minMse) / baselineMse) * 100 : 0;

    return _CalibratedH2hParam(
      value: (blendedW * 100).round() / 100,
      sampleCount: withH2h.length,
      mseReductionPercent: mseReduction > 0 ? mseReduction : 0,
    );
  }

  static double _calculateMse(List<PredictionResult> matches, double h2hWeight) {
    double totalError = 0.0;
    for (final m in matches) {
      final h2h = m.headToHead!;
      final hRatio = math.min(h2h.played, LeagueConstants.headToHeadFullWeightMatches) /
          LeagueConstants.headToHeadFullWeightMatches;
      final effectiveW = h2hWeight * hRatio;

      final lambdaH = (1 - effectiveW) * m.lambdaHome + effectiveW * h2h.homeTeamGoalsAvg;
      final lambdaA = (1 - effectiveW) * m.lambdaAway + effectiveW * h2h.awayTeamGoalsAvg;

      final errH = m.actualHomeGoals! - lambdaH;
      final errA = m.actualAwayGoals! - lambdaA;
      totalError += (errH * errH) + (errA * errA);
    }
    return totalError / matches.length;
  }
}
