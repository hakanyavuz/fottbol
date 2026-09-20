import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/league_constants.dart';
import '../models/fixture.dart';
import '../models/sport_type.dart';
import '../providers/match_prediction_provider.dart';
import '../services/api_football_service.dart';
import '../services/match_tracker_service.dart';
import 'live_analysis_screen.dart';

class LiveMatchesScreen extends StatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  State<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends State<LiveMatchesScreen> {
  SportType _selectedSport = SportType.soccer;
  String _selectedCountry = 'Tümü';
  String _selectedLeague = 'Tümü';
  Timer? _refreshTimer;
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshLive();
    });
    // Canlı maçları periyodik yenile
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _refreshLive();
    });
  }

  Future<void> _loadFavorites() async {
    final list = await MatchTrackerService.getTrackedFixtureIds();
    if (mounted) setState(() => _favoriteIds = list.toSet());
  }

  Future<void> _toggleFavorite(Fixture f) async {
    final isNow = await MatchTrackerService.toggleTrackFixture(f.id);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNow
            ? '⭐ ${f.homeTeamName} - ${f.awayTeamName} favorilere eklendi.'
            : '⚪ ${f.homeTeamName} - ${f.awayTeamName} favorilerden çıkarıldı.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshLive() {
    final provider = context.read<MatchPredictionProvider>();
    final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
    provider.loadLiveFixtures(apiService, provider.selectedLiveDate);
  }

  String _formatTurkishDate(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekdays = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${weekdays[dt.weekday - 1]}';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<Fixture> _getFilteredFixtures(List<Fixture> allLive) {
    return allLive.where((f) {
      final matchesSport = f.sportType == _selectedSport;
      if (_selectedLeague == '⭐ Favoriler') {
        return matchesSport && _favoriteIds.contains(f.id);
      }
      final matchesCountry = LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry);
      final matchesLeague = LeagueConstants.matchesLeague(f.leagueName, _selectedLeague);
      return matchesSport && matchesCountry && matchesLeague;
    }).toList();
  }

  void _showStandingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _StandingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchPredictionProvider>();
    final filtered = _getFilteredFixtures(provider.liveFixtures);

    // Seçili spora ve ülkeye ait tüm ligleri topla
    final leagueSet = <String>{};

    if (_selectedSport == SportType.soccer) {
      if (_selectedCountry != 'Tümü') {
        final known = LeagueConstants.countryLeaguesMap[_selectedCountry] ??
            LeagueConstants.countryLeaguesMap[_selectedCountry == 'Türkiye' ? 'Turkey' : _selectedCountry];
        if (known != null) {
          leagueSet.addAll(known);
        }
      } else {
        leagueSet.addAll([
          'Trendyol Süper Lig',
          'Premier League',
          'La Liga',
          'Serie A',
          'Bundesliga',
          'Ligue 1',
          'UEFA Şampiyonlar Ligi',
        ]);
      }
    } else if (_selectedSport == SportType.volleyball) {
      if (_selectedCountry.toLowerCase() == 'turkey' || _selectedCountry.toLowerCase() == 'türkiye') {
        leagueSet.addAll(['Sultanlar Ligi', 'Efeler Ligi']);
      } else if (_selectedCountry.toLowerCase() == 'italy' || _selectedCountry.toLowerCase() == 'italya') {
        leagueSet.add('Serie A1');
      } else if (_selectedCountry.toLowerCase() == 'world') {
        leagueSet.add('CEV Şampiyonlar Ligi');
      }
    } else if (_selectedSport == SportType.basketball) {
      if (_selectedCountry.toLowerCase() == 'turkey' || _selectedCountry.toLowerCase() == 'türkiye') {
        leagueSet.addAll(['Basketbol Süper Ligi', 'Türkiye Kupası']);
      } else if (_selectedCountry.toLowerCase() == 'usa' || _selectedCountry.toLowerCase() == 'abd') {
        leagueSet.add('NBA');
      } else if (_selectedCountry.toLowerCase() == 'world') {
        leagueSet.addAll(['EuroLeague', 'EuroCup']);
      }
    }

    // Ayrıca o günkü maçlarda yer alan diğer tüm ligleri de normalize ederek ekle (çift çip oluşmasını önler)
    for (final f in provider.liveFixtures) {
      if (f.sportType == _selectedSport) {
        if (LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry)) {
          final normalized = LeagueConstants.normalizeLeagueName(f.leagueName);
          if (!leagueSet.any((l) => LeagueConstants.matchesLeague(normalized, l))) {
            leagueSet.add(normalized);
          }
        }
      }
    }

    final availableLeagues = leagueSet.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 CANLI ANALİZ MERKEZİ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: Colors.amber),
            tooltip: 'Canlı Puan Durumu',
            onPressed: () => _showStandingsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoadingLive ? null : _refreshLive,
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.lastAlert != null)
            _buildLiveAlertBanner(provider.lastAlert!, () => provider.dismissAlert()),
          _buildLiveSourceBadge(),
          _buildDateSelectorBar(provider),
          _buildSportSelector(),
          _buildCountrySelector(provider.liveFixtures),
          if (availableLeagues.isNotEmpty)
            _buildLeagueSelector(['Tümü', ...availableLeagues], provider.liveFixtures),

          Expanded(
            child: provider.isLoadingLive && provider.liveFixtures.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(provider)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final fixture = filtered[index];
                          return _LiveFixtureTile(
                            fixture: fixture,
                            isFavorite: _favoriteIds.contains(fixture.id),
                            onToggleFavorite: () => _toggleFavorite(fixture),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorBar(MatchPredictionProvider provider) {
    final selectedDate = provider.selectedLiveDate;
    final isToday = _isToday(selectedDate);
    final dateFormatted = _formatTurkishDate(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ◀ Önceki Gün Butonu
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            tooltip: 'Önceki Gün',
            onPressed: () {
              final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
              provider.previousLiveDay(apiService);
            },
          ),

          // Ortada Takvim & Tarih Seçici
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.black,
                        surface: Color(0xFF1E293B),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && mounted) {
                final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                provider.setLiveDate(picked, apiService);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isToday
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: isToday ? AppColors.primary : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white54),
                  if (isToday) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BUGÜN',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Eğer bugün değilse "Bugün" butonu göster, yanında sonraki gün
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isToday)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.today, size: 14, color: AppColors.primary),
                    label: const Text(
                      'Bugün',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                      provider.resetLiveDateToToday(apiService);
                    },
                  ),
                ),

              // ▶ Sonraki Gün Butonu
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                tooltip: 'Sonraki Gün',
                onPressed: () {
                  final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                  provider.nextLiveDay(apiService);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.6),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: SportType.values.map((sport) {
            final isSelected = _selectedSport == sport;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text('${sport.emoji} ${sport.label}',
                    style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.2),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSport = sport;
                      _selectedCountry = 'Tümü';
                      _selectedLeague = 'Tümü';
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCountrySelector(List<Fixture> liveFixtures) {
    final countryList = <Map<String, String>>[
      {'name': 'Tümü', 'icon': '🌍', 'tr': 'Tümü'},
    ];

    if (_selectedSport == SportType.soccer) {
      countryList.addAll([
        {'name': 'Turkey', 'icon': '🇹🇷', 'tr': 'Türkiye'},
        {'name': 'England', 'icon': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'tr': 'İngiltere'},
        {'name': 'Spain', 'icon': '🇪🇸', 'tr': 'İspanya'},
        {'name': 'Italy', 'icon': '🇮🇹', 'tr': 'İtalya'},
        {'name': 'Germany', 'icon': '🇩🇪', 'tr': 'Almanya'},
        {'name': 'France', 'icon': '🇫🇷', 'tr': 'Fransa'},
        {'name': 'Netherlands', 'icon': '🇳🇱', 'tr': 'Hollanda'},
        {'name': 'Portugal', 'icon': '🇵🇹', 'tr': 'Portekiz'},
        {'name': 'Brazil', 'icon': '🇧🇷', 'tr': 'Brezilya'},
        {'name': 'World', 'icon': '🌐', 'tr': 'Avrupa / UEFA'},
      ]);
    } else if (_selectedSport == SportType.volleyball) {
      countryList.addAll([
        {'name': 'Turkey', 'icon': '🇹🇷', 'tr': 'Türkiye'},
        {'name': 'Italy', 'icon': '🇮🇹', 'tr': 'İtalya'},
        {'name': 'World', 'icon': '🌐', 'tr': 'Avrupa (CEV)'},
      ]);
    } else if (_selectedSport == SportType.basketball) {
      countryList.addAll([
        {'name': 'Turkey', 'icon': '🇹🇷', 'tr': 'Türkiye (BSL)'},
        {'name': 'USA', 'icon': '🇺🇸', 'tr': 'ABD (NBA)'},
        {'name': 'World', 'icon': '🌐', 'tr': 'EuroLeague'},
      ]);
    }

    return Container(
      height: 46,
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.4)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: countryList.length,
        itemBuilder: (context, index) {
          final c = countryList[index];
          final isSelected = _selectedCountry == c['name'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${c['icon']} ${c['tr'] ?? c['name']}',
                  style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _selectedCountry = c['name']!;
                _selectedLeague = 'Tümü';
              }),
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeagueSelector(List<String> leagues, List<Fixture> liveFixtures) {
    final favCount = _favoriteIds.isEmpty
        ? 0
        : liveFixtures.where((f) => f.sportType == _selectedSport && _favoriteIds.contains(f.id)).length;

    // Favoriler çipini Tümü'nün hemen sağına yerleştir
    final allTabs = <String>[
      'Tümü',
      '⭐ Favoriler',
      ...leagues.where((l) => l != 'Tümü'),
    ];

    return Container(
      height: 42,
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.2)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: allTabs.length,
        itemBuilder: (context, index) {
          final tab = allTabs[index];
          final isSelected = _selectedLeague == tab;

          final String labelText;
          if (tab == '⭐ Favoriler') {
            labelText = '⭐ Favoriler ($favCount)';
          } else if (tab == 'Tümü') {
            final matchCount = liveFixtures.where((f) {
              final matchesSport = f.sportType == _selectedSport;
              final matchesCountry = LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry);
              return matchesSport && matchesCountry;
            }).length;
            labelText = 'Tümü ($matchCount)';
          } else {
            final matchCount = liveFixtures.where((f) {
              final matchesSport = f.sportType == _selectedSport;
              final matchesCountry = LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry);
              final matchesLeague = LeagueConstants.matchesLeague(f.leagueName, tab);
              return matchesSport && matchesCountry && matchesLeague;
            }).length;
            labelText = '$tab ($matchCount)';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(labelText, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedLeague = tab),
              selectedColor: Colors.amber.withOpacity(0.2),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.amber : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(MatchPredictionProvider provider) {
    final hasFilter = _selectedCountry != 'Tümü' || _selectedLeague != 'Tümü';
    final dateFormatted = _formatTurkishDate(provider.selectedLiveDate);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_outlined,
                size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? '${_selectedLeague != 'Tümü' ? _selectedLeague : _selectedCountry} liginde seçili tarihte ($dateFormatted) maç bulunamadı.'
                  : 'Seçili tarihte ($dateFormatted) kayıtlı maç bulunmuyor.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                  label: const Text('Önceki Gün'),
                  onPressed: () {
                    final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                    provider.previousLiveDay(apiService);
                  },
                ),
                const SizedBox(width: 8),
                if (hasFilter)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Tüm Maçları Göster'),
                    onPressed: () {
                      setState(() {
                        _selectedCountry = 'Tümü';
                        _selectedLeague = 'Tümü';
                      });
                    },
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('Sonraki Gün'),
                  onPressed: () {
                    final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                    provider.nextLiveDay(apiService);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSourceBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.green.withOpacity(0.08),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, color: Colors.greenAccent, size: 14),
          SizedBox(width: 6),
          Text(
            'GERÇEK CANLI VERİ (Kadro, Kartlar ve Sakatlıklar Aktif)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAlertBanner(MatchLiveAlert alert, VoidCallback onDismiss) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.isRedCard ? Colors.red.withOpacity(0.18) : Colors.green.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.isRedCard ? Colors.redAccent : Colors.greenAccent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(alert.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: alert.isRedCard ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _LiveFixtureTile extends StatelessWidget {
  final Fixture fixture;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _LiveFixtureTile({
    required this.fixture,
    this.isFavorite = false,
    required this.onToggleFavorite,
  });

  Widget _buildLiveRadarBar(Fixture fixture) {
    if (!fixture.isLive && fixture.elapsed == null) return const SizedBox.shrink();

    final minute = fixture.elapsed ?? 45;
    final basePressure = 45 + (minute * 0.4).clamp(0, 35).toInt();
    final redBoost = (fixture.homeRedCards + fixture.awayRedCards) * 8;
    final totalPressure = (basePressure + redBoost).clamp(30, 96);

    Color barColor;
    String statusText;
    if (totalPressure >= 75) {
      barColor = Colors.deepOrangeAccent;
      statusText = '🔥 Yüksek Gol Baskısı';
    } else if (totalPressure >= 60) {
      barColor = Colors.amber;
      statusText = '⚡ Hareketli Oyun';
    } else {
      barColor = Colors.cyan;
      statusText = '⚖️ Kontrollü Tempo';
    }

    final isLateGame = minute >= 75;

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: barColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: barColor.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar_rounded, size: 14, color: barColor),
                      const SizedBox(width: 5),
                      Text(
                        'Canlı Radar: $statusText',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Baskı: %$totalPressure',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: totalPressure / 100.0,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              if (isLateGame || fixture.homeRedCards > 0 || fixture.awayRedCards > 0) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (isLateGame)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purple.withOpacity(0.4)),
                        ),
                        child: const Text(
                          '⏱️ 75+ Son Düzlük',
                          style: TextStyle(fontSize: 9.5, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (fixture.homeRedCards > 0 || fixture.awayRedCards > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: const Text(
                          '⚠️ 10 Kişi Avantaj/Baskı',
                          style: TextStyle(fontSize: 9.5, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LiveAnalysisScreen(fixture: fixture))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFavorite ? Colors.amber : Colors.white38,
                          size: 20,
                        ),
                        tooltip: isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                        onPressed: onToggleFavorite,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 6),
                      if (fixture.leagueLogo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Image.network(
                            fixture.leagueLogo,
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      Text(
                        '${fixture.leagueName} ${fixture.leagueCountry.isNotEmpty && fixture.leagueCountry != 'World' ? '• ${fixture.leagueCountry}' : ''}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (fixture.isLive ? Colors.red : Colors.grey.shade800).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (fixture.isLive ? Colors.red : Colors.white24).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fixture.isLive) ...[
                          const Icon(Icons.circle, color: Colors.red, size: 7),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          fixture.statusLabel,
                          style: TextStyle(
                              color: fixture.isLive ? Colors.red : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (fixture.homeRedCards > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🟥 ${fixture.homeRedCards}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (fixture.homeYellowCards > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text('🟨${fixture.homeYellowCards}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                        Flexible(
                          child: Text(
                            fixture.homeTeamName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (fixture.homeTeamLogo.isNotEmpty)
                          Image.network(
                            fixture.homeTeamLogo,
                            width: 26,
                            height: 26,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 13,
                              child: Text(fixture.homeTeamName.isNotEmpty
                                  ? fixture.homeTeamName[0]
                                  : ''),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 13,
                            child: Text(fixture.homeTeamName.isNotEmpty
                                ? fixture.homeTeamName[0]
                                : ''),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${fixture.homeGoals ?? 0} - ${fixture.awayGoals ?? 0}',
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        if (fixture.awayTeamLogo.isNotEmpty)
                          Image.network(
                            fixture.awayTeamLogo,
                            width: 26,
                            height: 26,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 13,
                              child: Text(fixture.awayTeamName.isNotEmpty
                                  ? fixture.awayTeamName[0]
                                  : ''),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 13,
                            child: Text(fixture.awayTeamName.isNotEmpty
                                ? fixture.awayTeamName[0]
                                : ''),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            fixture.awayTeamName,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (fixture.awayYellowCards > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('🟨${fixture.awayYellowCards}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                        if (fixture.awayRedCards > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🟥 ${fixture.awayRedCards}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLiveRadarBar(fixture),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fixture.venueName ??
                        (fixture.referee != null
                            ? 'Hakem: ${fixture.referee}'
                            : ''),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_graph, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Anlık Analiz & Olasılıklar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
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

class _StandingItem {
  final int rank;
  final String team;
  final int played;
  final int won;
  final int draw;
  final int lost;
  final int goalDiff;
  final int points;
  final List<String> form;

  const _StandingItem({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalDiff,
    required this.points,
    this.form = const ['G', 'G', 'B'],
  });
}

class _StandingsBottomSheet extends StatefulWidget {
  const _StandingsBottomSheet();

  @override
  State<_StandingsBottomSheet> createState() => _StandingsBottomSheetState();
}

class _StandingsBottomSheetState extends State<_StandingsBottomSheet> {
  String _selectedLeague = 'Trendyol Süper Lig';

  static const Map<String, List<_StandingItem>> _leagueStandings = {
    'Trendyol Süper Lig': [
      _StandingItem(rank: 1, team: 'Galatasaray', played: 24, won: 20, draw: 3, lost: 1, goalDiff: 42, points: 63, form: ['G', 'G', 'G', 'B', 'G']),
      _StandingItem(rank: 2, team: 'Fenerbahçe', played: 24, won: 19, draw: 4, lost: 1, goalDiff: 38, points: 61, form: ['G', 'G', 'B', 'G', 'G']),
      _StandingItem(rank: 3, team: 'Samsunspor', played: 24, won: 14, draw: 4, lost: 6, goalDiff: 14, points: 46, form: ['G', 'B', 'G', 'M', 'G']),
      _StandingItem(rank: 4, team: 'Beşiktaş', played: 24, won: 12, draw: 7, lost: 5, goalDiff: 12, points: 43, form: ['B', 'G', 'B', 'G', 'M']),
      _StandingItem(rank: 5, team: 'Eyüpspor', played: 24, won: 12, draw: 6, lost: 6, goalDiff: 9, points: 42, form: ['G', 'M', 'G', 'G', 'B']),
      _StandingItem(rank: 6, team: 'Trabzonspor', played: 24, won: 10, draw: 8, lost: 6, goalDiff: 8, points: 38, form: ['G', 'B', 'M', 'G', 'G']),
      _StandingItem(rank: 7, team: 'Göztepe', played: 24, won: 10, draw: 6, lost: 8, goalDiff: 7, points: 36, form: ['M', 'G', 'G', 'B', 'M']),
      _StandingItem(rank: 8, team: 'Başakşehir', played: 24, won: 9, draw: 7, lost: 8, goalDiff: 3, points: 34, form: ['B', 'B', 'G', 'M', 'G']),
      _StandingItem(rank: 9, team: 'Kasımpaşa', played: 24, won: 8, draw: 9, lost: 7, goalDiff: 0, points: 33, form: ['G', 'B', 'M', 'B', 'G']),
      _StandingItem(rank: 10, team: 'Sivasspor', played: 24, won: 8, draw: 5, lost: 11, goalDiff: -6, points: 29, form: ['M', 'G', 'M', 'M', 'G']),
      _StandingItem(rank: 11, team: 'Antalyaspor', played: 24, won: 8, draw: 5, lost: 11, goalDiff: -8, points: 29, form: ['M', 'M', 'G', 'G', 'M']),
      _StandingItem(rank: 12, team: 'Konyaspor', played: 24, won: 7, draw: 6, lost: 11, goalDiff: -9, points: 27, form: ['B', 'M', 'M', 'G', 'B']),
      _StandingItem(rank: 13, team: 'Çaykur Rizespor', played: 24, won: 7, draw: 5, lost: 12, goalDiff: -10, points: 26, form: ['M', 'M', 'G', 'M', 'M']),
      _StandingItem(rank: 14, team: 'Alanyaspor', played: 24, won: 6, draw: 7, lost: 11, goalDiff: -11, points: 25, form: ['B', 'G', 'M', 'B', 'M']),
      _StandingItem(rank: 15, team: 'Gaziantep FK', played: 24, won: 6, draw: 6, lost: 12, goalDiff: -12, points: 24, form: ['M', 'B', 'M', 'G', 'M']),
      _StandingItem(rank: 16, team: 'Bodrum FK', played: 24, won: 5, draw: 4, lost: 15, goalDiff: -16, points: 19, form: ['M', 'M', 'M', 'B', 'M']),
      _StandingItem(rank: 17, team: 'Kayserispor', played: 24, won: 4, draw: 7, lost: 13, goalDiff: -18, points: 19, form: ['B', 'M', 'B', 'M', 'M']),
      _StandingItem(rank: 18, team: 'Hatayspor', played: 24, won: 3, draw: 6, lost: 15, goalDiff: -20, points: 15, form: ['M', 'B', 'M', 'M', 'M']),
      _StandingItem(rank: 19, team: 'Adana Demirspor', played: 24, won: 1, draw: 3, lost: 20, goalDiff: -35, points: 6, form: ['M', 'M', 'M', 'M', 'M']),
    ],
    'Trendyol 1. Lig': [
      _StandingItem(rank: 1, team: 'Kocaelispor', played: 24, won: 15, draw: 4, lost: 5, goalDiff: 18, points: 49, form: ['G', 'G', 'B', 'G', 'M']),
      _StandingItem(rank: 2, team: 'Fatih Karagümrük', played: 24, won: 13, draw: 6, lost: 5, goalDiff: 14, points: 45, form: ['G', 'B', 'G', 'G', 'B']),
      _StandingItem(rank: 3, team: 'Gençlerbirliği', played: 24, won: 13, draw: 5, lost: 6, goalDiff: 12, points: 44, form: ['G', 'G', 'M', 'G', 'B']),
      _StandingItem(rank: 4, team: 'Bandırmaspor', played: 24, won: 12, draw: 6, lost: 6, goalDiff: 10, points: 42, form: ['B', 'G', 'G', 'M', 'G']),
      _StandingItem(rank: 5, team: 'İstanbulspor', played: 24, won: 11, draw: 7, lost: 6, goalDiff: 9, points: 40, form: ['G', 'B', 'B', 'G', 'M']),
      _StandingItem(rank: 6, team: 'Erzurumspor FK', played: 24, won: 11, draw: 6, lost: 7, goalDiff: 8, points: 39, form: ['G', 'M', 'G', 'B', 'G']),
      _StandingItem(rank: 7, team: 'Amed SF', played: 24, won: 10, draw: 7, lost: 7, goalDiff: 6, points: 37, form: ['B', 'G', 'M', 'G', 'B']),
      _StandingItem(rank: 8, team: 'Ankaragücü', played: 24, won: 10, draw: 5, lost: 9, goalDiff: 4, points: 35, form: ['M', 'G', 'B', 'M', 'G']),
      _StandingItem(rank: 9, team: 'Çorum FK', played: 24, won: 9, draw: 7, lost: 8, goalDiff: 2, points: 34, form: ['B', 'B', 'G', 'M', 'G']),
      _StandingItem(rank: 10, team: 'Sakaryaspor', played: 24, won: 8, draw: 8, lost: 8, goalDiff: 0, points: 32, form: ['M', 'B', 'G', 'G', 'M']),
      _StandingItem(rank: 11, team: 'Boluspor', played: 24, won: 8, draw: 7, lost: 9, goalDiff: -2, points: 31, form: ['B', 'M', 'M', 'G', 'B']),
      _StandingItem(rank: 12, team: 'Ümraniyespor', played: 24, won: 8, draw: 6, lost: 10, goalDiff: -4, points: 30, form: ['M', 'G', 'M', 'B', 'M']),
    ],
    'Premier League': [
      _StandingItem(rank: 1, team: 'Liverpool', played: 25, won: 18, draw: 4, lost: 3, goalDiff: 34, points: 58, form: ['G', 'G', 'B', 'G', 'G']),
      _StandingItem(rank: 2, team: 'Arsenal', played: 25, won: 16, draw: 6, lost: 3, goalDiff: 29, points: 54, form: ['G', 'B', 'G', 'G', 'B']),
      _StandingItem(rank: 3, team: 'Manchester City', played: 25, won: 15, draw: 5, lost: 5, goalDiff: 27, points: 50, form: ['B', 'G', 'M', 'G', 'G']),
      _StandingItem(rank: 4, team: 'Chelsea', played: 25, won: 13, draw: 6, lost: 6, goalDiff: 18, points: 45, form: ['G', 'M', 'G', 'B', 'G']),
      _StandingItem(rank: 5, team: 'Newcastle United', played: 25, won: 12, draw: 6, lost: 7, goalDiff: 14, points: 42, form: ['G', 'G', 'B', 'M', 'G']),
      _StandingItem(rank: 6, team: 'Aston Villa', played: 25, won: 11, draw: 5, lost: 9, goalDiff: 6, points: 38, form: ['M', 'G', 'G', 'B', 'M']),
      _StandingItem(rank: 7, team: 'Tottenham', played: 25, won: 11, draw: 4, lost: 10, goalDiff: 12, points: 37, form: ['M', 'M', 'G', 'G', 'M']),
    ],
    'La Liga': [
      _StandingItem(rank: 1, team: 'Real Madrid', played: 24, won: 16, draw: 6, lost: 2, goalDiff: 31, points: 54, form: ['G', 'B', 'G', 'G', 'G']),
      _StandingItem(rank: 2, team: 'Barcelona', played: 24, won: 17, draw: 2, lost: 5, goalDiff: 36, points: 53, form: ['G', 'G', 'M', 'G', 'G']),
      _StandingItem(rank: 3, team: 'Atletico Madrid', played: 24, won: 15, draw: 6, lost: 3, goalDiff: 22, points: 51, form: ['G', 'G', 'B', 'G', 'M']),
      _StandingItem(rank: 4, team: 'Athletic Club', played: 24, won: 12, draw: 6, lost: 6, goalDiff: 15, points: 42, form: ['B', 'G', 'G', 'B', 'G']),
      _StandingItem(rank: 5, team: 'Villarreal', played: 24, won: 11, draw: 7, lost: 6, goalDiff: 8, points: 40, form: ['G', 'B', 'M', 'G', 'B']),
    ],
    'Serie A': [
      _StandingItem(rank: 1, team: 'Napoli', played: 25, won: 18, draw: 4, lost: 3, goalDiff: 26, points: 58, form: ['G', 'G', 'B', 'G', 'G']),
      _StandingItem(rank: 2, team: 'Inter', played: 25, won: 17, draw: 5, lost: 3, goalDiff: 35, points: 56, form: ['G', 'G', 'G', 'B', 'G']),
      _StandingItem(rank: 3, team: 'Atalanta', played: 25, won: 16, draw: 4, lost: 5, goalDiff: 30, points: 52, form: ['G', 'B', 'G', 'G', 'M']),
      _StandingItem(rank: 4, team: 'Juventus', played: 25, won: 12, draw: 11, lost: 2, goalDiff: 21, points: 47, form: ['B', 'G', 'B', 'G', 'B']),
      _StandingItem(rank: 5, team: 'Lazio', played: 25, won: 14, draw: 4, lost: 7, goalDiff: 15, points: 46, form: ['G', 'M', 'G', 'G', 'M']),
    ],
    'Bundesliga': [
      _StandingItem(rank: 1, team: 'Bayern München', played: 22, won: 17, draw: 3, lost: 2, goalDiff: 41, points: 54, form: ['G', 'G', 'G', 'B', 'G']),
      _StandingItem(rank: 2, team: 'Bayer Leverkusen', played: 22, won: 14, draw: 6, lost: 2, goalDiff: 24, points: 48, form: ['B', 'G', 'G', 'G', 'B']),
      _StandingItem(rank: 3, team: 'Eintracht Frankfurt', played: 22, won: 12, draw: 5, lost: 5, goalDiff: 16, points: 41, form: ['G', 'B', 'G', 'M', 'G']),
      _StandingItem(rank: 4, team: 'RB Leipzig', played: 22, won: 11, draw: 5, lost: 6, goalDiff: 11, points: 38, form: ['M', 'G', 'B', 'G', 'G']),
      _StandingItem(rank: 5, team: 'Borussia Dortmund', played: 22, won: 10, draw: 4, lost: 8, goalDiff: 6, points: 34, form: ['G', 'M', 'M', 'G', 'B']),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _leagueStandings[_selectedLeague] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Tutamak
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'CANLI PUAN DURUMU',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Lig Seçici Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: _leagueStandings.keys.map((league) {
                final isSelected = league == _selectedLeague;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      league,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    onSelected: (_) => setState(() => _selectedLeague = league),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Tablo Başlığı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withOpacity(0.04),
            child: const Row(
              children: [
                SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Takım', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                SizedBox(width: 28, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                SizedBox(width: 28, child: Text('G', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                SizedBox(width: 28, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                SizedBox(width: 28, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                SizedBox(width: 32, child: Text('AV', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                SizedBox(width: 34, child: Text('P', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber))),
              ],
            ),
          ),
          // Tablo İçeriği
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
              itemBuilder: (context, index) {
                final it = items[index];
                Color rankColor = Colors.white70;
                if (it.rank <= 2) {
                  rankColor = Colors.greenAccent;
                } else if (it.rank <= 4) {
                  rankColor = Colors.lightBlueAccent;
                } else if (it.rank >= items.length - 2) {
                  rankColor = Colors.redAccent;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${it.rank}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          it.team,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 28, child: Text('${it.played}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                      SizedBox(width: 28, child: Text('${it.won}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                      SizedBox(width: 28, child: Text('${it.draw}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                      SizedBox(width: 28, child: Text('${it.lost}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                      SizedBox(
                        width: 32,
                        child: Text(
                          it.goalDiff > 0 ? '+${it.goalDiff}' : '${it.goalDiff}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: it.goalDiff >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${it.points}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bilgi / Lejant
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text('Şampiyonlar / Üst Lig', style: TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.lightBlueAccent, size: 8),
                    SizedBox(width: 4),
                    Text('Avrupa Kupaları', style: TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.redAccent, size: 8),
                    SizedBox(width: 4),
                    Text('Düşme Hattı', style: TextStyle(fontSize: 10, color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
