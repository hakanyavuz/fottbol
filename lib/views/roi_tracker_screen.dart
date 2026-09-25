import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';
import '../providers/match_prediction_provider.dart';

/// Model Şeffaflığı ve Kasa Getirisi (Quant Performance & ROI Tracker) Ekranı
class RoiTrackerScreen extends StatefulWidget {
  const RoiTrackerScreen({super.key});

  @override
  State<RoiTrackerScreen> createState() => _RoiTrackerScreenState();
}

class _RoiTrackerScreenState extends State<RoiTrackerScreen> {
  String _selectedPeriod = 'Tümü'; // 'Son 7 Gün', 'Son 30 Gün', 'Tümü'

  List<PredictionResult> _filterPredictions(List<PredictionResult> list) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Son 7 Gün') {
      final cutoff = now.subtract(const Duration(days: 7));
      return list.where((p) => p.createdAt.isAfter(cutoff)).toList();
    }
    if (_selectedPeriod == 'Son 30 Gün') {
      final cutoff = now.subtract(const Duration(days: 30));
      return list.where((p) => p.createdAt.isAfter(cutoff)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MatchPredictionProvider>(context);
    final past = provider.pastPredictions;
    final filtered = _filterPredictions(past);
    final settled = filtered.where((p) => p.hasResult).toList();

    // İstatistik Hesaplamaları
    int totalSettled = settled.length;
    int outcomeHits = 0;
    int exactHits = 0;
    int overHits = 0;
    double totalStake = 0.0;
    double totalReturn = 0.0;

    for (final p in settled) {
      final actualOutcome = p.actualOutcome;
      if (actualOutcome == p.predictedOutcome) {
        outcomeHits++;
      }
      if (p.predictedHomeGoals == p.actualHomeGoals && p.predictedAwayGoals == p.actualAwayGoals) {
        exactHits++;
      }
      final totalGoals = (p.actualHomeGoals ?? 0) + (p.actualAwayGoals ?? 0);
      final isOver = totalGoals >= 3;
      final predictedOver = p.over25Probability >= 50.0;
      if (isOver == predictedOver) {
        overHits++;
      }

      // Teorik Sabit Kasa Getirisi (Her maça 100 birim)
      final odds = p.oddsComparison?.odds;
      if (odds != null) {
        totalStake += 100.0;
        if (actualOutcome == p.predictedOutcome) {
          double wonOdd = 1.0;
          if (actualOutcome == MatchOutcome.home) wonOdd = odds.homeOdd;
          if (actualOutcome == MatchOutcome.draw) wonOdd = odds.drawOdd;
          if (actualOutcome == MatchOutcome.away) wonOdd = odds.awayOdd;
          totalReturn += (100.0 * wonOdd);
        }
      }
    }

    final outcomeHitRate = totalSettled > 0 ? (outcomeHits / totalSettled) * 100.0 : 0.0;
    final exactHitRate = totalSettled > 0 ? (exactHits / totalSettled) * 100.0 : 0.0;
    final overHitRate = totalSettled > 0 ? (overHits / totalSettled) * 100.0 : 0.0;
    final netRoi = totalStake > 0 ? ((totalReturn - totalStake) / totalStake) * 100.0 : 0.0;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.query_stats_outlined, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('ROI & QUANT PERFORMANSI'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Periyot Seçici
            Row(
              children: ['Son 7 Gün', 'Son 30 Gün', 'Tümü'].map((period) {
                final isSel = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(period, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.black : null)),
                    selected: isSel,
                    selectedColor: Colors.greenAccent,
                    onSelected: (_) => setState(() => _selectedPeriod = period),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Ana ROI Gösterge Paneli
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: netRoi >= 0 ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Teorik Kasa Getirisi (ROI)',
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (netRoi >= 0 ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            netRoi >= 0 ? 'KÂRDA' : 'ZARARDA',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: netRoi >= 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${netRoi >= 0 ? "+" : ""}${netRoi.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: netRoi >= 0 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalStake > 0
                          ? 'Toplam ${totalStake.toInt()} birim yatırıldı, ${totalReturn.toInt()} birim geri dönüş sağlandı.'
                          : 'Henüz oranlı ve sonuçlanmış maç kaydı bulunmuyor.',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İsabet Oranları Izgarası
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'MS 1X2 Başarısı',
                    value: '%${outcomeHitRate.toStringAsFixed(1)}',
                    subtext: '$outcomeHits / $totalSettled Maç',
                    color: AppColors.primary,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: '2.5 Gol İsabeti',
                    value: '%${overHitRate.toStringAsFixed(1)}',
                    subtext: '$overHits / $totalSettled Maç',
                    color: Colors.amber,
                    icon: Icons.sports_soccer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: 'Tam Skor',
                    value: '%${exactHitRate.toStringAsFixed(1)}',
                    subtext: '$exactHits / $totalSettled Maç',
                    color: Colors.purpleAccent,
                    icon: Icons.pin_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sonuçlanan Tahminler Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sonuçlanan Karşılaşma Geçmişi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${settled.length} Kayıt',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (settled.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_toggle_off, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Henüz sonucu tamamlanmış tahmin bulunmuyor.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...settled.map((p) {
                final isHit = p.actualOutcome == p.predictedOutcome;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isHit ? Icons.check_circle : Icons.cancel_outlined,
                      color: isHit ? Colors.greenAccent : Colors.redAccent,
                    ),
                    title: Text(
                      '${p.homeTeam.name} - ${p.awayTeam.name}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Öngörü: ${p.predictedScoreString} (${p.primaryPick}) • Gerçek: ${p.actualScoreString}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                    trailing: Text(
                      p.homeTeam.league,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
