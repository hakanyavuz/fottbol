import 'package:flutter/material.dart';
import '../models/goal_timing_distribution.dart';

class GoalTimingCard extends StatelessWidget {
  final GoalTimingDistribution timing;
  final String homeTeam;
  final String awayTeam;

  const GoalTimingCard({
    super.key,
    required this.timing,
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  Widget build(BuildContext context) {
    const intervals = [
      '0-15',
      '16-30',
      '31-45',
      '46-60',
      '61-75',
      '76-90+',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gol Zamanlama & Periyot Dağılımı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '15\'er dakikalık dilimlerde canlı gol olasılık baskısı',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      timing.peakInterval,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // İlk Yarı vs İkinci Yarı Özeti
          Row(
            children: [
              Expanded(
                child: _buildHalfCard(
                  '1. YARI GOL İHTİMALİ',
                  '%${timing.firstHalfGoalProb.toStringAsFixed(1)}',
                  Icons.looks_one_rounded,
                  const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHalfCard(
                  '2. YARI GOL İHTİMALİ',
                  '%${timing.secondHalfGoalProb.toStringAsFixed(1)}',
                  Icons.looks_two_rounded,
                  const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 15 Dakikalık Grafikler
          const Text(
            'DAKİKA BAZLI GOL BASKISI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          for (int i = 0; i < intervals.length; i++) ...[
            _buildIntervalRow(
              interval: intervals[i],
              prob: timing.totalIntervals[i],
              homeProb: timing.homeIntervals[i],
              awayProb: timing.awayIntervals[i],
              isPeak: timing.peakInterval.startsWith(intervals[i]),
            ),
            if (i < intervals.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildHalfCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalRow({
    required String interval,
    required double prob,
    required double homeProb,
    required double awayProb,
    required bool isPeak,
  }) {
    // Oran maksimum ~50% varsayımıyla normalize
    final barFactor = (prob / 60.0).clamp(0.05, 1.0);

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '$interval\'',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
                  color: isPeak ? Colors.amber : Colors.white70,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 14,
                  color: Colors.white.withOpacity(0.05),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPeak
                              ? [Colors.amber, Colors.orangeAccent]
                              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 45,
              child: Text(
                '%${prob.toStringAsFixed(1)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPeak ? Colors.amber : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
