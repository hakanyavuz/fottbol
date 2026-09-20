import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/market_consensus.dart';
import '../models/prediction_result.dart';

/// Türkiye'deki İddaa bülteni, küresel keskin piyasalar (Pinnacle/Betfair),
/// algoritmik analiz siteleri (Forebet/PredictZ) ve topluluk oylarını
/// FOTTBOL AI ile yan yana kıyaslayan ve hibrit mutabakat üreten kart.
class MarketConsensusCard extends StatelessWidget {
  final MarketConsensus consensus;

  const MarketConsensusCard({super.key, required this.consensus});

  @override
  Widget build(BuildContext context) {
    final status = consensus.agreementStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;
    String statusBadgeText;

    switch (status) {
      case ConsensusAgreementStatus.strongConsensus:
        statusColor = AppColors.winGreen;
        statusIcon = Icons.verified;
        statusBadgeText = 'SÜPER BANKO / GÜÇLÜ MUTABAKAT';
        break;
      case ConsensusAgreementStatus.moderateConsensus:
        statusColor = Colors.amber.shade700;
        statusIcon = Icons.thumbs_up_down;
        statusBadgeText = 'ILIMLI MUTABAKAT';
        break;
      case ConsensusAgreementStatus.divergence:
        statusColor = Colors.orange.shade800;
        statusIcon = Icons.warning_amber_rounded;
        statusBadgeText = 'FİKİR AYRILIĞI / RİSK';
        break;
      case ConsensusAgreementStatus.contrarianEdge:
        statusColor = Colors.deepOrangeAccent;
        statusIcon = Icons.radar;
        statusBadgeText = 'TERS KÖŞE / GİZLİ DEĞER';
        break;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık & Durum Rozeti
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🌐 Küresel Analiz & Piyasa Konsensüsü',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusBadgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Türkiye İddaa bülteni, Pinnacle, Forebet ve Sofascore topluluk verileri harmanlanmıştır.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Durum Özeti Kutusu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      consensus.statusSummary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ters Köşe / Gizli Değer Açıklaması (Varsa)
            if (consensus.contrarianReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        consensus.contrarianReason!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.orange.shade200 : Colors.deepOrange.shade900,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Fikir Birliği İlerleme Çubuğu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fikir Birliği Oranı (Uyum)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '%${consensus.agreementScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (consensus.agreementScore / 100.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 16),

            // Kaynaklar Kıyaslama Tablosu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Kaynak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('1 (%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('X (%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('2 (%)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Skor', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 6),

            ...consensus.sources.map((src) => _SourceRow(prediction: src)),

            const SizedBox(height: 16),

            // Nihai Hibrit Olasılık (Bayesian Blended Ensemble) Kartı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.winGreen.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '🎯 NİHAİ HARMANLANMIŞ (HİBRİT) TAHMİN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Skor: ${consensus.blendedScoreString}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ProbabilityPill(
                        label: '1 (Ev Sahibi)',
                        probability: consensus.blendedHomeProbability,
                        isLeader: consensus.blendedOutcome == MatchOutcome.home,
                      ),
                      const SizedBox(width: 8),
                      _ProbabilityPill(
                        label: 'X (Beraberlik)',
                        probability: consensus.blendedDrawProbability,
                        isLeader: consensus.blendedOutcome == MatchOutcome.draw,
                      ),
                      const SizedBox(width: 8),
                      _ProbabilityPill(
                        label: '2 (Deplasman)',
                        probability: consensus.blendedAwayProbability,
                        isLeader: consensus.blendedOutcome == MatchOutcome.away,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final BenchmarkPrediction prediction;

  const _SourceRow({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final isFottbol = prediction.sourceType == BenchmarkSourceType.quantModel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
        decoration: isFottbol
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                prediction.sourceName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isFottbol ? FontWeight.w900 : FontWeight.w500,
                  color: isFottbol ? AppColors.primary : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                '%${prediction.homeProbability.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: prediction.favoriteOutcome == MatchOutcome.home ? FontWeight.bold : FontWeight.normal,
                  color: prediction.favoriteOutcome == MatchOutcome.home ? AppColors.winGreen : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '%${prediction.drawProbability.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: prediction.favoriteOutcome == MatchOutcome.draw ? FontWeight.bold : FontWeight.normal,
                  color: prediction.favoriteOutcome == MatchOutcome.draw ? Colors.amber.shade700 : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '%${prediction.awayProbability.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: prediction.favoriteOutcome == MatchOutcome.away ? FontWeight.bold : FontWeight.normal,
                  color: prediction.favoriteOutcome == MatchOutcome.away ? AppColors.winGreen : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                prediction.predictedScore ?? '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isFottbol ? FontWeight.bold : FontWeight.normal,
                  color: isFottbol ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityPill extends StatelessWidget {
  final String label;
  final double probability;
  final bool isLeader;

  const _ProbabilityPill({
    required this.label,
    required this.probability,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isLeader ? AppColors.primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isLeader ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                color: isLeader ? AppColors.primary : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              '%${probability.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isLeader ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
