import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../models/coupon_slip.dart';

/// Günün Akıllı Kupon Sihirbazı Kartı
class SmartCouponWizardCard extends StatelessWidget {
  final List<CouponSlip> slips;
  final void Function(CouponItem item)? onItemTap;

  const SmartCouponWizardCard({
    super.key,
    required this.slips,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'Günün Akıllı Kupon Sihirbazı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Modelin en yüksek güven skoru ve değer marjına sahip maçlarından otomatik derlenmiştir.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...slips.map((slip) => _CouponSlipView(slip: slip, onItemTap: onItemTap)),
      ],
    );
  }
}

class _CouponSlipView extends StatelessWidget {
  final CouponSlip slip;
  final void Function(CouponItem item)? onItemTap;

  const _CouponSlipView({required this.slip, this.onItemTap});

  Color _getHeaderColor(String cat) {
    if (cat.contains('Banko')) return Colors.greenAccent.shade700;
    if (cat.contains('Sürpriz')) return Colors.orangeAccent.shade700;
    return AppColors.primary;
  }

  void _showCouponShareDialog(BuildContext context, CouponSlip slip) {
    final buffer = StringBuffer();
    buffer.writeln('🎯 BÜYÜKDEFTER QUANT AKILLI KUPON 🎯');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 ${slip.title} (${slip.category})');
    buffer.writeln('📅 ${slip.date.day}.${slip.date.month}.${slip.date.year}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    for (final it in slip.items) {
      buffer.writeln('${it.sportEmoji} ${it.matchTitle}');
      buffer.writeln('   👉 Tercih: ${it.selectionLabel} | Oran: ${it.odds.toStringAsFixed(2)} (Güven: %${it.confidenceScore.toStringAsFixed(0)})');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🔥 Toplam Oran: ${slip.totalOdds.toStringAsFixed(2)}');
    buffer.writeln('🎲 Bileşik Başarı İhtimali: %${slip.jointProbabilityPercentage.toStringAsFixed(1)}');
    buffer.writeln('📈 Beklenen Değer (EV): ${slip.expectedValuePercentage >= 0 ? '+' : ''}${slip.expectedValuePercentage.toStringAsFixed(1)}%');
    buffer.writeln('💰 Kelly Kasa Önerisi: %${slip.kellyStakeRecommendation.toStringAsFixed(1)} Kasa Payı');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🤖 BüyükDefter / All-in-One Sports Analytics');
    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Kupon Bülteni Paylaş',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Panoya Kopyala'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Kupon bülteni kopyalandı. WhatsApp veya sosyal medyada paylaşabilirsiniz!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getHeaderColor(slip.category);
    final status = slip.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: status == 'winning' 
            ? const BorderSide(color: Colors.green, width: 2)
            : status == 'lost'
                ? const BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            slip.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (status == 'winning') ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.stars, color: Colors.green, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ort. Güven: %${slip.combinedConfidenceScore.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20, color: Colors.white70),
                  tooltip: 'Kuponu Paylaş / Kopyala',
                  onPressed: () => _showCouponShareDialog(context, slip),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'winning' ? Colors.green.withOpacity(0.1) : (status == 'lost' ? Colors.red.withOpacity(0.1) : color.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: status == 'winning' ? Colors.green : (status == 'lost' ? Colors.red : color.withOpacity(0.4))),
                  ),
                  child: Column(
                    children: [
                      Text(
                        status == 'winning' ? 'KAZANDI' : (status == 'lost' ? 'KAYBETTİ' : 'Toplam Oran'),
                        style: TextStyle(fontSize: 10, color: status == 'winning' ? Colors.green : (status == 'lost' ? Colors.red : Colors.grey), fontWeight: FontWeight.bold),
                      ),
                      Text(
                        slip.totalOdds.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: status == 'winning' ? Colors.green : (status == 'lost' ? Colors.red : color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
            const SizedBox(height: 8),

            // Kupon Maçları
            ...slip.items.map((it) {
              final won = it.isWon;
              return InkWell(
                onTap: () => onItemTap?.call(it),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        won == true ? Icons.check_circle : (won == false ? Icons.cancel : Icons.check_circle_outline),
                        size: 16,
                        color: won == true ? Colors.green : (won == false ? Colors.red : Colors.greenAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.matchTitle,
                              style: TextStyle(
                                fontSize: 12.5, 
                                fontWeight: FontWeight.w600,
                                decoration: won == false ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              it.selectionLabel + (it.prediction?.hasResult == true ? ' (${it.prediction?.actualScoreString})' : ''),
                              style: TextStyle(fontSize: 11, color: won == false ? Colors.red.withOpacity(0.7) : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          it.odds.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Bileşik İhtimal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '%${slip.jointProbabilityPercentage.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 22, color: Colors.white12),
                  Column(
                    children: [
                      const Text('Beklenen Değer (EV)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '${slip.expectedValuePercentage >= 0 ? '+' : ''}${slip.expectedValuePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: slip.expectedValuePercentage >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 22, color: Colors.white12),
                  Column(
                    children: [
                      const Text('Kelly Kasa Payı', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '%${slip.kellyStakeRecommendation.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (slip.aiAnalysis != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.purpleAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slip.aiAnalysis!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          height: 1.4,
                        ),
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
