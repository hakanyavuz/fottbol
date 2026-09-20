import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MomentumGraph extends StatelessWidget {
  const MomentumGraph({super.key});

  @override
  Widget build(BuildContext context) {
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
            _makeGroup(0, 4),
            _makeGroup(1, 7),
            _makeGroup(2, 5),
            _makeGroup(3, -2),
            _makeGroup(4, -5),
            _makeGroup(5, 2),
            _makeGroup(6, 8),
            _makeGroup(7, 3),
            _makeGroup(8, -1),
            _makeGroup(9, 6),
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
