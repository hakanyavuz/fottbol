import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/team.dart';
import '../providers/match_prediction_provider.dart';
import '../widgets/comparison_bar.dart';
import '../widgets/form_badge.dart';
import 'prediction_screen.dart';

/// 4. Ekran: İki Takımın Yan Yana İstatistiksel Karşılaştırma Ekranı
class ComparisonScreen extends StatelessWidget {
  final Team homeTeam;
  final Team awayTeam;

  const ComparisonScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  Widget build(BuildContext context) {
    final hStat = homeTeam.stats;
    final aStat = awayTeam.stats;
    final provider = context.watch<MatchPredictionProvider>();

    // Topla oynama / şut metrikleri her veri kaynağında bulunmaz.
    // Veri yoksa uydurma değer yerine satır gizlenir ya da "—" gösterilir.
    Widget optionalBar(
      String title,
      double? homeValue,
      double? awayValue,
      String Function(double) format,
    ) {
      if (homeValue == null && awayValue == null) return const SizedBox.shrink();
      return ComparisonBar(
        title: title,
        homeValueText: homeValue != null ? format(homeValue) : '—',
        awayValueText: awayValue != null ? format(awayValue) : '—',
        homeValue: homeValue ?? 0,
        awayValue: awayValue ?? 0,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Takım Kıyaslaması'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Üst Karşılaşma Başlığı Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    // Ev Sahibi Logo & İsim
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.homeTeamColor.withOpacity(0.15),
                            child: Text(
                              homeTeam.initial,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.homeTeamColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            homeTeam.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          FormBadgeList(form: hStat.recentForm),
                        ],
                      ),
                    ),

                    // VS Rozeti
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey),
                      ),
                    ),

                    // Deplasman Logo & İsim
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.awayTeamColor.withOpacity(0.15),
                            child: Text(
                              awayTeam.initial,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.awayTeamColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            awayTeam.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          FormBadgeList(form: aStat.recentForm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Karşılaştırma Barları Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📈 Sezonluk Metrik Kıyaslaması',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    optionalBar(
                      'Topla Oynama',
                      hStat.avgPossession,
                      aStat.avgPossession,
                      (v) => '%${v.toStringAsFixed(1)}',
                    ),

                    optionalBar(
                      'Maç Başı Şut',
                      hStat.avgShotsPerGame,
                      aStat.avgShotsPerGame,
                      (v) => v.toStringAsFixed(1),
                    ),

                    optionalBar(
                      'İsabetli Şut',
                      hStat.avgShotsOnTarget,
                      aStat.avgShotsOnTarget,
                      (v) => v.toStringAsFixed(1),
                    ),

                    ComparisonBar(
                      title: 'Atılan Gol Ort.',
                      homeValueText: hStat.avgGoalsScored.toStringAsFixed(2),
                      awayValueText: aStat.avgGoalsScored.toStringAsFixed(2),
                      homeValue: hStat.avgGoalsScored,
                      awayValue: aStat.avgGoalsScored,
                    ),

                    ComparisonBar(
                      title: 'Yenilen Gol Ort.',
                      homeValueText: hStat.avgGoalsConceded.toStringAsFixed(2),
                      awayValueText: aStat.avgGoalsConceded.toStringAsFixed(2),
                      // Düşük olan daha iyi olduğu için değerler ters ölçeklenebilir
                      homeValue: hStat.avgGoalsConceded,
                      awayValue: aStat.avgGoalsConceded,
                    ),

                    ComparisonBar(
                      title: 'Galibiyet Oranı',
                      homeValueText: '%${hStat.winRate.toStringAsFixed(0)}',
                      awayValueText: '%${aStat.winRate.toStringAsFixed(0)}',
                      homeValue: hStat.winRate,
                      awayValue: aStat.winRate,
                    ),

                    ComparisonBar(
                      title: 'Clean Sheet (Gol Yememe)',
                      homeValueText: '${hStat.cleanSheets}',
                      awayValueText: '${aStat.cleanSheets}',
                      homeValue: hStat.cleanSheets.toDouble(),
                      awayValue: aStat.cleanSheets.toDouble(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kilit Oyuncu Karşılaştırması Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⭐ Kilit Golcüler Karşılaştırması',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PlayerHighlight(
                            player: homeTeam.topScorer,
                            teamColor: AppColors.homeTeamColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PlayerHighlight(
                            player: awayTeam.topScorer,
                            teamColor: AppColors.awayTeamColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tahmin Ekranına Git Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('Bu Maç İçin Tahmin Üret'),
                onPressed: () async {
                  final res = await provider.executePrediction();
                  if (res != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PredictionScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHighlight extends StatelessWidget {
  final dynamic player;
  final Color teamColor;

  const _PlayerHighlight({required this.player, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    if (player == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: teamColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('⚽ ${player.goals} Gol | 👟 ${player.assists} Asist', style: const TextStyle(fontSize: 11)),
          Text('⭐ Form Puanı: ${player.rating}', style: const TextStyle(fontSize: 11, color: Colors.amber)),
        ],
      ),
    );
  }
}
