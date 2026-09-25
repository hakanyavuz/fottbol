import 'dart:async';
import 'package:flutter/material.dart';
import '../models/fixture.dart';
import '../models/head_to_head.dart';
import '../models/team.dart';
import '../models/prediction_result.dart';
import '../models/odds_comparison.dart';
import '../models/weather_pitch_condition.dart';
import '../models/sport_type.dart';
import '../models/lineup.dart';
import '../models/match_event.dart';
import '../services/api_football_service.dart';
import '../services/poisson_engine.dart';
import '../services/gemini_analysis_service.dart';
import '../services/model_calibrator.dart';
import '../services/storage_service.dart';
import '../services/football_offline_repository.dart';
import '../services/real_sports_live_service.dart';
import '../services/match_tracker_service.dart';
import '../services/consensus_engine.dart';
import '../services/multi_source_football_service.dart';
import '../services/club_elo_service.dart';
import '../core/utils/team_name_matcher.dart';

class MatchPredictionProvider extends ChangeNotifier {
  List<Team> _allTeams = [];
  List<Team> _filteredTeams = [];
  String _selectedLeague = 'Tümü';
  String _selectedCountry = 'Tümü';
  String _searchQuery = '';
  SportType _selectedSport = SportType.soccer;

  Team? _homeTeam;
  Team? _awayTeam;
  PredictionResult? _currentPrediction;
  List<PredictionResult> _pastPredictions = [];
  
  MatchLiveAlert? _lastAlert;
  StreamSubscription<MatchLiveAlert>? _alertSub;
  
  final Map<int, List<TeamLineup>> _fixtureLineups = {};
  final Map<int, List<MatchEvent>> _fixtureEvents = {};
  final Map<int, DateTime> _lastLineupCheck = {};
  List<TeamLineup>? _currentLineups;
  List<MatchEvent> _currentEvents = [];
  bool _isLineupConfirmed = false;
  String? _lineupAlertMessage;

  List<Fixture> _liveFixtures = [];
  DateTime _selectedLiveDate = DateTime.now();
  bool _isLoadingLive = false;
  Timer? _liveUpdateTimer;

  bool _isLoadingTeams = false;
  bool _isPredicting = false;
  bool _isLoadingLineups = false;
  bool _isAnalyzingGemini = false;
  bool _isCheckingResults = false;
  String? _errorMessage;

  int _analystPoints = 0;
  String _analystRank = 'Çaylak';

  String _apiFootballKey = '';
  String _geminiApiKey = '';

  // Getters
  List<TeamLineup>? getLineupsForFixture(int fixtureId) => _fixtureLineups[fixtureId];
  List<MatchEvent> getEventsForFixture(int fixtureId) => _fixtureEvents[fixtureId] ?? const [];
  List<MatchEvent> get currentEvents => _currentEvents;
  bool shouldCheckLineups(int fixtureId) {
    final last = _lastLineupCheck[fixtureId];
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= 3;
  }
  Team? findTeamByName(String name) {
    for (final t in _allTeams) {
      if (TeamNameMatcher.matches(t.name, name)) return t;
    }
    return null;
  }
  int get analystPoints => _analystPoints;
  String get analystRank => _analystRank;
  List<Team> get allTeams => _allTeams;
  List<Team> get filteredTeams => _filteredTeams;
  String get selectedLeague => _selectedLeague;
  String get selectedCountry => _selectedCountry;
  SportType get selectedSport => _selectedSport;
  Team? get homeTeam => _homeTeam;
  Team? get awayTeam => _awayTeam;
  PredictionResult? get currentPrediction => _currentPrediction;
  List<PredictionResult> get pastPredictions => _pastPredictions;
  List<TeamLineup>? get currentLineups => _currentLineups;
  bool get isLineupConfirmed => _isLineupConfirmed;
  String? get lineupAlertMessage => _lineupAlertMessage;
  List<Fixture> get liveFixtures => _liveFixtures;
  DateTime get selectedLiveDate => _selectedLiveDate;
  bool get isLoadingLive => _isLoadingLive;
  bool get isLoadingTeams => _isLoadingTeams;
  bool get isPredicting => _isPredicting;
  bool get isLoadingLineups => _isLoadingLineups;
  bool get isAnalyzingGemini => _isAnalyzingGemini;
  bool get isCheckingResults => _isCheckingResults;
  String? get errorMessage => _errorMessage;
  String get apiFootballKey => _apiFootballKey;
  String get geminiApiKey => _geminiApiKey;
  MatchLiveAlert? get lastAlert => _lastAlert;

  void dismissAlert() {
    _lastAlert = null;
    notifyListeners();
  }

  PredictionAccuracy get accuracy => PredictionAccuracy.from(_pastPredictions);
  CalibrationResult get calibration => ModelCalibrator.calibrate(_pastPredictions);

  MatchPredictionProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final keys = await StorageService.getApiKeys();
    _apiFootballKey = keys['apiFootball'] ?? '';
    _geminiApiKey = keys['gemini'] ?? '';
    await MultiSourceFootballService.initialize();
    await loadTeams();
    await loadPastPredictions();
    _calculateAnalystPoints();

    _alertSub = MatchTrackerService.alertStream.listen((alert) {
      _lastAlert = alert;
      notifyListeners();
    });

    _startLiveBackgroundUpdates();
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = null;
    _alertSub?.cancel();
    _alertSub = null;
    super.dispose();
  }

  void _startLiveBackgroundUpdates() {
    restartLiveBackgroundUpdates();
  }

  Future<void> restartLiveBackgroundUpdates() async {
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = null;
    final seconds = await StorageService.getRefreshIntervalSeconds();
    if (_isDisposed) return;
    if (seconds <= 0) return; // Manuel yenileme modu
    _liveUpdateTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final isToday = _selectedLiveDate.year == now.year &&
          _selectedLiveDate.month == now.month &&
          _selectedLiveDate.day == now.day;
      if (isToday) {
        final api = ApiFootballService(apiKey: _apiFootballKey);
        loadLiveFixtures(api, _selectedLiveDate);
      }
      if (_currentPrediction?.fixtureId != null) {
        final api = ApiFootballService(apiKey: _apiFootballKey);
        fetchAndAnalyzeLineups(_currentPrediction!.fixtureId!, api);
      }
    });
  }

  void _calculateAnalystPoints() {
    int points = 0;
    for (var p in _pastPredictions) {
      if (!p.hasResult) continue;
      if (p.isExactScoreHit == true) {
        points += 50;
      } else if (p.isOutcomeHit == true) {
        points += 20;
      }
      if (p.isOver25Hit == true) {
        points += 10;
      }
      if (p.isBttsHit == true) {
        points += 10;
      }
    }
    _analystPoints = points;
    if (points > 1000) {
      _analystRank = 'Efsane';
    } else if (points > 500) {
      _analystRank = 'Üstad';
    } else if (points > 200) {
      _analystRank = 'Analist';
    } else {
      _analystRank = 'Çaylak';
    }
    notifyListeners();
  }

  Future<void> loadTeams() async {
    _isLoadingTeams = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final popularLeagues = [203, 39, 140, 78, 135, 61, 2];
      final List<Team> allOfflineTeams = [];
      for (var id in popularLeagues) {
        final apiTeams = FootballOfflineRepository.getTeams(id);
        for (var at in apiTeams) {
          allOfflineTeams.add(Team(
            id: at.id.toString(),
            name: at.name,
            shortName: at.code ?? at.name,
            crestUrl: at.logo,
            league: at.country, 
            venue: at.venueName ?? 'Stadyum',
            stats: FootballOfflineRepository.getRealisticStats(at.id, at.name),
            squad: FootballOfflineRepository.getRealisticSquad(at.id, at.name),
          ));
        }
      }
      _allTeams = allOfflineTeams;
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Takımlar yüklenirken hata oluştu: $e';
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  void setSport(SportType sport) {
    _selectedSport = sport;
    notifyListeners();
  }

  void setCountry(String country) {
    _selectedCountry = country;
    _selectedLeague = 'Tümü';
    _applyFilters();
  }

  void filterByLeague(String league) {
    _selectedLeague = league;
    _applyFilters();
  }

  void searchTeams(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTeams = _allTeams.where((team) {
      final matchesCountry = _selectedCountry == 'Tümü' || team.league == _selectedCountry;
      final matchesLeague = _selectedLeague == 'Tümü';
      final matchesSearch = _searchQuery.isEmpty ||
          team.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          team.shortName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCountry && matchesLeague && matchesSearch;
    }).toList();
    notifyListeners();
  }

  void selectHomeTeam(Team team) {
    _homeTeam = team;
    if (_awayTeam?.id == team.id) _awayTeam = null;
    _currentPrediction = null;
    _currentLineups = null;
    _currentEvents = [];
    _isLineupConfirmed = false;
    _lineupAlertMessage = null;
    notifyListeners();
  }

  void selectAwayTeam(Team team) {
    _awayTeam = team;
    if (_homeTeam?.id == team.id) _homeTeam = null;
    _currentPrediction = null;
    _currentLineups = null;
    _currentEvents = [];
    _isLineupConfirmed = false;
    _lineupAlertMessage = null;
    notifyListeners();
  }

  void swapTeams() {
    final temp = _homeTeam;
    _homeTeam = _awayTeam;
    _awayTeam = temp;
    _currentPrediction = null;
    _currentLineups = null;
    _currentEvents = [];
    _isLineupConfirmed = false;
    _lineupAlertMessage = null;
    notifyListeners();
  }

  bool isTeamSelected(String teamId) => _homeTeam?.id == teamId || _awayTeam?.id == teamId;

  Team? selectedTeamById(String teamId) {
    if (_homeTeam?.id == teamId) return _homeTeam;
    if (_awayTeam?.id == teamId) return _awayTeam;
    return null;
  }

  void togglePlayerInjury(String teamId, String playerId) {
    var changed = false;
    if (_homeTeam?.id == teamId) { _homeTeam = _withToggledInjury(_homeTeam!, playerId); changed = true; }
    if (_awayTeam?.id == teamId) { _awayTeam = _withToggledInjury(_awayTeam!, playerId); changed = true; }
    if (changed) notifyListeners();
  }

  Team _withToggledInjury(Team team, String playerId) {
    final squad = team.squad.map((player) {
      if (player.id != playerId) return player;
      final willBeInjured = !player.isInjured;
      return player.copyWith(isInjured: willBeInjured, injuryReason: willBeInjured ? 'Teknik Heyet Kararı' : null);
    }).toList();
    return team.copyWith(squad: squad);
  }

  Future<void> fetchAndAnalyzeLineups(int fixtureId, [ApiFootballService? service, String? leagueCode]) async {
    _isLoadingLineups = true;
    notifyListeners();
    try {
      // 1. Önce gerçek ESPN özetinden kadroları ve maç olaylarını çek
      List<TeamLineup> lineups = await RealSportsLiveService.getFixtureLineups(fixtureId, leagueCode: leagueCode);
      List<MatchEvent> events = await RealSportsLiveService.getFixtureEvents(fixtureId, leagueCode: leagueCode);

      // 2. ESPN'den dönmediyse ve API servisi varsa API-Football'dan çek
      if (lineups.isEmpty && service != null) {
        lineups = await service.getFixtureLineups(fixtureId);
      }
      if (events.isEmpty && service != null) {
        events = await service.getFixtureEvents(fixtureId);
      }

      _lastLineupCheck[fixtureId] = DateTime.now();
      _fixtureEvents[fixtureId] = events;
      _fixtureLineups[fixtureId] = lineups;

      // SADECE aktif tahmin bu fixtureId'ye aitse ve takımlar uyuşuyorsa currentLineups güncelle
      final effectiveHome = _homeTeam?.name ?? _currentPrediction?.homeTeam.name;
      final effectiveAway = _awayTeam?.name ?? _currentPrediction?.awayTeam.name;
      if (_currentPrediction != null && _currentPrediction!.fixtureId == fixtureId && effectiveHome != null && effectiveAway != null) {
        _currentEvents = events;
        final bool hasStarters = lineups.length >= 2 &&
            lineups[0].startXI.isNotEmpty &&
            lineups[1].startXI.isNotEmpty;

        final bool teamsMatch = lineups.length >= 2 &&
            ((TeamNameMatcher.matches(lineups[0].teamName, effectiveHome) && TeamNameMatcher.matches(lineups[1].teamName, effectiveAway)) ||
             (TeamNameMatcher.matches(lineups[1].teamName, effectiveHome) && TeamNameMatcher.matches(lineups[0].teamName, effectiveAway)));

        if (teamsMatch && hasStarters) {
          _currentLineups = lineups;
          _isLineupConfirmed = true;
          _analyzeLineupImpact();
        } else {
          _currentLineups = null;
          _isLineupConfirmed = false;
        }
      }
    } catch (e) {
      debugPrint('Kadro çekme hatası: $e');
    } finally {
      _isLoadingLineups = false;
      notifyListeners();
    }
  }

  void _analyzeLineupImpact() {
    if (_currentLineups == null || _homeTeam == null || _awayTeam == null || _currentPrediction == null) return;
    if (_currentLineups!.length < 2) return;

    // Hangi kadronun ev sahibi, hangisinin deplasman olduğunu güvenle belirle
    final TeamLineup homeLineup;
    final TeamLineup awayLineup;
    if (TeamNameMatcher.matches(_currentLineups![0].teamName, _homeTeam!.name)) {
      homeLineup = _currentLineups![0];
      awayLineup = _currentLineups![1];
    } else if (TeamNameMatcher.matches(_currentLineups![1].teamName, _homeTeam!.name)) {
      homeLineup = _currentLineups![1];
      awayLineup = _currentLineups![0];
    } else {
      // Kadrolar bu maçın takımlarıyla eşleşmiyor, hiçbir etki uygulama!
      return;
    }

    if (homeLineup.startXI.isEmpty || awayLineup.startXI.isEmpty) return;

    final missingStars = <String>[];
    var impactDetected = false;
    Team newHome = _homeTeam!;
    Team newAway = _awayTeam!;

    void processTeam(bool isHome) {
      final team = isHome ? _homeTeam! : _awayTeam!;
      final lineup = isHome ? homeLineup : awayLineup;
      final topPlayers = [...team.squad]..sort((a, b) => (b.goals + b.assists).compareTo(a.goals + a.assists));
      final top3 = topPlayers.take(3).toList();
      final updatedSquad = team.squad.map((p) {
        final lastName = p.name.split(' ').last.toLowerCase();
        final isInXI = lineup.startXI.any((lp) => lp.name.toLowerCase().contains(lastName));
        final isInSubs = lineup.substitutes.any((lp) => lp.name.toLowerCase().contains(lastName));
        if (!isInXI && !p.isInjured) {
          impactDetected = true;
          if (top3.contains(p)) missingStars.add('${team.name}: ${p.name}');
          return p.copyWith(isInjured: true, injuryReason: isInSubs ? 'Yedek Başlıyor' : 'Kadroda Yok / Cezalı');
        }
        return p;
      }).toList();
      if (isHome) {
        newHome = team.copyWith(squad: updatedSquad);
      } else {
        newAway = team.copyWith(squad: updatedSquad);
      }
    }

    processTeam(true);
    processTeam(false);

    if (impactDetected) {
      _lineupAlertMessage = '⚠️ KADROLAR DEĞİŞTİ: Maç kadroları açıklandı! ';
      if (missingStars.isNotEmpty) {
        _lineupAlertMessage = '${_lineupAlertMessage!}Şu yıldızlar ilk 11\'de yok: ${missingStars.join(", ")}. ';
      }
      _lineupAlertMessage = '${_lineupAlertMessage!}Tahmin revize edildi.';
      _homeTeam = newHome;
      _awayTeam = newAway;
      final calib = ModelCalibrator.calibrate(_pastPredictions);
      _currentPrediction = PoissonEngine.calculatePrediction(
        homeTeam: _homeTeam!,
        awayTeam: _awayTeam!,
        fixtureId: _currentPrediction!.fixtureId,
        matchDate: _currentPrediction!.matchDate,
        referee: _currentPrediction!.refereeStat?.name,
        rho: calib.calibratedRho,
        maxH2hWeight: calib.calibratedH2hWeight,
        isDataCalibrated: calib.isDataCalibrated,
        headToHead: _currentPrediction!.headToHead,
        homeElo: _currentPrediction!.homeElo,
        awayElo: _currentPrediction!.awayElo,
        marketOdds: _currentPrediction!.oddsComparison?.odds,
        homeXg: _currentPrediction!.homeXg,
        awayXg: _currentPrediction!.awayXg,
      );
    }
  }

  void setLiveDate(DateTime date, [ApiFootballService? service]) {
    _selectedLiveDate = date;
    loadLiveFixtures(service, date);
  }

  void previousLiveDay([ApiFootballService? service]) {
    _selectedLiveDate = _selectedLiveDate.subtract(const Duration(days: 1));
    loadLiveFixtures(service, _selectedLiveDate);
  }

  void nextLiveDay([ApiFootballService? service]) {
    _selectedLiveDate = _selectedLiveDate.add(const Duration(days: 1));
    loadLiveFixtures(service, _selectedLiveDate);
  }

  void resetLiveDateToToday([ApiFootballService? service]) {
    _selectedLiveDate = DateTime.now();
    loadLiveFixtures(service, _selectedLiveDate);
  }

  Future<void> loadLiveFixtures([ApiFootballService? service, DateTime? date]) async {
    _isLoadingLive = true;
    notifyListeners();
    try {
      final targetDate = date ?? _selectedLiveDate;
      // 1. Gerçek ESPN Live servisi ile seçili tarihteki maçları çek
      List<Fixture> fixtures = List.of(await RealSportsLiveService.getLiveFixtures(date: targetDate));

      // 2. Eğer ESPN boş döndüyse ve API servisi varsa API-Football'dan dene
      if (fixtures.isEmpty && service != null) {
        fixtures = List.of(await service.getFixturesByDate(targetDate));
      }

      // 3. ESPN'in doğrudan canlı akış vermediği yerel alt ligler (Trendyol 1. Lig, TFF 2. Lig, TFF 3. Lig vb.)
      // için resmi TFF takvimindeki maçları bültene ekle
      final officialTffFixtures = FootballOfflineRepository.getOfficialFixturesByDate(targetDate);
      for (final offFix in officialTffFixtures) {
        final alreadyExists = fixtures.any((f) =>
            (TeamNameMatcher.matches(f.homeTeamName, offFix.homeTeamName) &&
             TeamNameMatcher.matches(f.awayTeamName, offFix.awayTeamName)) ||
            f.id == offFix.id);
        if (!alreadyExists) {
          fixtures.add(offFix);
        }
      }

      // Canlı maçlar en üstte, ardından başlama saatine göre sırala
      fixtures.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        return (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100));
      });

      _liveFixtures = fixtures;

      // Anlık gol ve kırmızı kart takibini çalıştır (bildirim ve ses alarmı)
      MatchTrackerService.processFixturesUpdate(fixtures);
    } catch (e) {
      debugPrint('Canlı maç yükleme hatası: $e');
    } finally {
      _isLoadingLive = false;
      notifyListeners();
    }
  }

  Future<PredictionResult?> predictFixture(Fixture fixture, ApiFootballService service) async {
    _isPredicting = true;
    notifyListeners();
    try {
      final teams = await service.buildTeamsForFixture(fixture);
      _homeTeam = teams.home;
      _awayTeam = teams.away;
    } catch (_) {}
    return executePrediction(fixtureId: fixture.id, matchDate: fixture.date, referee: fixture.referee, service: service);
  }

  Future<PredictionResult?> executePrediction({
    int? fixtureId,
    DateTime? matchDate,
    String? referee,
    ApiFootballService? service,
    bool isNeutralGround = false,
    WeatherCondition? weatherCondition,
  }) async {
    if (_homeTeam == null || _awayTeam == null) {
      _errorMessage = 'Lütfen iki takım da seçiniz.';
      notifyListeners();
      return null;
    }
    _isPredicting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      int? autoFixtureId = fixtureId;
      final api = service ?? ApiFootballService(apiKey: _apiFootballKey);
      if (autoFixtureId == null) {
        Fixture? matchedFixture;
        // 1. Önce yüklenmiş canlı/bülten maçlarında ara
        for (final f in _liveFixtures) {
          if (TeamNameMatcher.matches(f.homeTeamName, _homeTeam!.name) &&
              TeamNameMatcher.matches(f.awayTeamName, _awayTeam!.name)) {
            matchedFixture = f;
            break;
          }
        }
        // 2. Canlı maç listesinde yoksa RealSportsLiveService ile ara
        if (matchedFixture == null) {
          try {
            final liveList = await RealSportsLiveService.getLiveFixtures(date: matchDate ?? DateTime.now());
            for (final f in liveList) {
              if (TeamNameMatcher.matches(f.homeTeamName, _homeTeam!.name) &&
                  TeamNameMatcher.matches(f.awayTeamName, _awayTeam!.name)) {
                matchedFixture = f;
                break;
              }
            }
          } catch (_) {}
        }
        // 3. API-Football varsa oradan ara
        if (matchedFixture == null) {
          try {
            final todayFixtures = await api.getFixturesByDate(matchDate ?? DateTime.now());
            for (final f in todayFixtures) {
              if (TeamNameMatcher.matches(f.homeTeamName, _homeTeam!.name) &&
                  TeamNameMatcher.matches(f.awayTeamName, _awayTeam!.name)) {
                matchedFixture = f;
                break;
              }
            }
          } catch (_) {}
        }

        if (matchedFixture != null && matchedFixture.id != -1) {
          autoFixtureId = matchedFixture.id;
          matchDate ??= matchedFixture.date;
          referee ??= matchedFixture.referee;
        }
      }
      final liveStats = await MultiSourceFootballService.getLiveStatsForMatch(
        homeTeam: _homeTeam!.name,
        awayTeam: _awayTeam!.name,
        date: matchDate,
      );
      final headToHead = await _loadHeadToHead(api);
      final calib = ModelCalibrator.calibrate(_pastPredictions);

      // Club Elo küresel güç dereceleri
      final double homeElo = ClubEloService.getTeamElo(_homeTeam!.name);
      final double awayElo = ClubEloService.getTeamElo(_awayTeam!.name);

      // Piyasa Oranlarını çek (Sofascore / Canlı Hatlar)
      BookmakerOdds? marketOdds = await MultiSourceFootballService.getOddsForMatch(
        homeTeam: _homeTeam!.name,
        awayTeam: _awayTeam!.name,
        date: matchDate,
        fixtureId: autoFixtureId != -1 ? autoFixtureId : null,
        apiService: api,
      );

      final prediction = PoissonEngine.calculatePrediction(
        homeTeam: _homeTeam!,
        awayTeam: _awayTeam!,
        fixtureId: autoFixtureId != -1 ? autoFixtureId : null,
        matchDate: matchDate,
        referee: referee,
        rho: calib.calibratedRho,
        maxH2hWeight: calib.calibratedH2hWeight,
        isDataCalibrated: calib.isDataCalibrated,
        headToHead: headToHead,
        isNeutralGround: isNeutralGround,
        weatherCondition: weatherCondition,
        homeElo: homeElo,
        awayElo: awayElo,
        homeXg: liveStats?.homeXg,
        awayXg: liveStats?.awayXg,
        marketOdds: marketOdds,
      );

      marketOdds ??= api.simulateMarketOdds(lambdaHome: prediction.lambdaHome, lambdaAway: prediction.lambdaAway);
      prediction.oddsComparison = OddsComparison.fromModelAndOdds(
        odds: marketOdds,
        modelHomeProb: prediction.homeWinProbability,
        modelDrawProb: prediction.drawProbability,
        modelAwayProb: prediction.awayWinProbability,
      );
      prediction.consensus = ConsensusEngine.buildConsensus(prediction: prediction, odds: marketOdds);
      _currentPrediction = prediction;
      _currentLineups = null;
      _currentEvents = [];
      _isLineupConfirmed = false;
      _lineupAlertMessage = null;

      // Canlı fikstür bağlandıysa hemen kadroları çekmeyi dene
      if (autoFixtureId != null && autoFixtureId != -1) {
        fetchAndAnalyzeLineups(autoFixtureId, api);
      }

      _isAnalyzingGemini = true;
      notifyListeners();
      final aiAnalysis = await GeminiAnalysisService.generateTacticalAnalysis(prediction: prediction, apiKey: _geminiApiKey);
      prediction.geminiTacticalAnalysis = aiAnalysis;
      await StorageService.savePrediction(prediction);
      await loadPastPredictions();
      return prediction;
    } catch (e) {
      _errorMessage = 'Tahmin oluşturulurken bir sorun oluştu: $e';
      return null;
    } finally {
      _isPredicting = false;
      _isAnalyzingGemini = false;
      notifyListeners();
    }
  }

  Future<HeadToHeadSummary?> _loadHeadToHead(ApiFootballService api) async {
    final homeId = _homeTeam?.apiFootballId;
    final awayId = _awayTeam?.apiFootballId;
    if (homeId == null || awayId == null || !api.hasKey) return null;
    try { return await api.getHeadToHead(homeTeamId: homeId, awayTeamId: awayId).timeout(const Duration(seconds: 15)); } catch (_) { return null; }
  }

  Future<void> refreshGeminiAnalysis() async {
    if (_currentPrediction == null) return;
    _isAnalyzingGemini = true;
    notifyListeners();
    try {
      final aiAnalysis = await GeminiAnalysisService.generateTacticalAnalysis(prediction: _currentPrediction!, apiKey: _geminiApiKey);
      _currentPrediction!.geminiTacticalAnalysis = aiAnalysis;
      await StorageService.savePrediction(_currentPrediction!);
      await loadPastPredictions();
    } finally {
      _isAnalyzingGemini = false;
      notifyListeners();
    }
  }

  Future<int> refreshResults(ApiFootballService service, {int maxRequests = 10}) async {
    if (!service.hasKey) return 0;
    final pending = _pastPredictions.where((p) => p.isAwaitingResult).take(maxRequests).toList();
    if (pending.isEmpty) return 0;
    var updated = 0;
    _isCheckingResults = true;
    notifyListeners();
    try {
      for (final prediction in pending) {
        final fixture = await service.getFixtureById(prediction.fixtureId!, forceRefresh: true);
        if (fixture == null) continue;
        prediction.fixtureStatus = fixture.statusShort;
        if (fixture.isFinished && fixture.hasScore) {
          prediction.actualHomeGoals = fixture.homeGoals;
          prediction.actualAwayGoals = fixture.awayGoals;
          updated++;
        }
        await StorageService.updatePrediction(prediction);
      }
    } finally {
      _isCheckingResults = false;
      await loadPastPredictions();
      _calculateAnalystPoints();
    }
    return updated;
  }

  Future<void> loadPastPredictions() async {
    _pastPredictions = await StorageService.getSavedPredictions();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await StorageService.clearPredictions();
    _pastPredictions = [];
    _analystPoints = 0;
    _analystRank = 'Çaylak';
    notifyListeners();
  }

  Future<void> updateApiKeys({String? apiFootballKey, required String geminiKey}) async {
    if (apiFootballKey != null) _apiFootballKey = apiFootballKey;
    _geminiApiKey = geminiKey;
    await StorageService.saveApiKeys(apiFootballKey: _apiFootballKey, geminiKey: geminiKey);
    await loadTeams();
    notifyListeners();
  }
}
