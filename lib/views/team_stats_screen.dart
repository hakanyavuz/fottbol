import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/team.dart';
import '../widgets/form_badge.dart';

/// 2. Ekran: Takım Detaylı İstatistikleri, Form Durumu ve Son Maçlar
class TeamStatsScreen extends StatelessWidget {
  final Team team;

  const TeamStatsScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final s = team.stats;

    return Scaffold(
      appBar: AppBar(
        title: Text('${team.shortName} İstatistikleri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey.withOpacity(0.2),
                      child: Text(
                        team.initial,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${team.league} • ${team.venue}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Son Form: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              FormBadgeList(form: s.recentForm),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Genel Sezon Özeti Kartı
            const Text(
              '📊 Sezonluk Genel Performans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(title: 'Oynanan', value: '${s.played}', color: Colors.blueGrey),
                        _StatBox(title: 'Galibiyet', value: '${s.won}', color: AppColors.winGreen),
                        _StatBox(title: 'Beraberlik', value: '${s.drawn}', color: AppColors.drawYellow),
                        _StatBox(title: 'Mağlubiyet', value: '${s.lost}', color: AppColors.lossRed),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(
                          title: 'Kazanma Oranı',
                          value: '%${s.winRate.toStringAsFixed(1)}',
                          color: AppColors.primary,
                        ),
                        _StatBox(
                          title: 'Atılan Gol Ort.',
                          value: s.avgGoalsScored.toStringAsFixed(2),
                          color: Colors.tealAccent,
                        ),
                        _StatBox(
                          title: 'Yenilen Gol Ort.',
                          value: s.avgGoalsConceded.toStringAsFixed(2),
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İç Saha vs Dış Saha Kıyaslama Kartı
            const Text(
              '🏟️ İç Saha vs Dış Saha Dağılımı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // İç Saha
                Expanded(
                  child: Card(
                    color: AppColors.homeTeamColor.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'İç Saha (Ev)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.homeTeamColor),
                          ),
                          const SizedBox(height: 6),
                          Text('Maç: ${s.homePlayed} (${s.homeWon}G / ${s.homeDrawn}B / ${s.homeLost}M)'),
                          Text('Atılan Gol: ${s.homeGoalsScored} (Ort: ${s.avgHomeGoalsScored.toStringAsFixed(1)})'),
                          Text('Yenilen Gol: ${s.homeGoalsConceded} (Ort: ${s.avgHomeGoalsConceded.toStringAsFixed(1)})'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dış Saha
                Expanded(
                  child: Card(
                    color: AppColors.awayTeamColor.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dış Saha (Dep)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.awayTeamColor),
                          ),
                          const SizedBox(height: 6),
                          Text('Maç: ${s.awayPlayed} (${s.awayWon}G / ${s.awayDrawn}B / ${s.awayLost}M)'),
                          Text('Atılan Gol: ${s.awayGoalsScored} (Ort: ${s.avgAwayGoalsScored.toStringAsFixed(1)})'),
                          Text('Yenilen Gol: ${s.awayGoalsConceded} (Ort: ${s.avgAwayGoalsConceded.toStringAsFixed(1)})'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Oyun İstatistikleri (Topla Oynama & Şut)
            const Text(
              '🎯 Taktiksel Oyun Metrikleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Bu üç metrik her veri kaynağında bulunmaz; yoksa uydurulmaz
                    _MetricRow(
                      label: 'Ortalama Topla Oynama',
                      value: s.avgPossession != null
                          ? '%${s.avgPossession!.toStringAsFixed(1)}'
                          : 'Veri yok',
                    ),
                    const Divider(),
                    _MetricRow(
                      label: 'Maç Başı Toplam Şut',
                      value: s.avgShotsPerGame?.toStringAsFixed(1) ?? 'Veri yok',
                    ),
                    const Divider(),
                    _MetricRow(
                      label: 'İsabetli Şut Ortalaması',
                      value: s.avgShotsOnTarget?.toStringAsFixed(1) ?? 'Veri yok',
                    ),
                    const Divider(),
                    _MetricRow(label: 'Gol Yemediği Maç (Clean Sheet)', value: '${s.cleanSheets} maç'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
      ],
    );
  }
}
