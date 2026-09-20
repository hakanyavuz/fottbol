import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/head_to_head.dart';

/// Aralarındaki son maçların özeti: galibiyet/beraberlik/mağlubiyet dağılımı
/// (parça-bütün yığılmış çubuk) ve son 5 maçın skorları.
class HeadToHeadCard extends StatelessWidget {
  final HeadToHeadSummary summary;
  final String homeName;
  final String awayName;

  const HeadToHeadCard({
    super.key,
    required this.summary,
    required this.homeName,
    required this.awayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.6);
    final neutral = ink.withValues(alpha: 0.22);

    final segments = [
      (summary.homeTeamWins, AppColors.homeTeamColor),
      (summary.draws, neutral),
      (summary.awayTeamWins, AppColors.awayTeamColor),
    ].where((s) => s.$1 > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_edu, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aralarındaki Son Maçlar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${summary.played} maç', style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
            const SizedBox(height: 12),

            // Yığılmış çubuk: parçalar kenarlıkla değil 2px boşlukla ayrılır
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (int i = 0; i < segments.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(flex: segments[i].$1, child: Container(color: segments[i].$2)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Gösterge + doğrudan etiketler (metin mürekkep renginde)
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _Key(color: AppColors.homeTeamColor, text: '$homeName ${summary.homeTeamWins}G', ink: ink),
                _Key(color: neutral, text: 'Beraberlik ${summary.draws}', ink: ink),
                _Key(color: AppColors.awayTeamColor, text: '$awayName ${summary.awayTeamWins}G', ink: ink),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Maç başı gol: ${summary.homeTeamGoalsAvg.toStringAsFixed(1)} - ${summary.awayTeamGoalsAvg.toStringAsFixed(1)}'
              '  ·  Tahmine etkisi %${(summary.weight * 100).toStringAsFixed(0)}',
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
            const SizedBox(height: 8),

            // Derin H2H İpuçları: KG Var % ve 2.5 Üst %
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'KG Var: %${summary.bttsPercentage.toStringAsFixed(0)} (${summary.bttsCount}/${summary.played})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '2.5 Üst: %${summary.over25Percentage.toStringAsFixed(0)} (${summary.over25Count}/${summary.played})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),

            if (summary.recent.isNotEmpty) ...[
              Divider(height: 22, thickness: 1, color: ink.withValues(alpha: 0.10)),
              for (final m in summary.recent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          m.date != null ? DateFormat('dd.MM.yyyy').format(m.date!) : '-',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.homeName,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${m.homeGoals} - ${m.awayGoals}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.awayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Color color;
  final String text;
  final Color ink;

  const _Key({required this.color, required this.text, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11.5, color: ink)),
      ],
    );
  }
}
