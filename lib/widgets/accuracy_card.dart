import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';

import '../services/model_calibrator.dart';

/// Tahmin geçmişinin isabet karnesi.
///
/// Yalnızca gerçek bir maça bağlı, maç başlamadan önce yapılmış ve sonucu
/// belli olan tahminler sayılır.
class AccuracyCard extends StatelessWidget {
  final PredictionAccuracy accuracy;
  final CalibrationResult? calibration;
  final int pendingCount;
  final bool isChecking;
  final bool canCheck;
  final VoidCallback? onCheckResults;

  const AccuracyCard({
    super.key,
    required this.accuracy,
    this.calibration,
    required this.pendingCount,
    required this.isChecking,
    required this.canCheck,
    this.onCheckResults,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'İsabet Karnesi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  '${accuracy.settled} maç',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!accuracy.hasData)
              const Text(
                'Henüz sonuçlanmış bir tahmin yok. Lig ekranındaki "Maçlar" sekmesinden '
                'yaklaşan bir maçı tahmin edin; maç oynandıktan sonra gerçek skorla karşılaştırılır.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              )
            else
              Row(
                children: [
                  _RateBox(label: 'Maç Sonucu\n(1X2)', rate: accuracy.outcomeRate, hits: accuracy.outcomeHits),
                  _RateBox(label: 'Skor\n(Tam)', rate: accuracy.exactScoreRate, hits: accuracy.exactScoreHits),
                  _RateBox(label: 'Skor\n(İlk 3)', rate: accuracy.top3ScoreRate, hits: accuracy.top3ScoreHits),
                  _RateBox(label: '2.5\nÜst/Alt', rate: accuracy.over25Rate, hits: accuracy.over25Hits),
                  _RateBox(label: 'KG\nVar/Yok', rate: accuracy.bttsRate, hits: accuracy.bttsHits),
                ],
              ),

            if (calibration != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: (calibration!.isDataCalibrated ? AppColors.primary : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (calibration!.isDataCalibrated ? AppColors.primary : Colors.grey)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      calibration!.isDataCalibrated ? Icons.auto_awesome : Icons.science_outlined,
                      size: 16,
                      color: calibration!.isDataCalibrated ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calibration!.isDataCalibrated
                            ? 'Kalibre Model (Veriden): ρ = ${calibration!.calibratedRho.toStringAsFixed(2)} • H2H Ağırlığı: %${(calibration!.calibratedH2hWeight * 100).toInt()}'
                            : 'Model Parametreleri: ρ = ${calibration!.defaultRho.toStringAsFixed(2)} • H2H Ağırlığı: %${(calibration!.defaultH2hWeight * 100).toInt()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (pendingCount > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(
                    !canCheck
                        ? '$pendingCount maç sonuç bekliyor (API-Football anahtarı gerekli)'
                        : isChecking
                            ? 'Sonuçlar kontrol ediliyor...'
                            : '$pendingCount maçın sonucunu kontrol et',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onPressed: canCheck && !isChecking ? onCheckResults : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateBox extends StatelessWidget {
  final String label;
  final double rate;
  final int hits;

  const _RateBox({required this.label, required this.rate, required this.hits});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 60
        ? AppColors.winGreen
        : rate >= 40
            ? AppColors.drawYellow
            : AppColors.lossRed;

    return Expanded(
      child: Column(
        children: [
          Text(
            '%${rate.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
          Text('$hits isabet', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Geçmiş listesindeki tek tahminin sonuç rozeti
class ResultBadge extends StatelessWidget {
  final PredictionResult prediction;

  const ResultBadge({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final p = prediction;

    if (p.fixtureId == null) {
      return const _Badge(text: 'Serbest eşleşme', color: Colors.grey, icon: Icons.tune);
    }
    if (const ['PST', 'CANC', 'ABD', 'AWD', 'WO'].contains(p.fixtureStatus)) {
      return const _Badge(text: 'Ertelendi / iptal', color: Colors.orange, icon: Icons.event_busy);
    }
    if (!p.isPreMatch) {
      return const _Badge(text: 'Maç sonrası tahmin (sayılmaz)', color: Colors.grey, icon: Icons.block);
    }
    if (!p.hasResult) {
      return p.isAwaitingResult
          ? const _Badge(text: 'Sonuç bekleniyor', color: AppColors.drawYellow, icon: Icons.hourglass_bottom)
          : const _Badge(text: 'Oynanmadı', color: AppColors.homeTeamColor, icon: Icons.schedule);
    }

    final outcomeHit = p.isOutcomeHit == true;
    final exactHit = p.isExactScoreHit == true;

    return _Badge(
      text: exactHit
          ? 'Gerçek: ${p.actualScoreString} • Tam skor!'
          : 'Gerçek: ${p.actualScoreString} • ${outcomeHit ? '1X2 tuttu' : '1X2 tutmadı'}',
      color: exactHit
          ? AppColors.primary
          : outcomeHit
              ? AppColors.winGreen
              : AppColors.lossRed,
      icon: exactHit || outcomeHit ? Icons.check_circle : Icons.cancel,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Badge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
