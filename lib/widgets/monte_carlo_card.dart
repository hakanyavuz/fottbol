import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/monte_carlo_simulation.dart';

/// 10.000 Maçlık Monte Carlo Simülasyon Kartı
class MonteCarloCard extends StatefulWidget {
  final double lambdaHome;
  final double lambdaAway;
  final String homeName;
  final String awayName;

  const MonteCarloCard({
    super.key,
    required this.lambdaHome,
    required this.lambdaAway,
    required this.homeName,
    required this.awayName,
  });

  @override
  State<MonteCarloCard> createState() => _MonteCarloCardState();
}

class _MonteCarloCardState extends State<MonteCarloCard> {
  late MonteCarloSimulation _simulation;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _simulation = MonteCarloSimulation.simulate(
      lambdaHome: widget.lambdaHome,
      lambdaAway: widget.lambdaAway,
      iterations: 10000,
    );
  }

  @override
  void didUpdateWidget(covariant MonteCarloCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lambdaHome != widget.lambdaHome || oldWidget.lambdaAway != widget.lambdaAway) {
      _runSimulation();
    }
  }

  void _runSimulation() {
    setState(() => _isSimulating = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _simulation = MonteCarloSimulation.simulate(
          lambdaHome: widget.lambdaHome,
          lambdaAway: widget.lambdaAway,
          iterations: 10000,
        );
        _isSimulating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.casino_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Monte Carlo Simülasyonu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                  tooltip: 'Yeniden 10.000 Kez Simüle Et',
                  onPressed: _isSimulating ? null : _runSimulation,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '10.000 Maç',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Matematiksel gol beklentisiyle bu maç 10.000 defa oynatılarak olası tüm senaryolar test edilmiştir.',
              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),

            if (_isSimulating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // 10.000 Simülasyon Dağılım Çubuğu
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      Expanded(
                        flex: _simulation.homeWins,
                        child: Container(color: AppColors.homeTeamColor),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: _simulation.draws,
                        child: Container(color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: _simulation.awayWins,
                        child: Container(color: AppColors.awayTeamColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Dağılım İstatistikleri
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.homeName}: %${_simulation.homeWinPercentage.toStringAsFixed(1)} (${_simulation.homeWins})',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Beraberlik: %${_simulation.drawPercentage.toStringAsFixed(1)} (${_simulation.draws})',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  Text(
                    '${widget.awayName}: %${_simulation.awayWinPercentage.toStringAsFixed(1)} (${_simulation.awayWins})',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),

              // En Sık Görülen Simülasyon Skorları
              const Text(
                'En Sık Gerçekleşen Simülasyon Skorları:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _simulation.mostFrequentScores.entries.map((entry) {
                  final pct = (entry.value / _simulation.totalSimulations) * 100;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${entry.key} (%${pct.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
