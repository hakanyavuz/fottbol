import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';

/// Model Güven Skoru, Risk Seviyesi ve Fiziksel/Şut Metrikleri Kartı
class ConfidenceBadgeCard extends StatelessWidget {
  final PredictionResult prediction;

  const ConfidenceBadgeCard({super.key, required this.prediction});

  Color _getRiskColor(String risk) {
    if (risk.contains('Banko') || risk.contains('Düşük')) {
      return Colors.greenAccent.shade700;
    }
    if (risk.contains('Sürpriz') || risk.contains('Yüksek')) {
      return Colors.orangeAccent.shade700;
    }
    return AppColors.primary;
  }

  IconData _getRiskIcon(String risk) {
    if (risk.contains('Banko') || risk.contains('Düşük')) {
      return Icons.verified;
    }
    if (risk.contains('Sürpriz') || risk.contains('Yüksek')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.balance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(prediction.riskLevel);
    final riskIcon = _getRiskIcon(prediction.riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Model Güven Skoru & Risk İndeksi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    prediction.riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Güven Skoru İlerleme Çubuğu
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: prediction.confidenceScore / 100.0,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '%${prediction.confidenceScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),

            // Dinlenme ve Şut Verimlilik Göstergeleri
            Row(
              children: [
                // Ev Sahibi Dinlenme & İsabet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.homeTeam.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: (prediction.homeRestDays ?? 7) <= 3
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${prediction.homeRestDays ?? 7} gün dinlenme',
                            style: TextStyle(
                              fontSize: 11,
                              color: (prediction.homeRestDays ?? 7) <= 3
                                  ? Colors.orange
                                  : Colors.grey,
                              fontWeight: (prediction.homeRestDays ?? 7) <= 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (prediction.homeShotEfficiency != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 13, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              'Şut İsabeti: %${prediction.homeShotEfficiency!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Deplasman Dinlenme & İsabet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.awayTeam.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: (prediction.awayRestDays ?? 7) <= 3
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${prediction.awayRestDays ?? 7} gün dinlenme',
                            style: TextStyle(
                              fontSize: 11,
                              color: (prediction.awayRestDays ?? 7) <= 3
                                  ? Colors.orange
                                  : Colors.grey,
                              fontWeight: (prediction.awayRestDays ?? 7) <= 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (prediction.awayShotEfficiency != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 13, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              'Şut İsabeti: %${prediction.awayShotEfficiency!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
