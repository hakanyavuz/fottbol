import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';

/// Her takımın kaç gol atacağının olasılık dağılımı (0-5 gol).
///
/// Değerler skor matrisinin satır/sütun toplamlarıdır (marjinal dağılım).
/// Ev sahibi / deplasman renkleri uygulama genelindeki kimlik renkleridir;
/// ikili açık ve koyu yüzeyde renk körlüğü doğrulayıcısından geçmiştir.
class GoalDistributionChart extends StatelessWidget {
  final PredictionResult prediction;

  const GoalDistributionChart({super.key, required this.prediction});

  /// Ev sahibinin k gol atma olasılıkları (matris satır toplamları)
  static List<double> homeMarginal(List<List<double>> m) =>
      [for (final row in m) row.fold(0.0, (a, b) => a + b)];

  /// Deplasmanın k gol atma olasılıkları (matris sütun toplamları)
  static List<double> awayMarginal(List<List<double>> m) =>
      [for (int a = 0; a < m.first.length; a++) m.fold(0.0, (sum, row) => sum + row[a])];

  @override
  Widget build(BuildContext context) {
    final matrix = prediction.scoreMatrix;
    if (matrix.length != 6 || matrix.any((row) => row.length != 6)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final inkPrimary = theme.colorScheme.onSurface;
    final inkMuted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final gridColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    final home = homeMarginal(matrix);
    final away = awayMarginal(matrix);
    final maxY = [...home, ...away].reduce((a, b) => a > b ? a : b);
    final axisMax = ((maxY / 10).ceil() * 10).toDouble().clamp(10.0, 100.0);

    int peak(List<double> v) => v.indexOf(v.reduce((a, b) => a > b ? a : b));
    final homePeak = peak(home);
    final awayPeak = peak(away);

    // Veri uçları 4px yuvarlak, taban kare
    const rodRadius = BorderRadius.vertical(top: Radius.circular(4));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gösterge (2 seri): renkli işaret + metin rengi mürekkep, en olası değer doğrudan etiket
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendItem(
              color: AppColors.homeTeamColor,
              label: '${prediction.homeTeam.name} · en olası $homePeak gol (%${home[homePeak].toStringAsFixed(0)})',
              ink: inkPrimary,
            ),
            _LegendItem(
              color: AppColors.awayTeamColor,
              label: '${prediction.awayTeam.name} · en olası $awayPeak gol (%${away[awayPeak].toStringAsFixed(0)})',
              ink: inkPrimary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              maxY: axisMax,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barGroups: [
                for (int k = 0; k <= 5; k++)
                  BarChartGroupData(
                    x: k,
                    barsSpace: 2, // bitişik çubuklar arası yüzey boşluğu
                    barRods: [
                      BarChartRodData(
                        toY: home[k],
                        color: AppColors.homeTeamColor,
                        width: 12,
                        borderRadius: rodRadius,
                      ),
                      BarChartRodData(
                        toY: away[k],
                        color: AppColors.awayTeamColor,
                        width: 12,
                        borderRadius: rodRadius,
                      ),
                    ],
                  ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: axisMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: inkMuted.withValues(alpha: 0.4), width: 1)),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: axisMax / 4,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '%${value.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, color: inkMuted),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${value.toInt()} gol',
                        style: TextStyle(fontSize: 10.5, color: inkMuted),
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0B0B0B),
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final team = rodIndex == 0 ? prediction.homeTeam.name : prediction.awayTeam.name;
                    return BarTooltipItem(
                      '$team\n${group.x} gol: %${rod.toY.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color ink;

  const _LegendItem({required this.color, required this.label, required this.ink});

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
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(fontSize: 11.5, color: ink))),
      ],
    );
  }
}
