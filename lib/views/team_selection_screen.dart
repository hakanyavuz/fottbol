import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/team.dart';
import '../providers/match_prediction_provider.dart';
import 'comparison_screen.dart';
import 'prediction_screen.dart';
import 'team_stats_screen.dart';
import 'squad_screen.dart';
import 'country_list_screen.dart';
import 'global_team_search_screen.dart';
import 'custom_match_arena_screen.dart';
import '../widgets/popular_leagues_widget.dart';

import '../models/sport_type.dart';
import '../widgets/signal_ticker_widget.dart';

/// 1. Ekran: Takım Arama ve Ev Sahibi / Deplasman Seçim Ekranı
class TeamSelectionScreen extends StatelessWidget {
  const TeamSelectionScreen({super.key});

  void _showSportPicker(BuildContext context, MatchPredictionProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Spor Dalı Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...SportType.values.map((sport) => ListTile(
                  leading: Icon(sport.icon, color: AppColors.primary),
                  title: Text(sport.label),
                  trailing: provider.selectedSport == sport ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    provider.setSport(sport);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchPredictionProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.analystRank.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.premiumGold)),
              Text('${provider.analystPoints} Puan', style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
        title: InkWell(
          onTap: () => _showSportPicker(context, provider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${provider.selectedSport.emoji} ${provider.selectedSport.label.toUpperCase()}'),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalTeamSearchScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoadingTeams
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Sinyal Merkezi (YENİ)
                const SliverToBoxAdapter(
                  child: SignalTickerWidget(),
                ),

                // Üst Seçim Paneli
                SliverToBoxAdapter(
                  child: _SelectedMatchupHeader(provider: provider),
                ),

                // Hızlı Aksiyonlar (Özel Arena & 200+ Ülke)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _QuickActionCard(
                          title: 'Özel Arena',
                          subtitle: 'Simülasyon & Taktik',
                          icon: Icons.stadium_outlined,
                          color: Colors.cyanAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CustomMatchArenaScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          title: '200+ Ülke & Lig',
                          subtitle: 'Tüm Dünya Havuzu',
                          icon: Icons.public,
                          color: Colors.amberAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CountryListScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filtreler: Ülkeler
                SliverToBoxAdapter(
                  child: _CountryFilterList(provider: provider),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Popüler Ligler (Hızlı Kısayol)
                const SliverToBoxAdapter(child: PopularLeaguesWidget()),

                // Arama Kutusu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Takım ara...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => provider.searchTeams(val),
                    ),
                  ),
                ),

                // Takım Listesi
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final team = provider.filteredTeams[index];
                        return _TeamListTile(
                          team: team,
                          isHome: provider.homeTeam?.id == team.id,
                          isAway: provider.awayTeam?.id == team.id,
                          onSelectHome: () => provider.selectHomeTeam(team),
                          onSelectAway: () => provider.selectAwayTeam(team),
                          onViewStats: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TeamStatsScreen(team: team)),
                          ),
                          onViewSquad: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SquadScreen(team: team)),
                          ),
                        );
                      },
                      childCount: provider.filteredTeams.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      bottomSheet: _StickyBottomActions(provider: provider),
    );
  }
}

class _CountryFilterList extends StatelessWidget {
  final MatchPredictionProvider provider;
  const _CountryFilterList({required this.provider});

  static const countries = [
    {'name': 'Tümü', 'icon': '🌍', 'tr': 'Tümü'},
    {'name': 'Turkey', 'icon': '🇹🇷', 'tr': 'Türkiye'},
    {'name': 'England', 'icon': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'tr': 'İngiltere'},
    {'name': 'Spain', 'icon': '🇪🇸', 'tr': 'İspanya'},
    {'name': 'Germany', 'icon': '🇩🇪', 'tr': 'Almanya'},
    {'name': 'Italy', 'icon': '🇮🇹', 'tr': 'İtalya'},
    {'name': 'France', 'icon': '🇫🇷', 'tr': 'Fransa'},
    {'name': 'Netherlands', 'icon': '🇳🇱', 'tr': 'Hollanda'},
    {'name': 'Brazil', 'icon': '🇧🇷', 'tr': 'Brezilya'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ülkeler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              if (provider.selectedCountry != 'Tümü')
                TextButton(
                  onPressed: () => provider.setCountry('Tümü'),
                  child: const Text('Temizle', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final c = countries[index];
              final isSelected = provider.selectedCountry == c['name'];
              return GestureDetector(
                onTap: () => provider.setCountry(c['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c['icon']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        c['tr']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyBottomActions extends StatelessWidget {
  final MatchPredictionProvider provider;
  const _StickyBottomActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasSelection = provider.homeTeam != null && provider.awayTeam != null;
    if (!hasSelection) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.compare_arrows, color: AppColors.primary),
              label: const Text(
                'KARŞILAŞTIR',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComparisonScreen(
                      homeTeam: provider.homeTeam!,
                      awayTeam: provider.awayTeam!,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.auto_graph),
              onPressed: () async {
                final result = await provider.executePrediction();
                if (result != null && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictionScreen()));
                }
              },
              label: const Text('SKOR TAHMİNİ YAP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seçili Ev Sahibi vs Deplasman Karşılaşma Özeti
class _SelectedMatchupHeader extends StatelessWidget {
  final MatchPredictionProvider provider;

  const _SelectedMatchupHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final home = provider.homeTeam;
    final away = provider.awayTeam;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SelectedTeamInfo(team: home, label: 'EV SAHİBİ', color: AppColors.homeTeamColor),
          Column(
            children: [
              const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 24)),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: (home != null && away != null) ? () => provider.swapTeams() : null,
              ),
            ],
          ),
          _SelectedTeamInfo(team: away, label: 'DEPLASMAN', color: AppColors.awayTeamColor),
        ],
      ),
    );
  }
}

class _SelectedTeamInfo extends StatelessWidget {
  final Team? team;
  final String label;
  final Color color;

  const _SelectedTeamInfo({this.team, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.05),
            child: team != null
                ? Text(team!.initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                : const Icon(Icons.add, color: Colors.white38),
          ),
          const SizedBox(height: 8),
          Text(
            team?.name ?? 'Seçiniz',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Takım Liste Elemanı
class _TeamListTile extends StatelessWidget {
  final Team team;
  final bool isHome;
  final bool isAway;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectAway;
  final VoidCallback onViewStats;
  final VoidCallback onViewSquad;

  const _TeamListTile({
    required this.team,
    required this.isHome,
    required this.isAway,
    required this.onSelectHome,
    required this.onSelectAway,
    required this.onViewStats,
    required this.onViewSquad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Sol: Takım Logosu/Harfi
              Container(
                width: 60,
                color: AppColors.primary.withOpacity(0.1),
                child: Center(
                  child: team.crestUrl.isNotEmpty
                      ? Image.network(team.crestUrl, width: 32, height: 32, errorBuilder: (_, __, ___) => Text(team.initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))
                      : Text(team.initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              // Orta: İsim ve Bilgi
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(team.league, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              // Sağ: İşlem Butonları
              Row(
                children: [
                  _ActionButton(
                    label: 'EV',
                    isSelected: isHome,
                    color: AppColors.homeTeamColor,
                    onTap: onSelectHome,
                  ),
                  const VerticalDivider(width: 1, indent: 15, endIndent: 15),
                  _ActionButton(
                    label: 'DEP',
                    isSelected: isAway,
                    color: AppColors.awayTeamColor,
                    onTap: onSelectAway,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(onTap: onViewStats, child: const Row(children: [Icon(Icons.bar_chart, size: 18), SizedBox(width: 8), Text('İstatistikler')])),
                      PopupMenuItem(onTap: onViewSquad, child: const Row(children: [Icon(Icons.group, size: 18), SizedBox(width: 8), Text('Kadro')])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
