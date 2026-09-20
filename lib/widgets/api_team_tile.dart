import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/api_team.dart';

/// API-Football takımını listeleyen ve EV / DEP olarak seçtiren ortak kart.
///
/// Seçim sırasında takımın gerçek istatistikleri ağdan çekildiği için
/// [isBusy] true iken butonlar yerine yükleniyor göstergesi gösterilir.
class ApiTeamTile extends StatelessWidget {
  final ApiTeam team;
  final String? subtitle;
  final bool isHome;
  final bool isAway;
  final bool isBusy;
  final VoidCallback onSelectAsHome;
  final VoidCallback onSelectAsAway;

  const ApiTeamTile({
    super.key,
    required this.team,
    required this.onSelectAsHome,
    required this.onSelectAsAway,
    this.subtitle,
    this.isHome = false,
    this.isAway = false,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final detail = subtitle ??
        (team.venueName != null
            ? '${team.venueName}${team.venueCity != null ? ', ${team.venueCity}' : ''}'
            : team.country);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (team.logo.isNotEmpty)
              Image.network(
                team.logo,
                width: 44,
                height: 44,
                errorBuilder: (_, __, ___) => _fallbackLogo(),
              )
            else
              _fallbackLogo(),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (isBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SelectButton(
                    label: 'EV',
                    color: AppColors.homeTeamColor,
                    selected: isHome,
                    onPressed: onSelectAsHome,
                  ),
                  const SizedBox(width: 6),
                  _SelectButton(
                    label: 'DEP',
                    color: AppColors.awayTeamColor,
                    selected: isAway,
                    onPressed: onSelectAsAway,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackLogo() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blueGrey.withValues(alpha: 0.15),
      child: Text(
        team.name.isNotEmpty ? team.name.substring(0, 1) : '⚽',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const _SelectButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : color.withValues(alpha: 0.15),
        foregroundColor: selected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        elevation: 0,
        minimumSize: const Size(42, 36),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
