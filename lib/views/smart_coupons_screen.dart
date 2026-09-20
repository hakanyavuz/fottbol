import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../core/constants/app_colors.dart';
import '../services/match_tracker_service.dart';
import '../core/constants/league_constants.dart';
import '../models/basketball_match.dart';
import '../models/coupon_slip.dart';
import '../models/fixture.dart';
import '../models/odds_comparison.dart';
import '../models/prediction_result.dart';
import '../models/sport_type.dart';
import '../models/volleyball_match.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';
import '../services/basketball_engine.dart';
import '../services/gemini_analysis_service.dart';
import '../services/poisson_engine.dart';
import '../services/real_sports_live_service.dart';
import '../services/storage_service.dart';
import '../services/volleyball_engine.dart';
import '../services/weather_service.dart';
import '../widgets/smart_coupon_wizard_card.dart';
import 'prediction_screen.dart';

/// Günün Akıllı Kuponları & Değerli Bahisler Ekranı (Çoklu Spor, Canlı Hava Durumu ve Tarih Filtreli)
class SmartCouponsScreen extends ConsumerStatefulWidget {
  const SmartCouponsScreen({super.key});

  @override
  ConsumerState<SmartCouponsScreen> createState() => _SmartCouponsScreenState();
}

class _SmartCouponsScreenState extends ConsumerState<SmartCouponsScreen> {
  bool _isLoading = true;
  bool _showHistoryView = false;
  SportType _selectedSport = SportType.soccer;
  String _selectedCountry = 'Turkey'; // Varsayılan Türkiye
  String _selectedLeague = 'Tümü'; // Varsayılan tüm ligler
  List<CouponSlip> _slips = [];
  List<CouponSlip> _savedCoupons = [];
  List<Fixture> _allDateFixtures = [];
  List<Fixture> _dayFixtures = [];
  List<String> _availableLeagues = [];

  Map<int, PredictionResult> _footballPredictions = {};
  Map<int, VolleyballPrediction> _volleyballPredictions = {};
  Map<int, BasketballPrediction> _basketballPredictions = {};
  Map<int, LiveWeatherData> _weatherByFixtureId = {};

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAndGenerateCoupons();
    });
  }

  void _onSportSelected(SportType sport) {
    if (_selectedSport == sport) return;
    setState(() {
      _selectedSport = sport;
      _selectedCountry = 'Tümü';
      _selectedLeague = 'Tümü';
    });
    _loadAndGenerateCoupons();
  }

  void _onCountrySelected(String country) {
    if (_selectedCountry == country) return;
    setState(() {
      _selectedCountry = country;
      _selectedLeague = 'Tümü'; // Ülke değişince ligi sıfırla
    });
    _loadAndGenerateCoupons();
  }

  void _onLeagueSelected(String league) {
    if (_selectedLeague == league) return;
    setState(() {
      _selectedLeague = league;
    });
    _loadAndGenerateCoupons();
  }

  void _changeDate(int dayDelta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: dayDelta));
    });
    _loadAndGenerateCoupons();
  }

  void _setDate(DateTime newDate) {
    setState(() {
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
    });
    _loadAndGenerateCoupons();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('tr', 'TR'),
      helpText: 'MAÇ TARİHİ SEÇİN',
      cancelText: 'İPTAL',
      confirmText: 'SEÇ',
    );
    if (picked != null) {
      _setDate(picked);
    }
  }

  Future<void> _loadAndGenerateCoupons({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _dayFixtures = [];
      _slips = [];
    });

    try {
      final multiSport = ref.read(multiSportServiceProvider);
      final footballService = ref.read(apiFootballServiceProvider);
      final geminiKey = p.Provider.of<MatchPredictionProvider>(context, listen: false).geminiApiKey;

      // Seçilen spor dalı ve tarihteki tüm maçları çek
      List<Fixture> allDateFixtures = [];
      if (_selectedSport == SportType.soccer) {
        allDateFixtures = await RealSportsLiveService.getLiveFixtures(date: _selectedDate);
      }
      if (allDateFixtures.isEmpty) {
        allDateFixtures = await multiSport.getMatchesByDate(
          sport: _selectedSport,
          date: _selectedDate,
          forceRefresh: forceRefresh,
        ).timeout(const Duration(seconds: 15));
      }
      _allDateFixtures = allDateFixtures;

      // Sadece seçili güne ve ÜLKEYE ait maçları filtrele
      final matching = allDateFixtures.where((f) {
        if (f.date == null) return false;
        
        final sameDate = f.date!.year == _selectedDate.year &&
            f.date!.month == _selectedDate.month &&
            f.date!.day == _selectedDate.day;
            
        if (!sameDate) return false;
        
        if (!LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry)) {
          return false;
        }

        if (!LeagueConstants.matchesLeague(f.leagueName, _selectedLeague)) {
          return false;
        }
        
        return true;
      }).toList();

      // Seçili ülkeye ait tüm ligleri eksiksiz göster
      final standardCountryLeagues = _selectedCountry == 'Tümü'
          ? <String>[]
          : (LeagueConstants.countryLeaguesMap[_selectedCountry] ?? <String>[]);

      final fixtureLeagues = allDateFixtures
          .where((f) => LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry))
          .map((f) => f.leagueName)
          .toSet();

      final combinedLeagues = <String>{
        ...standardCountryLeagues,
        ...fixtureLeagues,
      }.toList();

      _availableLeagues = ['Tümü', ...combinedLeagues];

      matching.sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));

      _dayFixtures = matching;
      _footballPredictions = {};
      _volleyballPredictions = {};
      _basketballPredictions = {};
      _weatherByFixtureId = {};

      if (matching.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (_selectedSport == SportType.soccer) {
        // --- ⚽ FUTBOL MOTORU + CANLI HAVA DURUMU ---
        final fPreds = <PredictionResult>[];
        
        // Çok fazla maç varsa performansı korumak için ilk 10 tanesini işle
        final limitedMatching = matching.take(10).toList();

        for (final f in limitedMatching) {
          try {
            final teams = await footballService.buildTeamsForFixture(f).timeout(const Duration(seconds: 4));

            // Open-Meteo Canlı Stadyum Hava Durumu (Ücretsiz & Anlık)
            final weather = await WeatherService.getLiveWeather(f.venueName ?? f.homeTeamName).timeout(const Duration(seconds: 2));
            _weatherByFixtureId[f.id] = weather;

            final pred = PoissonEngine.calculatePrediction(
              homeTeam: teams.home,
              awayTeam: teams.away,
              fixtureId: f.id,
              matchDate: f.date,
              referee: f.referee,
              weatherCondition: weather.toWeatherCondition,
            );

            final odds = footballService.simulateMarketOdds(lambdaHome: pred.lambdaHome, lambdaAway: pred.lambdaAway);
            pred.oddsComparison = OddsComparison.fromModelAndOdds(
              odds: odds,
              modelHomeProb: pred.homeWinProbability,
              modelDrawProb: pred.drawProbability,
              modelAwayProb: pred.awayWinProbability,
            );

            fPreds.add(pred);
            _footballPredictions[f.id] = pred;
          } catch (e) {
            debugPrint('Maç analiz hatası (${f.homeTeamName}): $e');
            continue;
          }
        }
        
        final generatedSlips = CouponSlip.generateSlips(fPreds);
        
        final updatedSlips = <CouponSlip>[];
        for (var slip in generatedSlips) {
          // İlk kupona AI yorumu alalım
          if (updatedSlips.isEmpty && geminiKey.isNotEmpty) {
            try {
              final analysis = await GeminiAnalysisService.analyzeCoupon(slip: slip, apiKey: geminiKey).timeout(const Duration(seconds: 8));
              updatedSlips.add(slip.copyWith(aiAnalysis: analysis));
            } catch (_) {
              updatedSlips.add(slip);
            }
          } else {
            updatedSlips.add(slip);
          }
        }
        _slips = updatedSlips;
        for (final slip in updatedSlips) {
          await StorageService.saveCoupon(slip);
        }
      } else if (_selectedSport == SportType.volleyball) {
        // --- 🏐 VOLEYBOL MOTORU (SULTANLAR LİGİ, EFELER, CEV) ---
        final vPreds = <VolleyballPrediction>[];
        for (final f in matching) {
          final home = VolleyballTeam(
            id: f.homeTeamId,
            name: f.homeTeamName,
            logo: f.homeTeamLogo,
            league: f.leagueName,
            attackEfficiency: 48.0,
            blockPerSet: 2.5,
            acePerSet: 1.4,
            receptionQuality: 52.0,
          );
          final away = VolleyballTeam(
            id: f.awayTeamId,
            name: f.awayTeamName,
            logo: f.awayTeamLogo,
            league: f.leagueName,
            attackEfficiency: 45.0,
            blockPerSet: 2.1,
            acePerSet: 1.1,
            receptionQuality: 49.0,
          );

          final pred = VolleyballEngine.calculatePrediction(
            homeTeam: home,
            awayTeam: away,
            matchDate: f.date ?? _selectedDate,
            leagueName: f.leagueName,
          );
          vPreds.add(pred);
          _volleyballPredictions[f.id] = pred;
        }
        final vSlips = CouponSlip.generateVolleyballSlips(vPreds);
        if (vSlips.isNotEmpty && geminiKey.isNotEmpty) {
          final analysis = await GeminiAnalysisService.analyzeCoupon(slip: vSlips.first, apiKey: geminiKey);
          _slips = [vSlips.first.copyWith(aiAnalysis: analysis)];
        } else {
          _slips = vSlips;
        }
        for (final slip in _slips) {
          await StorageService.saveCoupon(slip);
        }
      } else if (_selectedSport == SportType.basketball) {
        // --- 🏀 BASKETBOL MOTORU (NBA, EUROLEAGUE, BSL) ---
        final bPreds = <BasketballPrediction>[];
        for (final f in matching) {
          final home = BasketballTeam(
            id: f.homeTeamId,
            name: f.homeTeamName,
            logo: f.homeTeamLogo,
            league: f.leagueName,
            pace: 72.5,
            offensiveRating: 114.0,
            defensiveRating: 108.0,
            threePointPercentage: 37.0,
          );
          final away = BasketballTeam(
            id: f.awayTeamId,
            name: f.awayTeamName,
            logo: f.awayTeamLogo,
            league: f.leagueName,
            pace: 71.0,
            offensiveRating: 110.0,
            defensiveRating: 111.0,
            threePointPercentage: 35.5,
          );

          final pred = BasketballEngine.calculatePrediction(
            homeTeam: home,
            awayTeam: away,
            matchDate: f.date ?? _selectedDate,
            leagueName: f.leagueName,
          );
          bPreds.add(pred);
          _basketballPredictions[f.id] = pred;
        }
        final bSlips = CouponSlip.generateBasketballSlips(bPreds);
        if (bSlips.isNotEmpty && geminiKey.isNotEmpty) {
          final analysis = await GeminiAnalysisService.analyzeCoupon(slip: bSlips.first, apiKey: geminiKey);
          _slips = [bSlips.first.copyWith(aiAnalysis: analysis)];
        } else {
          _slips = bSlips;
        }
        for (final slip in _slips) {
          await StorageService.saveCoupon(slip);
        }
      } else {
        _slips = [];
      }
    } catch (_) {
      _dayFixtures = [];
      _slips = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekdays = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    final dayStr = '${date.day} ${months[date.month - 1]} ${date.year}';
    final weekDay = weekdays[date.weekday - 1];
    return '$dayStr, $weekDay';
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(apiFootballKeyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showHistoryView ? '📜 Kayıtlı Kuponlarım' : '🏆 Akıllı Kupon & Çoklu Spor'),
        actions: [
          IconButton(
            icon: Icon(
              _showHistoryView ? Icons.smart_toy_outlined : Icons.receipt_long,
              color: _showHistoryView ? AppColors.primary : Colors.amber,
            ),
            tooltip: _showHistoryView ? 'Günün Kuponlarına Dön' : 'Geçmiş / Kayıtlı Kuponlar',
            onPressed: () async {
              if (!_showHistoryView) {
                final saved = await StorageService.getSavedCoupons();
                setState(() {
                  _savedCoupons = saved;
                  _showHistoryView = true;
                });
              } else {
                setState(() => _showHistoryView = false);
              }
            },
          ),
          if (!_showHistoryView && !_isToday)
            TextButton.icon(
              onPressed: () {
                final now = DateTime.now();
                _setDate(DateTime(now.year, now.month, now.day));
              },
              icon: const Icon(Icons.today, size: 18, color: AppColors.primary),
              label: const Text('Bugün', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          if (!_showHistoryView)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
              onPressed: _isLoading ? null : () => _loadAndGenerateCoupons(forceRefresh: true),
            ),
        ],
      ),
      body: _showHistoryView
          ? _buildSavedCouponsView()
          : Column(
              children: [
                // 1. Spor Dalı Seçici Sekmesi
                _buildSportSelector(),

                // 1b. Ülke Filtresi
                _buildCountrySelector(),

                // 1c. Lig Filtresi
                if (_availableLeagues.isNotEmpty) _buildLeagueSelector(),

                // 2. Tarih Gezinme Çubuğu
                _buildDateNavigator(context),

                // 3. İçerik Alanı
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                '${_selectedSport.emoji} ${_selectedSport.label} ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year} maçları analiz ediliyor...',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadAndGenerateCoupons(forceRefresh: true),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: _buildContent(context, hasKey),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSportSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: SportType.values.map((sport) {
            final isSelected = _selectedSport == sport;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  '${sport.emoji} ${sport.label}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.25),
                onSelected: (selected) {
                  if (selected) _onSportSelected(sport);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    final countries = [
      {'name': 'Tümü', 'icon': '🌍', 'label': 'Tüm Ülkeler'},
      {'name': 'Turkey', 'icon': '🇹🇷', 'label': 'Türkiye'},
      {'name': 'England', 'icon': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'label': 'İngiltere'},
      {'name': 'Spain', 'icon': '🇪🇸', 'label': 'İspanya'},
      {'name': 'Germany', 'icon': '🇩🇪', 'label': 'Almanya'},
      {'name': 'Italy', 'icon': '🇮🇹', 'label': 'İtalya'},
      {'name': 'France', 'icon': '🇫🇷', 'label': 'Fransa'},
      {'name': 'Netherlands', 'icon': '🇳🇱', 'label': 'Hollanda'},
      {'name': 'Portugal', 'icon': '🇵🇹', 'label': 'Portekiz'},
      {'name': 'Brazil', 'icon': '🇧🇷', 'label': 'Brezilya'},
      {'name': 'World', 'icon': '🌐', 'label': 'Uluslararası / UEFA'},
    ];

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final c = countries[index];
          final isSelected = _selectedCountry == c['name'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${c['icon']} ${c['label']}', style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (_) => _onCountrySelected(c['name']!),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : null, 
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeagueSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.2),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _availableLeagues.length,
        itemBuilder: (context, index) {
          final league = _availableLeagues[index];
          final isSelected = _selectedLeague == league;
          
          final int count = league == 'Tümü'
              ? _allDateFixtures.where((f) => LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry)).length
              : _allDateFixtures.where((f) => 
                  LeagueConstants.countryMatches(f.leagueCountry, _selectedCountry) && 
                  LeagueConstants.matchesLeague(f.leagueName, league)).length;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$league ($count)', style: const TextStyle(fontSize: 10.5)),
              selected: isSelected,
              onSelected: (_) => _onLeagueSelected(league),
              selectedColor: Colors.amber.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.amber : (count > 0 ? null : Colors.grey), 
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateNavigator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Önceki Gün',
            onPressed: _isLoading ? null : () => _changeDate(-1),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bugün',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Sonraki Gün',
            onPressed: _isLoading ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool hasKey) {
    if (_dayFixtures.isEmpty) {
      return _buildEmptyState(context, hasKey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Akıllı Kupon Kartları
        SmartCouponWizardCard(
          slips: _slips,
          onItemTap: (item) {
            if (item.prediction != null) {
              final provider = p.Provider.of<MatchPredictionProvider>(context, listen: false);
              provider.selectHomeTeam(item.prediction!.homeTeam);
              provider.selectAwayTeam(item.prediction!.awayTeam);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PredictionScreen(historyItem: item.prediction),
                ),
              );
            } else {
              _showSportItemDetails(context, item);
            }
          },
        ),

        const SizedBox(height: 24),

        // O gün oynanacak maçların listesi
        Row(
          children: [
            Icon(_selectedSport.icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '${_selectedSport.label} Karşılaşmaları (${_dayFixtures.length} Maç)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Seçili tarihteki tüm ${_selectedSport.label.toLowerCase()} maçları ve model analizleri:',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        ..._dayFixtures.map((fixture) {
          final fPred = _footballPredictions[fixture.id];
          final vPred = _volleyballPredictions[fixture.id];
          final bPred = _basketballPredictions[fixture.id];
          final weather = _weatherByFixtureId[fixture.id];

          return _MultiSportFixtureCard(
            fixture: fixture,
            footballPred: fPred,
            volleyballPred: vPred,
            basketballPred: bPred,
            weather: weather,
            onTap: () {
              if (fPred != null) {
                final provider = p.Provider.of<MatchPredictionProvider>(context, listen: false);
                provider.selectHomeTeam(fPred.homeTeam);
                provider.selectAwayTeam(fPred.awayTeam);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PredictionScreen(historyItem: fPred),
                  ),
                );
              } else if (vPred != null) {
                _showVolleyballDetails(context, vPred);
              } else if (bPred != null) {
                _showBasketballDetails(context, bPred);
              }
            },
          );
        }),
      ],
    );
  }

  void _showSportItemDetails(BuildContext context, CouponItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.sportEmoji} ${item.matchTitle}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(item.leagueName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(height: 24),
            Text('Önerilen Tercih: ${item.selectionLabel}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Model Güven Skoru: %${item.confidenceScore.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVolleyballDetails(BuildContext context, VolleyballPrediction pred) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🏐 VOLEYBOL PROJEKSİYONU', style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(
                      '${pred.matchDate.day.toString().padLeft(2, '0')}.${pred.matchDate.month.toString().padLeft(2, '0')}.${pred.matchDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${pred.homeTeam.name} vs ${pred.awayTeam.name}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${pred.leagueName} • ${pred.homeTeam.venue}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
                const Divider(height: 24, color: Colors.white12),

                // Galibiyet İhtimalleri & En Olası Set Skoru
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Ev Sahibi', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('%${pred.homeWinProbability.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Column(
                        children: [
                          const Text('En Olası Set', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(pred.mostLikelySetScore, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Column(
                        children: [
                          Text('Deplasman', style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('%${pred.awayWinProbability.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Set Skoru Olasılık Dağılımı (Set Probability Distribution)
                const Text(
                  '📊 Set Skoru Olasılık Dağılımı (Monte Carlo Simülasyonu)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pred.setScoreProbabilities.entries.map((entry) {
                    final isMostLikely = entry.key == pred.mostLikelySetScore;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMostLikely ? AppColors.primary.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMostLikely ? AppColors.primary : Colors.white10,
                          width: isMostLikely ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isMostLikely ? AppColors.primary : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '%${entry.value.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isMostLikely ? Colors.white : Colors.white60,
                              fontWeight: isMostLikely ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Toplam Sayı & Set Baremleri
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Toplam Sayı Baremi:', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '${pred.totalPointsThreshold} Sayı (Üst: %${pred.overProbability} / Alt: %${pred.underProbability})',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('3.5 Set Üstü (Min 4 Set):', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '%${pred.over35SetsProbability.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('4.5 Set Üstü (Tie-Break):', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '%${pred.over45SetsProbability.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Taktik Anlatım
                Text(
                  pred.tacticalSummary,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),

                // Google Calendar Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available_rounded, size: 18, color: Colors.amber),
                    label: const Text(
                      '📅 Takvime Hatırlatıcı Ekle (Google Calendar)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final url = MatchTrackerService.generateGoogleCalendarUrl(
                        matchTitle: '${pred.homeTeam.name} vs ${pred.awayTeam.name}',
                        matchDate: pred.matchDate,
                        venue: pred.homeTeam.venue,
                        league: pred.leagueName,
                      );
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📅 Google Takvim hatırlatıcı linki panoya kopyalandı!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBasketballDetails(BuildContext context, BasketballPrediction pred) {
    // 4 Çeyrek Projeksiyonu (Pace ve hücum verimliliği ağırlıklı dağılım)
    final q1Home = (pred.expectedHomeScore * 0.24).round();
    final q1Away = (pred.expectedAwayScore * 0.24).round();
    final q2Home = (pred.expectedHomeScore * 0.26).round();
    final q2Away = (pred.expectedAwayScore * 0.26).round();
    final q3Home = (pred.expectedHomeScore * 0.24).round();
    final q3Away = (pred.expectedAwayScore * 0.24).round();
    final q4Home = (pred.expectedHomeScore * 0.26).round();
    final q4Away = (pred.expectedAwayScore * 0.26).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🏀 BASKETBOL QUANT PROJEKSİYONU', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(
                      '${pred.matchDate.day.toString().padLeft(2, '0')}.${pred.matchDate.month.toString().padLeft(2, '0')}.${pred.matchDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${pred.homeTeam.name} vs ${pred.awayTeam.name}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${pred.leagueName} • ${pred.homeTeam.venue}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
                const Divider(height: 24, color: Colors.white12),

                // Galibiyet İhtimalleri & Beklenen Skor
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Ev Sahibi', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('%${pred.homeWinProbability.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Column(
                        children: [
                          const Text('Beklenen Skor', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${pred.expectedHomeScore.round()} - ${pred.expectedAwayScore.round()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Column(
                        children: [
                          Text('Deplasman', style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('%${pred.awayWinProbability.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4-Çeyrek Skor Projeksiyonu
                const Text(
                  '⏱️ 4-Çeyrek Skor Projeksiyonu (Pace Dağılımı)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildQuarterCard('1. Çeyrek', q1Home, q1Away)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildQuarterCard('2. Çeyrek', q2Home, q2Away)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildQuarterCard('3. Çeyrek', q3Home, q3Away)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildQuarterCard('4. Çeyrek', q4Home, q4Away)),
                  ],
                ),
                const SizedBox(height: 16),

                // Baremler ve Dinlenme Durumu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Toplam Sayı Baremi:', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '${pred.totalPointsThreshold} (Üst: %${pred.overProbability} / Alt: %${pred.underProbability})',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Önerilen Handikap:', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '${pred.suggestedHandicap >= 0 ? "+" : ""}${pred.suggestedHandicap}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dinlenme Günleri (Ev / Dep):', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                          Text(
                            '${pred.homeTeam.restDays} gün / ${pred.awayTeam.restDays} gün',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Taktik Anlatım
                Text(
                  pred.tacticalSummary,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),

                // Google Calendar Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available_rounded, size: 18, color: Colors.amber),
                    label: const Text(
                      '📅 Takvime Hatırlatıcı Ekle (Google Calendar)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final url = MatchTrackerService.generateGoogleCalendarUrl(
                        matchTitle: '${pred.homeTeam.name} vs ${pred.awayTeam.name}',
                        matchDate: pred.matchDate,
                        venue: pred.homeTeam.venue,
                        league: pred.leagueName,
                      );
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📅 Google Takvim hatırlatıcı linki panoya kopyalandı!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuarterCard(String label, int home, int away) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            '$home - $away',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            '${home + away} sayı',
            style: const TextStyle(color: Colors.amber, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasKey) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year} Tarihinde ${_selectedSport.label} Maçı Bulunamadı',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seçilen tarihte resmi bir karşılaşma planlanmamış olabilir. İleri/Geri butonlarıyla başka bir güne geçebilirsiniz.',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Önceki Gün'),
                ),
                if (!_isToday)
                  ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      _setDate(DateTime(now.year, now.month, now.day));
                    },
                    icon: const Icon(Icons.today),
                    label: const Text('Bugüne Git'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Sonraki Gün'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponStatusBadge(CouponSlip slip) {
    Color color;
    String text;
    IconData icon;
    switch (slip.status) {
      case 'winning':
        color = Colors.greenAccent;
        text = 'KAZANDI';
        icon = Icons.check_circle;
        break;
      case 'lost':
        color = Colors.redAccent;
        text = 'KAYBETTİ';
        icon = Icons.cancel;
        break;
      case 'partial':
        color = Colors.orangeAccent;
        text = 'DEVAM EDİYOR';
        icon = Icons.timelapse;
        break;
      default:
        color = Colors.blueAccent;
        text = 'BEKLİYOR';
        icon = Icons.schedule;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSavedCouponsView() {
    if (_savedCoupons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Henüz Kayıtlı Kupon Bulunmuyor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Günün maçlarını inceleyip oluşturulan akıllı kuponlar otomatik olarak buraya arşivlenir. Ayrıca maç sonuçları netleştikçe kuponlarınızın kazanma durumu canlı olarak takip edilir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showHistoryView = false),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Günün Kuponlarına Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final saved = await StorageService.getSavedCoupons();
        if (mounted) setState(() => _savedCoupons = saved);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedCoupons.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kayıtlı Kupon Geçmişi (${_savedCoupons.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Tüm Kuponları Sil?'),
                          content: const Text('Kayıtlı tüm geçmiş kuponlar cihaz hafızasından silinecektir.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await StorageService.clearSavedCoupons();
                        setState(() => _savedCoupons = []);
                      }
                    },
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                    label: const Text('Tümünü Temizle', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            );
          }

          final slip = _savedCoupons[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slip.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${slip.date.day}.${slip.date.month}.${slip.date.year} • ${slip.category}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      _buildCouponStatusBadge(slip),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        tooltip: 'Kuponu Sil',
                        onPressed: () async {
                          await StorageService.deleteCoupon(slip.id);
                          setState(() {
                            _savedCoupons.removeAt(index - 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Toplam Oran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              slip.totalOdds.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Güven Endeksi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              '%${slip.combinedConfidenceScore.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Maç Sayısı', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              '${slip.items.length}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...slip.items.map((it) {
                    IconData itemIcon;
                    Color itemColor;
                    if (it.isWon == true) {
                      itemIcon = Icons.check_circle;
                      itemColor = Colors.greenAccent;
                    } else if (it.isWon == false) {
                      itemIcon = Icons.cancel;
                      itemColor = Colors.redAccent;
                    } else {
                      itemIcon = Icons.schedule;
                      itemColor = Colors.grey;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(it.sportEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.matchTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('${it.leagueName} • ${it.selectionLabel}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              it.odds.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(itemIcon, size: 16, color: itemColor),
                        ],
                      ),
                    );
                  }),
                  if (slip.aiAnalysis != null && slip.aiAnalysis!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slip.aiAnalysis!,
                              style: const TextStyle(fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MultiSportFixtureCard extends StatelessWidget {
  final Fixture fixture;
  final PredictionResult? footballPred;
  final VolleyballPrediction? volleyballPred;
  final BasketballPrediction? basketballPred;
  final LiveWeatherData? weather;
  final VoidCallback onTap;

  const _MultiSportFixtureCard({
    required this.fixture,
    this.footballPred,
    this.volleyballPred,
    this.basketballPred,
    this.weather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = fixture.date != null
        ? '${fixture.date!.hour.toString().padLeft(2, '0')}:${fixture.date!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Lig, Saat & Canlı Hava Durumu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${fixture.sportType.emoji} ${fixture.leagueName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (weather != null) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${weather!.emoji} ${weather!.temperature.toStringAsFixed(0)}°C',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Takımlar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fixture.homeTeamName,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: fixture.isFinished && (fixture.homeGoals ?? 0) > (fixture.awayGoals ?? 0) ? Colors.greenAccent : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: fixture.isFinished ? Colors.green.withOpacity(0.1) : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: fixture.isFinished ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
                      ),
                      child: Text(
                        fixture.isFinished || fixture.isLive
                            ? '${fixture.homeGoals ?? 0} - ${fixture.awayGoals ?? 0}'
                            : (fixture.statusShort == 'NS' && fixture.date != null && DateTime.now().isAfter(fixture.date!) ? 'Oynanıyor' : 'vs'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: fixture.isFinished ? Colors.greenAccent : (fixture.isLive ? Colors.redAccent : null),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fixture.awayTeamName,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: fixture.isFinished && (fixture.awayGoals ?? 0) > (fixture.homeGoals ?? 0) ? Colors.greenAccent : null,
                      ),
                    ),
                  ),
                ],
              ),

              // Spor Dalına Göre Tahmin Satırı
              if (footballPred != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('1: %${footballPred!.homeWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.homeTeamColor, fontWeight: FontWeight.w600)),
                    Text('X: %${footballPred!.drawProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.drawYellow, fontWeight: FontWeight.w600)),
                    Text('2: %${footballPred!.awayWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.awayTeamColor, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('Detay', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ] else if (volleyballPred != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Ev: %${volleyballPred!.homeWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.homeTeamColor, fontWeight: FontWeight.w600)),
                    Text('Set: ${volleyballPred!.mostLikelySetScore}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Text('Dep: %${volleyballPred!.awayWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.awayTeamColor, fontWeight: FontWeight.w600)),
                    Text('178.5 Üst: %${volleyballPred!.overProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ] else if (basketballPred != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Ev: %${basketballPred!.homeWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.homeTeamColor, fontWeight: FontWeight.w600)),
                    Text('Skor: ${basketballPred!.expectedHomeScore.round()}-${basketballPred!.expectedAwayScore.round()}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Text('Dep: %${basketballPred!.awayWinProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.awayTeamColor, fontWeight: FontWeight.w600)),
                    Text('Üst: %${basketballPred!.overProbability.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



