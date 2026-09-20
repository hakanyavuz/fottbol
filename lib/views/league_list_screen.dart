import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/season_utils.dart';
import '../models/country.dart';
import '../providers/global_football_providers.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/quota_warning_banner.dart';
import 'settings_screen.dart';
import 'team_list_screen.dart';

/// 2. Aşama: Seçilen Ülkenin Lig ve Kupalarını Listeleme Ekranı
class LeagueListScreen extends ConsumerWidget {
  final Country country;

  const LeagueListScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(leaguesByCountryProvider(country.name));
    final selectedType = ref.watch(leagueTypeFilterProvider);
    final selectedSeason = ref.watch(selectedSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${country.name} Ligleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(leaguesByCountryProvider(country.name)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler (Tür: Tümü/Lig/Kupa ve Sezon Seçici)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Tür Filtre Çipleri
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tümü', 'League', 'Cup'].map((type) {
                        final isSelected = selectedType == type;
                        final label = type == 'League'
                            ? 'Ligler'
                            : type == 'Cup'
                                ? 'Kupalar'
                                : 'Tümü';

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              ref.read(leagueTypeFilterProvider.notifier).state = type;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sezon Seçim Menüsü
                DropdownButton<int>(
                  value: selectedSeason,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: SeasonUtils.recentSeasons().map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (year) {
                    if (year != null) {
                      ref.read(selectedSeasonProvider.notifier).state = year;
                    }
                  },
                ),
              ],
            ),
          ),

          // Lig Listesi
          Expanded(
            child: leaguesAsync.when(
              loading: () => const SkeletonLoadingList(itemCount: 8),
              error: (err, stack) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: QuotaWarningBanner(
                      message: err.toString(),
                      onRetry: () => ref.invalidate(leaguesByCountryProvider(country.name)),
                    ),
                  ),
                );
              },
              data: (leagues) {
                if (leagues.isEmpty) {
                  return _EmptyLeagues(
                    hasKey: ref.watch(apiFootballServiceProvider).hasKey,
                    season: selectedSeason,
                  );
                }

                return ListView.separated(
                  itemCount: leagues.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final league = leagues[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: league.logo.isNotEmpty
                          ? Image.network(
                              league.logo,
                              width: 36,
                              height: 36,
                              errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer),
                            )
                          : const Icon(Icons.sports_soccer, color: AppColors.primary),
                      title: Text(
                        league.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: league.isCup
                                  ? Colors.purple.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              league.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: league.isCup ? Colors.purpleAccent : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Sezon: $selectedSeason', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () {
                        ref.read(selectedLeagueProvider.notifier).state = league;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamListScreen(
                              league: league,
                              season: selectedSeason,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ülkede lig bulunamadığında gösterilen bilgilendirme
class _EmptyLeagues extends StatelessWidget {
  final bool hasKey;
  final int season;

  const _EmptyLeagues({required this.hasKey, required this.season});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasKey ? Icons.filter_alt_off : Icons.public_off,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              hasKey
                  ? '$season sezonunda bu kriterde lig veya kupa bulunamadı.'
                  : 'Bu ülkenin ligleri çevrimdışı demo veri setinde yok.\nDünyadaki tüm ligler ve kupalar için API-Football anahtarı gerekli.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            if (!hasKey) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Anahtar Ekle'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
