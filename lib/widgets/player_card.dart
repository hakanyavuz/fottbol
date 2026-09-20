import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/player.dart';

/// Oyuncu istatistik ve sakatlık durum kartı
class PlayerCard extends StatelessWidget {
  final Player player;

  /// null ise sakatlık simülasyonu bu ekranda kapalıdır
  /// (takım maçta ev/deplasman olarak seçili değil).
  final VoidCallback? onToggleInjury;

  const PlayerCard({
    super.key,
    required this.player,
    this.onToggleInjury,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Pozisyon İkonu / Rozeti
            CircleAvatar(
              backgroundColor: _getPositionColor(player.position).withOpacity(0.15),
              child: Text(
                player.position.isNotEmpty ? player.position.substring(0, 1) : '?',
                style: TextStyle(
                  color: _getPositionColor(player.position),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Oyuncu Adı ve İstatistikler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.isInjured) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lossRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.lossRed, width: 0.8),
                          ),
                          child: const Text(
                            'Sakat',
                            style: TextStyle(
                              color: AppColors.lossRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatChip(label: 'Gol', value: '${player.goals}'),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Asist', value: '${player.assists}'),
                      const SizedBox(width: 8),
                      // Reyting bilgisi olmayan kaynaklarda (football-data) 0 gelir
                      _StatChip(
                        label: 'Puan',
                        value: player.rating > 0 ? player.rating.toStringAsFixed(1) : '—',
                        isRating: true,
                      ),
                    ],
                  ),
                  if (player.isInjured && player.injuryReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      player.injuryReason!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Sakatlık Simülasyon Butonu
            IconButton(
              tooltip: onToggleInjury == null
                  ? 'Simülasyon için takımı EV/DEP olarak seçin'
                  : (player.isInjured ? 'Sakatlığı Kaldır' : 'Sakat Olarak İşaretle'),
              icon: Icon(
                player.isInjured ? Icons.medical_services : Icons.medical_services_outlined,
                color: player.isInjured ? AppColors.lossRed : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              onPressed: onToggleInjury,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'Forvet':
        return Colors.orangeAccent;
      case 'Orta Saha':
        return Colors.blueAccent;
      case 'Defans':
        return Colors.greenAccent;
      case 'Kaleci':
        return Colors.amber;
      default:
        return Colors.cyan;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isRating;

  const _StatChip({
    required this.label,
    required this.value,
    this.isRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRating ? Colors.amber : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
