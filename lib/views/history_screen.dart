import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as p;
import '../core/constants/app_colors.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';
import '../widgets/accuracy_card.dart';
import 'prediction_screen.dart';

/// 6. Ekran: Geçmiş Tahminler, Gerçek Sonuçlar ve İsabet Karnesi
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _checkResults(BuildContext context, WidgetRef ref) async {
    final provider = context.read<MatchPredictionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final updated = await provider.refreshResults(ref.read(apiFootballServiceProvider));

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          updated > 0
              ? '$updated maçın sonucu kaydedildi, isabet karnesi güncellendi.'
              : 'Yeni sonuçlanan maç yok (maçlar henüz bitmemiş olabilir).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = context.watch<MatchPredictionProvider>();
    final history = provider.pastPredictions;
    final canCheck = ref.watch(apiFootballServiceProvider).hasKey;
    final pendingCount = history.where((p) => p.isAwaitingResult).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📜 Geçmiş Tahminler'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Geçmişi Temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Geçmişi Temizle'),
                    content: const Text('Tüm kaydedilmiş tahmin geçmişi silinsin mi?'),
                    actions: [
                      TextButton(
                        child: const Text('İptal'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      TextButton(
                        child: const Text('Sil', style: TextStyle(color: AppColors.lossRed)),
                        onPressed: () {
                          provider.clearHistory();
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz kayıtlı bir tahmin bulunmuyor.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Yeni bir maç seçip tahmin ürettiğinizde burada listelenir.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => canCheck ? _checkResults(context, ref) : Future.value(),
                child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: history.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return AccuracyCard(
                      accuracy: provider.accuracy,
                      calibration: provider.calibration,
                      pendingCount: pendingCount,
                      isChecking: provider.isCheckingResults,
                      canCheck: canCheck,
                      onCheckResults: () => _checkResults(context, ref),
                    );
                  }

                  final item = history[index - 1];
                  // Gerçek maça bağlı tahminlerde maç tarihi, diğerlerinde tahmin tarihi gösterilir
                  final dateStr = item.matchDate != null
                      ? 'Maç: ${DateFormat('dd.MM.yyyy HH:mm').format(item.matchDate!)}'
                      : DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Tıklanan kaydın kendisi salt okunur modda açılır
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PredictionScreen(historyItem: item),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // Tarih ve Lig
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.homeTeam.league,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Maç Eşleşmesi ve Tahmin Skoru
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Ev Sahibi
                                Expanded(
                                  child: Text(
                                    item.homeTeam.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.left,
                                  ),
                                ),

                                // Tahmin Skoru Rozeti
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primary),
                                  ),
                                  child: Text(
                                    item.predictedScoreString,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),

                                // Deplasman
                                Expanded(
                                  child: Text(
                                    item.awayTeam.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // xG ve İhtimal Özeti
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'xG: ${item.lambdaHome.toStringAsFixed(2)} - ${item.lambdaAway.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  '1 (%${item.homeWinProbability.toStringAsFixed(0)}) • X (%${item.drawProbability.toStringAsFixed(0)}) • 2 (%${item.awayWinProbability.toStringAsFixed(0)})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ResultBadge(prediction: item),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
