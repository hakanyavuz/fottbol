import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../core/constants/app_colors.dart';
import '../models/api_team.dart';
import '../models/league.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';
import '../widgets/api_team_tile.dart';
import '../widgets/search_bar_with_debounce.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/quota_warning_banner.dart';
import 'league_fixtures_view.dart';
import 'settings_screen.dart';
import 'team_picker.dart';

/// 3. Aşama: Lig detay ekranı — "Maçlar" (fikstür + tahmin) ve "Takımlar" sekmeleri.
///
/// Anahtar varsa varsayılan sekme maç programıdır; yoksa (çevrimdışı demo)
/// fikstür verisi olmadığı için takımlar sekmesi açılır.
class TeamListScreen extends ConsumerWidget {
  final League league;
  final int season;

  const TeamListScreen({
    super.key,
    required this.league,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = LeagueSeasonParams(leagueId: league.id, season: season);

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(league.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
              onPressed: () {
                ref.invalidate(teamsByLeagueProvider(params));
                ref.invalidate(upcomingFixturesProvider(params));
                ref.invalidate(recentFixturesProvider(params));
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.event_note, size: 20), text: 'Maçlar'),
              Tab(icon: Icon(Icons.groups_2_outlined, size: 20), text: 'Takımlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LeagueFixturesView(league: league, season: season),
            _LeagueTeamsView(league: league, season: season),
          ],
        ),
      ),
    );
  }
}

/// Ligin takımları; takım gerçek istatistikleriyle EV / DEP olarak seçilir
class _LeagueTeamsView extends ConsumerStatefulWidget {
  final League league;
  final int season;

  const _LeagueTeamsView({required this.league, required this.season});

  @override
  ConsumerState<_LeagueTeamsView> createState() => _LeagueTeamsViewState();
}

class _LeagueTeamsViewState extends ConsumerState<_LeagueTeamsView> {
  int? _busyTeamId;

  /// Takımı gerçek sezon istatistikleri, kadrosu ve sakatlıklarıyla seçer
  Future<void> _select(ApiTeam team, {required bool asHome}) async {
    setState(() => _busyTeamId = team.id);
    try {
      await pickApiTeam(
        context: context,
        ref: ref,
        apiTeam: team,
        asHome: asHome,
        season: widget.season,
        leagueId: widget.league.id,
        leagueName: widget.league.name,
      );
    } finally {
      if (mounted) setState(() => _busyTeamId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = LeagueSeasonParams(leagueId: widget.league.id, season: widget.season);
    final teamsAsync = ref.watch(teamsByLeagueProvider(params));
    final predProvider = context.watch<MatchPredictionProvider>();
    final hasKey = ref.watch(apiFootballServiceProvider).hasKey;

    return Column(
      children: [
        // Lig Bilgi Başlığı
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              if (widget.league.logo.isNotEmpty)
                Image.network(
                  widget.league.logo,
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer),
                )
              else
                const Icon(Icons.sports_soccer, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.league.country} • ${widget.season} Sezonu',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      widget.league.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Arama Çubuğu
        SearchBarWithDebounce(
          hintText: 'Bu ligde takım ara...',
          initialValue: ref.read(teamSearchQueryProvider),
          onChanged: (val) {
            ref.read(teamSearchQueryProvider.notifier).state = val;
          },
        ),

        // Takım Listesi
        Expanded(
          child: teamsAsync.when(
            loading: () => const SkeletonLoadingList(itemCount: 8),
            error: (err, stack) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: QuotaWarningBanner(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(teamsByLeagueProvider(params)),
                  ),
                ),
              );
            },
            data: (teams) {
              if (teams.isEmpty) {
                return _EmptyLeague(hasKey: hasKey, season: widget.season);
              }

              return ListView.builder(
                itemCount: teams.length,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                itemBuilder: (context, index) {
                  final apiTeam = teams[index];

                  return ApiTeamTile(
                    team: apiTeam,
                    isHome: predProvider.homeTeam?.id == apiTeam.id.toString(),
                    isAway: predProvider.awayTeam?.id == apiTeam.id.toString(),
                    isBusy: _busyTeamId == apiTeam.id,
                    onSelectAsHome: () => _select(apiTeam, asHome: true),
                    onSelectAsAway: () => _select(apiTeam, asHome: false),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Ligde takım bulunamadığında gösterilen bilgilendirme
class _EmptyLeague extends StatelessWidget {
  final bool hasKey;
  final int season;

  const _EmptyLeague({required this.hasKey, required this.season});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasKey ? Icons.calendar_month_outlined : Icons.public_off,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              hasKey
                  ? '$season sezonu için bu ligde takım bulunamadı.\nÜst ekrandan farklı bir sezon seçmeyi deneyin.'
                  : 'Bu lig çevrimdışı demo veri setinde yok.\nTüm dünya liglerinin takımları için API-Football anahtarı gerekli.',
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
