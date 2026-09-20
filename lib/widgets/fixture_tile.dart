import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/fixture.dart';

/// Fikstür listesindeki tek bir maç kartı.
///
/// Oynanmamış maçlarda "Tahmin Et" butonu, bitmiş maçlarda skor gösterilir.
class FixtureTile extends StatelessWidget {
  final Fixture fixture;
  final bool isBusy;
  final VoidCallback? onPredict;

  const FixtureTile({
    super.key,
    required this.fixture,
    this.isBusy = false,
    this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    final date = fixture.date;
    final timeText = date != null ? DateFormat('HH:mm').format(date) : '--:--';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Saat / durum sütunu
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(
                    fixture.isUpcoming ? timeText : fixture.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: fixture.isLive
                          ? AppColors.lossRed
                          : fixture.isCancelled
                              ? Colors.orange
                              : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (fixture.round.isNotEmpty)
                    Text(
                      _shortRound(fixture.round),
                      style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Takımlar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamRow(
                    name: fixture.homeTeamName,
                    logo: fixture.homeTeamLogo,
                    goals: fixture.hasScore ? fixture.homeGoals : null,
                    isWinner: fixture.isFinished &&
                        fixture.hasScore &&
                        fixture.homeGoals! > fixture.awayGoals!,
                  ),
                  const SizedBox(height: 6),
                  _TeamRow(
                    name: fixture.awayTeamName,
                    logo: fixture.awayTeamLogo,
                    goals: fixture.hasScore ? fixture.awayGoals : null,
                    isWinner: fixture.isFinished &&
                        fixture.hasScore &&
                        fixture.awayGoals! > fixture.homeGoals!,
                  ),
                ],
              ),
            ),

            // Eylem
            if (fixture.isUpcoming) ...[
              const SizedBox(width: 8),
              if (isBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.auto_graph, size: 16),
                  label: const Text('Tahmin', style: TextStyle(fontSize: 12)),
                  onPressed: onPredict,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Regular Season - 5" -> "5. Hafta"
  static String _shortRound(String round) {
    final match = RegExp(r'Regular Season - (\d+)').firstMatch(round);
    if (match != null) return '${match.group(1)}. Hafta';
    return round;
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final String logo;
  final int? goals;
  final bool isWinner;

  const _TeamRow({
    required this.name,
    required this.logo,
    required this.goals,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (logo.isNotEmpty)
          Image.network(
            logo,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 18),
          )
        else
          const Icon(Icons.shield_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        if (goals != null)
          Text(
            '$goals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
