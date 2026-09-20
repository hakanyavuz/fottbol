import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/season_utils.dart';
import '../models/country.dart';
import '../models/fixture.dart';
import '../models/league.dart';
import '../models/api_team.dart';
import '../models/sport_type.dart';
import '../services/api_football_service.dart';
import '../services/multi_sport_service.dart';

/// API-Football Anahtarını Tutan Provider
/// Başlangıç değeri `main.dart` içinde kayıtlı anahtarla override edilir.
final apiFootballKeyProvider = StateProvider<String>((ref) => '');

/// API-Football Servis İstemcisi
final apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  final key = ref.watch(apiFootballKeyProvider);
  return ApiFootballService(apiKey: key);
});

/// Seçili Spor Dalı (Futbol, Voleybol, Basketbol, Tenis)
final selectedSportProvider = StateProvider<SportType>((ref) => SportType.soccer);

/// Çoklu Spor Servis İstemcisi
final multiSportServiceProvider = Provider<MultiSportService>((ref) {
  final key = ref.watch(apiFootballKeyProvider);
  return MultiSportService(apiKey: key);
});

/// Ülke Arama Metni (Debounce edilmiş)
final countrySearchQueryProvider = StateProvider<String>((ref) => '');

/// 1. Tüm Ülkeleri Getiren ve Arama Filtresi Uygulayan Provider (Lazy Loading)
final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  final allCountries = await service.getCountries();
  final query = ref.watch(countrySearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return allCountries;

  return allCountries.where((c) => c.name.toLowerCase().contains(query)).toList();
});

/// Seçili Ülke
final selectedCountryProvider = StateProvider<Country?>((ref) => null);

/// Lig Türü Filtresi ('Tümü', 'League', 'Cup')
final leagueTypeFilterProvider = StateProvider<String>((ref) => 'Tümü');

/// Seçili Sezon (varsayılan: içinde bulunulan sezon)
final selectedSeasonProvider = StateProvider<int>((ref) => SeasonUtils.currentSeason());

/// 2. Seçili Ülkeye Göre Ligleri Getiren Parametrik Provider (FutureProvider.family)
final leaguesByCountryProvider = FutureProvider.family<List<League>, String>((ref, countryName) async {
  final service = ref.watch(apiFootballServiceProvider);
  final season = ref.watch(selectedSeasonProvider);
  final typeFilter = ref.watch(leagueTypeFilterProvider);

  final leagues = await service.getLeaguesByCountry(countryName, season: season);

  if (typeFilter == 'Tümü') return leagues;

  return leagues.where((l) => l.type.toLowerCase() == typeFilter.toLowerCase()).toList();
});

/// Seçili Lig
final selectedLeagueProvider = StateProvider<League?>((ref) => null);

/// Takım Arama Metni (lig içi filtre)
final teamSearchQueryProvider = StateProvider<String>((ref) => '');

/// Lig ve Sezon Parametre Kaydı
class LeagueSeasonParams {
  final int leagueId;
  final int season;

  const LeagueSeasonParams({required this.leagueId, required this.season});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeagueSeasonParams &&
          runtimeType == other.runtimeType &&
          leagueId == other.leagueId &&
          season == other.season;

  @override
  int get hashCode => leagueId.hashCode ^ season.hashCode;
}

/// 3. Seçilen Lige Göre Takımları Getiren Parametrik Provider (FutureProvider.family)
final teamsByLeagueProvider =
    FutureProvider.family<List<ApiTeam>, LeagueSeasonParams>((ref, params) async {
  final service = ref.watch(apiFootballServiceProvider);
  final teams = await service.getTeamsByLeague(params.leagueId, params.season);
  final query = ref.watch(teamSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return teams;

  return teams.where((t) => t.name.toLowerCase().contains(query)).toList();
});

/// 4. Ligin yaklaşan maçları (tahmin yapılabilecek fikstür)
final upcomingFixturesProvider =
    FutureProvider.family<List<Fixture>, LeagueSeasonParams>((ref, params) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getUpcomingFixtures(leagueId: params.leagueId, season: params.season);
});

/// 5. Ligin son oynanan maçları (sonuçlar)
final recentFixturesProvider =
    FutureProvider.family<List<Fixture>, LeagueSeasonParams>((ref, params) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getRecentFixtures(leagueId: params.leagueId, season: params.season);
});

/// Dünya genelinde takım araması (ülke/lig gezinmeden doğrudan takıma ulaşmak için)
final globalTeamSearchQueryProvider = StateProvider<String>((ref) => '');

final globalTeamSearchProvider = FutureProvider<List<ApiTeam>>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  final query = ref.watch(globalTeamSearchQueryProvider).trim();

  // API-Football arama için en az 3 karakter ister
  if (query.length < 3) return const [];

  return service.searchTeams(query);
});

/// Kullanıcının şu an Ev Sahibi mi (true) yoksa Deplasman mı (false) seçtiği durumu
final isPickingHomeTeamProvider = StateProvider<bool>((ref) => true);
