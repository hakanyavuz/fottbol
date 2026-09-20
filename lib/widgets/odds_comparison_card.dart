import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/odds_comparison.dart';

/// Bahis bürosu oranları ile Poisson model olasılıklarını karşılaştıran
/// ve istatistiksel avantaj (Value Bet) içeren tercihleri vurgulayan kart.
class OddsComparisonCard extends StatelessWidget {
  final OddsComparison comparison;

  const OddsComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final odds = comparison.odds;
    final hasValue = comparison.hasValueBet;
    final best = comparison.bestChoice;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Büro Bilgisi
            Row(
              children: [
                const Icon(Icons.balance, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⚖️ Piyasa Oranları & Value Bet Analizi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    odds.bookmakerName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Büro Kâr Marjı: %${odds.marginPercent.toStringAsFixed(1)} (Arındırılmış saf piyasa olasılıklarıyla kıyaslanır)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Kıyaslama Tablosu Başlıkları
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Tercih', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Oran', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Piyasa', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Model', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Fark / EV', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Satırlar: 1, X, 2
            _ChoiceRow(choice: comparison.homeChoice),
            const Divider(height: 1),
            _ChoiceRow(choice: comparison.drawChoice),
            const Divider(height: 1),
            _ChoiceRow(choice: comparison.awayChoice),

            // Value Bet Bildirim Kutusu
            if (hasValue) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.winGreen.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '⚡ Değerli Tercih: ${best.outcomeLabel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Oran: ${best.odd.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Model bu tercihe piyasadan %+${best.probabilityDiff.toStringAsFixed(1)} daha yüksek olasılık veriyor '
                            '(Beklenen Değer / EV: %+${(best.expectedValue * 100).toStringAsFixed(1)}).',
                            style: const TextStyle(fontSize: 11.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Bu maçta piyasa oranları ile model tahminleri dengeli; belirgin bir değer sapması (Value Bet) görülmüyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final ValueBetChoice choice;

  const _ChoiceRow({required this.choice});

  @override
  Widget build(BuildContext context) {
    final diff = choice.probabilityDiff;
    final isValue = choice.isValue;
    final diffColor = isValue
        ? AppColors.winGreen
        : diff > 0
            ? AppColors.drawYellow
            : Colors.grey;

    final evPercent = (choice.expectedValue * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Tercih Adı
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  choice.outcomeLabel,
                  style: TextStyle(
                    fontWeight: isValue ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isValue ? AppColors.primary : null,
                  ),
                ),
                if (isValue) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                ],
              ],
            ),
          ),
          // Oran
          Expanded(
            child: Text(
              choice.odd.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Piyasa %
          Expanded(
            child: Text(
              '%${choice.marketProbability.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          // Model %
          Expanded(
            child: Text(
              '%${choice.modelProbability.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isValue ? AppColors.winGreen : null,
              ),
            ),
          ),
          // Fark & EV
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${diff >= 0 ? '+' : ''}%${diff.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: diffColor,
                  ),
                ),
                Text(
                  'EV: ${evPercent >= 0 ? '+' : ''}%$evPercent',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isValue ? FontWeight.bold : FontWeight.normal,
                    color: choice.expectedValue >= 0 ? AppColors.winGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
