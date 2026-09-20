import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/prediction_result.dart';

/// Maçın tahmini skorunu ve 1X2 olasılıklarını stadyum skorbordu tarzında gösteren kart
class ScoreBoardCard extends StatelessWidget {
  final PredictionResult prediction;

  const ScoreBoardCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final home = prediction.homeTeam;
    final away = prediction.awayTeam;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.homeTeamColor.withOpacity(0.12),
              Colors.transparent,
              AppColors.awayTeamColor.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Lig & Durum Rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: const Text(
                '⚽ POISSON SKOR TAHMİNİ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Takımlar ve Skor Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Ev Sahibi Takım
                Expanded(
                  child: Column(
                    children: [
                      _TeamLogo(crestUrl: home.crestUrl, name: home.name),
                      const SizedBox(height: 8),
                      Text(
                        home.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'xG: ${prediction.lambdaHome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.homeTeamColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tahmin Edilen Skor Kutusu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${prediction.predictedHomeGoals}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        '${prediction.predictedAwayGoals}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Deplasman Takımı
                Expanded(
                  child: Column(
                    children: [
                      _TeamLogo(crestUrl: away.crestUrl, name: away.name),
                      const SizedBox(height: 8),
                      Text(
                        away.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'xG: ${prediction.lambdaAway.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.awayTeamColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // 1X2 Olasılık Dağılım Barları
            Row(
              children: [
                _ProbBox(
                  label: '1 (Ev Sahibi)',
                  prob: prediction.homeWinProbability,
                  color: AppColors.homeTeamColor,
                ),
                const SizedBox(width: 8),
                _ProbBox(
                  label: 'X (Beraberlik)',
                  prob: prediction.drawProbability,
                  color: AppColors.drawYellow,
                ),
                const SizedBox(width: 8),
                _ProbBox(
                  label: '2 (Deplasman)',
                  prob: prediction.awayWinProbability,
                  color: AppColors.awayTeamColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String crestUrl;
  final String name;

  const _TeamLogo({required this.crestUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (crestUrl.isNotEmpty) {
      return Image.network(
        crestUrl,
        width: 54,
        height: 54,
        errorBuilder: (_, __, ___) => _initialsAvatar(),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: 27,
      backgroundColor: Colors.blueGrey.withOpacity(0.2),
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProbBox extends StatelessWidget {
  final String label;
  final double prob;
  final Color color;

  const _ProbBox({
    required this.label,
    required this.prob,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '%${prob.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
