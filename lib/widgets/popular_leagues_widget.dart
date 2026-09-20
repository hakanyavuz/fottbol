import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/season_utils.dart';
import '../models/league.dart';
import '../views/team_list_screen.dart';

/// Ana ekranda dünyaca ünlü popüler liglere tek tıkla doğrudan erişim kısayolu
class PopularLeaguesWidget extends StatelessWidget {
  const PopularLeaguesWidget({super.key});

  static final List<League> popularLeagues = [
    League(
      id: 39,
      name: 'Premier League',
      type: 'League',
      logo: 'https://media.api-sports.io/football/leagues/39.png',
      country: 'England',
      countryCode: 'GB',
      seasons: const [],
    ),
    League(
      id: 140,
      name: 'La Liga',
      type: 'League',
      logo: 'https://media.api-sports.io/football/leagues/140.png',
      country: 'Spain',
      countryCode: 'ES',
      seasons: const [],
    ),
    League(
      id: 203,
      name: 'Süper Lig',
      type: 'League',
      logo: 'https://media.api-sports.io/football/leagues/203.png',
      country: 'Turkey',
      countryCode: 'TR',
      seasons: const [],
    ),
    League(
      id: 135,
      name: 'Serie A',
      type: 'League',
      logo: 'https://media.api-sports.io/football/leagues/135.png',
      country: 'Italy',
      countryCode: 'IT',
      seasons: const [],
    ),
    League(
      id: 78,
      name: 'Bundesliga',
      type: 'League',
      logo: 'https://media.api-sports.io/football/leagues/78.png',
      country: 'Germany',
      countryCode: 'DE',
      seasons: const [],
    ),
    League(
      id: 2,
      name: 'Champions League',
      type: 'Cup',
      logo: 'https://media.api-sports.io/football/leagues/2.png',
      country: 'World',
      seasons: const [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 Popüler Ligler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                'Hızlı Seçim',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: popularLeagues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final league = popularLeagues[index];

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamListScreen(
                        league: league,
                        season: league.seasons.isNotEmpty
                            ? league.seasons.first
                            : SeasonUtils.currentSeason(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (league.logo.isNotEmpty)
                            Image.network(
                              league.logo,
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20),
                            )
                          else
                            const Icon(Icons.sports_soccer, size: 20, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              league.country,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        league.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
