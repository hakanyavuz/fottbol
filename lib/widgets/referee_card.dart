import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/referee_stat.dart';

/// Maçın resmi hakemi ve istatistiki kart / faul / penaltı eğilim kartı
class RefereeCard extends StatelessWidget {
  final RefereeStat referee;

  const RefereeCard({super.key, required this.referee});

  Color _getStrictnessColor(String rating) {
    if (rating.contains('Sert')) return Colors.redAccent.shade700;
    if (rating.contains('Müsamahakar')) return Colors.greenAccent.shade700;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strictColor = _getStrictnessColor(referee.strictnessRating);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maçın Resmi Hakemi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        referee.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: strictColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: strictColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    referee.strictnessRating,
                    style: TextStyle(
                      color: strictColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
            const SizedBox(height: 12),

            // 4 Temel Hakem Metriği: Sarı Kart, Kırmızı Kart, Faul, Penaltı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RefereeStatItem(
                  label: 'Sarı Kart',
                  value: referee.avgYellowCards.toStringAsFixed(1),
                  icon: Icons.square,
                  iconColor: Colors.amber,
                ),
                _RefereeStatItem(
                  label: 'Kırmızı Kart',
                  value: referee.avgRedCards.toStringAsFixed(2),
                  icon: Icons.square,
                  iconColor: Colors.redAccent,
                ),
                _RefereeStatItem(
                  label: 'Maç Başı Faul',
                  value: referee.avgFouls.toStringAsFixed(0),
                  icon: Icons.sports_kabaddi_outlined,
                  iconColor: Colors.orangeAccent,
                ),
                _RefereeStatItem(
                  label: 'Penaltı Sıklığı',
                  value: referee.avgPenalties.toStringAsFixed(2),
                  icon: Icons.sports_soccer,
                  iconColor: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hakemin 1X2 Yönetim Dağılımı (Ev Sahibi / Beraberlik / Deplasman)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: referee.homeWinPercentage.round(),
                      child: Container(color: AppColors.homeTeamColor),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: referee.drawPercentage.round(),
                      child: Container(color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: referee.awayWinPercentage.round(),
                      child: Container(color: AppColors.awayTeamColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ev Galibiyeti %${referee.homeWinPercentage.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Beraberlik %${referee.drawPercentage.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Deplasman %${referee.awayWinPercentage.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      referee.avgYellowCards >= 4.8
                          ? '🔥 Kart Bahsi Analizi: 4.5 Sarı Kart Üstü eğilimi yüksek (%${((referee.avgYellowCards / 6.0) * 100).clamp(50, 95).toStringAsFixed(0)} ihtimal).'
                          : (referee.avgYellowCards <= 4.0
                              ? '🛡️ Kart Bahsi Analizi: Hakem oyunu akıtır, 4.5 Kart Altı eğilimi ön planda.'
                              : '⚖️ Kart Bahsi Analizi: Lig ortalamasında kart eğilimi bekleniyor.'),
                      style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefereeStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _RefereeStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
