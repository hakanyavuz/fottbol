import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';

class MatchProbabilityChart extends StatelessWidget {
  final PredictionResult prediction;

  const MatchProbabilityChart({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              startDegreeOffset: 270,
              sections: [
                PieChartSectionData(
                  value: prediction.homeWinProbability,
                  title: '%${prediction.homeWinProbability.toStringAsFixed(0)}',
                  color: AppColors.homeTeamColor,
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: prediction.drawProbability,
                  title: '%${prediction.drawProbability.toStringAsFixed(0)}',
                  color: AppColors.drawYellow,
                  radius: 45,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: prediction.awayWinProbability,
                  title: '%${prediction.awayWinProbability.toStringAsFixed(0)}',
                  color: AppColors.awayTeamColor,
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Indicator(color: AppColors.homeTeamColor, text: 'Ev Sahibi'),
            SizedBox(width: 16),
            _Indicator(color: AppColors.drawYellow, text: 'Beraberlik'),
            SizedBox(width: 16),
            _Indicator(color: AppColors.awayTeamColor, text: 'Deplasman'),
          ],
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
