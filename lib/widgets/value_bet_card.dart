import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/value_bet.dart';

/// Değerli Bahis (Value Bet) ve Oran Avantajı Kartı
class ValueBetCard extends StatelessWidget {
  final ValueBet bet;
  final VoidCallback? onTap;

  const ValueBetCard({super.key, required this.bet, this.onTap});

  Color _getBadgeColor(String risk) {
    if (risk.contains('Banko')) return Colors.greenAccent.shade700;
    if (risk.contains('Sürpriz') || risk.contains('Yüksek')) return Colors.orangeAccent.shade700;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _getBadgeColor(bet.riskCategory);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: Lig, Tarih ve Risk Rozeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${bet.leagueName} ${bet.matchDate != null ? "• ${DateFormat("dd.MM HH:mm").format(bet.matchDate!)}" : ""}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      bet.riskCategory,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Maç Başlığı
              Text(
                bet.matchTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Tercih Kutusu ve Oran Avantajı
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Önerilen Tercih', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            bet.selectionLabel,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // Piyasa Oranı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Oran', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                          Text(
                            bet.marketOdds.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Model İhtimali vs Piyasa İhtimali (Edge Göstergesi)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Model İhtimali: %${bet.modelProbability.toStringAsFixed(1)} (Piyasa: %${bet.impliedProbability.toStringAsFixed(1)})',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        '+%${bet.edgePercentage.toStringAsFixed(1)} Değer',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          'Kelly Kasa Yönetimi (1/2 Kelly):',
                          style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '%${bet.kellyStakePercentage.toStringAsFixed(1)} Kasa Payı',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              if (bet.prediction.isHighManipulationRisk) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '🛡️ ${bet.prediction.manipulationRiskRegion ?? "Bölgesel"} Lig/Kupa Kalkanı: Manipülasyon & varyans riski nedeniyle kasa payı korumalı (%30 indirimli) hesaplandı.',
                          style: const TextStyle(fontSize: 10.5, color: Colors.deepOrangeAccent, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
