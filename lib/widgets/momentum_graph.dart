import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MomentumGraph extends StatelessWidget {
  final List<double>? momentumPoints;
  const MomentumGraph({super.key, this.momentumPoints});

  @override
  Widget build(BuildContext context) {
    final points = momentumPoints ?? const [4, 7, 5, -2, -5, 2, 8, 3, -1, 6];

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          maxY: 10,
          minY: -10,
          groupsSpace: 12,
          barTouchData: BarTouchData(enabled: false),
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < points.length; i++)
              _makeGroup(i, points[i]),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y > 0 ? AppColors.homeTeamColor : AppColors.awayTeamColor,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
