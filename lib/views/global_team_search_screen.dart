import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/api_team.dart';
import '../providers/global_football_providers.dart';
import '../widgets/api_team_tile.dart';
import '../widgets/search_bar_with_debounce.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/quota_warning_banner.dart';
import 'settings_screen.dart';
import 'team_picker.dart';

/// Ülke ve lig gezinmeden, dünyadaki herhangi bir takımı adıyla bulup
/// ev sahibi / deplasman olarak seçme ekranı (GET /teams?search=).
class GlobalTeamSearchScreen extends ConsumerStatefulWidget {
  const GlobalTeamSearchScreen({super.key});

  @override
  ConsumerState<GlobalTeamSearchScreen> createState() => _GlobalTeamSearchScreenState();
}

class _GlobalTeamSearchScreenState extends ConsumerState<GlobalTeamSearchScreen> {
  int? _busyTeamId;

  Future<void> _select(ApiTeam team, {required bool asHome}) async {
    setState(() => _busyTeamId = team.id);
    try {
      await pickApiTeam(
        context: context,
        ref: ref,
        apiTeam: team,
        asHome: asHome,
        season: ref.read(selectedSeasonProvider),
      );
    } finally {
      if (mounted) setState(() => _busyTeamId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(globalTeamSearchProvider);
    final query = ref.watch(globalTeamSearchQueryProvider);
    final hasKey = ref.watch(apiFootballServiceProvider).hasKey;

    return Scaffold(
      appBar: AppBar(title: const Text('🔎 Dünya Genelinde Takım Ara')),
      body: Column(
        children: [
          SearchBarWithDebounce(
            hintText: 'Takım adı yazın (Örn: Galatasaray, Boca, Al Hilal...)',
            initialValue: query,
            onChanged: (val) {
              ref.read(globalTeamSearchQueryProvider.notifier).state = val;
            },
          ),

          if (!hasKey) const _NoKeyBanner(),

          Expanded(
            child: resultsAsync.when(
              loading: () => const SkeletonLoadingList(itemCount: 6),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: QuotaWarningBanner(
                    message: err.toString(),
                    isUsingCache: false,
                    onRetry: () => ref.invalidate(globalTeamSearchProvider),
                  ),
                ),
              ),
              data: (teams) {
                if (query.trim().length < 3) {
                  return const _Hint(
                    icon: Icons.travel_explore,
                    text: 'Aramaya başlamak için en az 3 harf yazın.\n'
                        'Dünyadaki tüm liglerden takımlar listelenir.',
                  );
                }
                if (teams.isEmpty) {
                  return const _Hint(
                    icon: Icons.search_off,
                    text: 'Bu isimde takım bulunamadı.',
                  );
                }

                return ListView.builder(
                  itemCount: teams.length,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 4),
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return ApiTeamTile(
                      team: team,
                      subtitle: team.country,
                      isBusy: _busyTeamId == team.id,
                      onSelectAsHome: () => _select(team, asHome: true),
                      onSelectAsAway: () => _select(team, asHome: false),
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

class _NoKeyBanner extends StatelessWidget {
  const _NoKeyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_off, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Şu anda yalnızca birkaç demo takım aranabiliyor. Dünyadaki tüm takımlar için API-Football anahtarı gerekli.',
              style: TextStyle(fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('Ayarlar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
