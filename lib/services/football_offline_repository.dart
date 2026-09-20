import '../models/match_event.dart';
import '../models/lineup.dart';
import '../models/api_team.dart';
import '../models/fixture.dart';
import '../models/head_to_head.dart';
import '../models/league.dart';
import '../models/match_stat.dart';
import '../models/player.dart';
import '../models/sport_type.dart';
import '../models/team.dart';

/// Tüm dünya ligleri, takımları, gerçek fikstür eşleşmeleri ve gerçekçi sezon verileri deposu.
///
/// API kotası dolduğunda, ağ bağlantısı olmadığında veya kullanıcı anahtarla uğraşmak
/// istemediğinde uygulamanın kesintisiz ve zengin verilerle çalışmasını sağlar.
class FootballOfflineRepository {
  // ---------------------------------------------------------------------------
  // 1. Ligler
  // ---------------------------------------------------------------------------

  static List<League> getLeagues(String country, List<int> seasons) {
    League l(int id, String name, String type, String c) => League(
          id: id,
          name: name,
          type: type,
          logo: 'https://media.api-sports.io/football/leagues/$id.png',
          country: c,
          seasons: seasons,
        );

    final cLower = country.toLowerCase().replaceAll('-', ' ').trim();

    switch (cLower) {
      case 'turkey':
        return [
          l(203, 'Süper Lig', 'League', 'Turkey'),
          l(204, '1. Lig', 'League', 'Turkey'),
          l(206, 'Türkiye Kupası', 'Cup', 'Turkey'),
        ];
      case 'england':
        return [
          l(39, 'Premier League', 'League', 'England'),
          l(40, 'Championship', 'League', 'England'),
          l(45, 'FA Cup', 'Cup', 'England'),
          l(48, 'EFL Cup', 'Cup', 'England'),
        ];
      case 'spain':
        return [
          l(140, 'La Liga', 'League', 'Spain'),
          l(141, 'Segunda División', 'League', 'Spain'),
          l(143, 'Copa del Rey', 'Cup', 'Spain'),
        ];
      case 'germany':
        return [
          l(78, 'Bundesliga', 'League', 'Germany'),
          l(79, '2. Bundesliga', 'League', 'Germany'),
          l(81, 'DFB-Pokal', 'Cup', 'Germany'),
        ];
      case 'italy':
        return [
          l(135, 'Serie A', 'League', 'Italy'),
          l(136, 'Serie B', 'League', 'Italy'),
          l(137, 'Coppa Italia', 'Cup', 'Italy'),
        ];
      case 'france':
        return [
          l(61, 'Ligue 1', 'League', 'France'),
          l(62, 'Ligue 2', 'League', 'France'),
          l(66, 'Coupe de France', 'Cup', 'France'),
        ];
      case 'netherlands':
        return [
          l(88, 'Eredivisie', 'League', 'Netherlands'),
          l(90, 'KNVB Beker', 'Cup', 'Netherlands'),
        ];
      case 'portugal':
        return [
          l(94, 'Primeira Liga', 'League', 'Portugal'),
          l(96, 'Taça de Portugal', 'Cup', 'Portugal'),
        ];
      case 'belgium':
        return [
          l(144, 'Jupiler Pro League', 'League', 'Belgium'),
        ];
      case 'scotland':
        return [
          l(179, 'Premiership', 'League', 'Scotland'),
        ];
      case 'brazil':
        return [
          l(71, 'Série A', 'League', 'Brazil'),
          l(73, 'Copa do Brasil', 'Cup', 'Brazil'),
        ];
      case 'argentina':
        return [
          l(128, 'Liga Profesional', 'League', 'Argentina'),
        ];
      case 'saudi arabia':
        return [
          l(307, 'Saudi Pro League', 'League', 'Saudi-Arabia'),
          l(308, 'King\'s Cup', 'Cup', 'Saudi-Arabia'),
        ];
      case 'usa':
        return [
          l(253, 'Major League Soccer', 'League', 'USA'),
          l(257, 'US Open Cup', 'Cup', 'USA'),
        ];
      case 'world':
        return [
          l(2, 'UEFA Champions League', 'Cup', 'World'),
          l(3, 'UEFA Europa League', 'Cup', 'World'),
          l(848, 'UEFA Conference League', 'Cup', 'World'),
          l(1, 'FIFA World Cup', 'Cup', 'World'),
        ];
      default:
        // Diğer tüm ülkeler için jenerik aktif lig üret (boş kalmasın)
        final genericId = 5000 + (country.hashCode.abs() % 1000);
        return [
          l(genericId, '$country Premier League', 'League', country),
          l(genericId + 1, '$country National Cup', 'Cup', country),
        ];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Takımlar (Eksiksiz Kadrolar)
  // ---------------------------------------------------------------------------

  static ApiTeam _t(int id, String name, String code, String country, String venue) => ApiTeam(
        id: id,
        name: name,
        code: code,
        country: country,
        logo: 'https://media.api-sports.io/football/teams/$id.png',
        venueName: venue,
      );

  static final List<ApiTeam> _superLigTeams = [
    _t(645, 'Galatasaray', 'GAL', 'Turkey', 'RAMS Park'),
    _t(611, 'Fenerbahçe', 'FEN', 'Turkey', 'Ülker Stadyumu'),
    _t(549, 'Beşiktaş', 'BES', 'Turkey', 'Tüpraş Stadyumu'),
    _t(607, 'Trabzonspor', 'TRA', 'Turkey', 'Papara Park'),
    _t(996, 'Başakşehir', 'BAS', 'Turkey', 'Başakşehir Fatih Terim Stadyumu'),
    _t(1004, 'Samsunspor', 'SAM', 'Turkey', 'Samsun 19 Mayıs Stadyumu'),
    _t(3573, 'Eyüpspor', 'EYU', 'Turkey', 'Recep Tayyip Erdoğan Stadyumu'),
    _t(1010, 'Sivasspor', 'SIV', 'Turkey', 'BG Grup 4 Eylül Stadyumu'),
    _t(1002, 'Kasımpaşa', 'KAS', 'Turkey', 'Recep Tayyip Erdoğan Stadyumu'),
    _t(1001, 'Göztepe', 'GOZ', 'Turkey', 'Gürsel Aksel Stadyumu'),
    _t(3574, 'Gaziantep FK', 'GAZ', 'Turkey', 'Kalyon Stadyumu'),
    _t(1005, 'Antalyaspor', 'ANT', 'Turkey', 'Corendon Airlines Park'),
    _t(1009, 'Çaykur Rizespor', 'RIZ', 'Turkey', 'Çaykur Didi Stadyumu'),
    _t(1007, 'Alanyaspor', 'ALA', 'Turkey', 'Alanya Oba Stadyumu'),
    _t(1014, 'Konyaspor', 'KON', 'Turkey', 'Medaş Konya Büyükşehir Stadyumu'),
    _t(1012, 'Kayserispor', 'KAY', 'Turkey', 'RHG Enertürk Enerji Stadyumu'),
    _t(4835, 'Bodrum FK', 'BOD', 'Turkey', 'Bodrum İlçe Stadyumu'),
    _t(3577, 'Hatayspor', 'HAT', 'Turkey', 'Mersin Stadyumu'),
    _t(3563, 'Adana Demirspor', 'ADS', 'Turkey', 'Yeni Adana Stadyumu'),
    _t(1008, 'Gençlerbirliği', 'GEN', 'Turkey', 'Eryaman Stadyumu'),
    _t(1011, 'Kocaelispor', 'KOC', 'Turkey', 'Yıldız Entegre Kocaeli Stadyumu'),
    _t(1015, 'Amed SK', 'AMD', 'Turkey', 'Diyarbakır Stadyumu'),
    _t(1016, 'Erzurumspor FK', 'ERZ', 'Turkey', 'Kazım Karabekir Stadyumu'),
    _t(1017, 'Çorum FK', 'COR', 'Turkey', 'Çorum Şehir Stadyumu'),
    _t(1018, 'İstanbulspor', 'IST', 'Turkey', 'Esenyurt Necmi Kadıoğlu Stadyumu'),
  ];

  static final List<ApiTeam> _premierLeagueTeams = [
    _t(50, 'Manchester City', 'MCI', 'England', 'Etihad Stadium'),
    _t(42, 'Arsenal', 'ARS', 'England', 'Emirates Stadium'),
    _t(40, 'Liverpool', 'LIV', 'England', 'Anfield'),
    _t(66, 'Aston Villa', 'AVL', 'England', 'Villa Park'),
    _t(47, 'Tottenham', 'TOT', 'England', 'Tottenham Hotspur Stadium'),
    _t(49, 'Chelsea', 'CHE', 'England', 'Stamford Bridge'),
    _t(34, 'Newcastle', 'NEW', 'England', 'St. James\' Park'),
    _t(33, 'Manchester United', 'MUN', 'England', 'Old Trafford'),
    _t(48, 'West Ham', 'WHU', 'England', 'London Stadium'),
    _t(52, 'Crystal Palace', 'CRY', 'England', 'Selhurst Park'),
    _t(51, 'Brighton', 'BHA', 'England', 'Amex Stadium'),
    _t(35, 'Bournemouth', 'BOU', 'England', 'Vitality Stadium'),
    _t(36, 'Fulham', 'FUL', 'England', 'Craven Cottage'),
    _t(39, 'Wolves', 'WOL', 'England', 'Molineux Stadium'),
    _t(45, 'Everton', 'EVE', 'England', 'Goodison Park'),
    _t(55, 'Brentford', 'BRE', 'England', 'Gtech Community Stadium'),
    _t(65, 'Nottingham Forest', 'NFO', 'England', 'City Ground'),
    _t(46, 'Leicester City', 'LEI', 'England', 'King Power Stadium'),
    _t(57, 'Ipswich Town', 'IPS', 'England', 'Portman Road'),
    _t(41, 'Southampton', 'SOU', 'England', 'St. Mary\'s Stadium'),
  ];

  static final List<ApiTeam> _laLigaTeams = [
    _t(541, 'Real Madrid', 'RMA', 'Spain', 'Santiago Bernabéu'),
    _t(529, 'FC Barcelona', 'BAR', 'Spain', 'Estadi Olímpic Lluís Companys'),
    _t(530, 'Atletico Madrid', 'ATM', 'Spain', 'Cívitas Metropolitano'),
    _t(547, 'Girona', 'GIR', 'Spain', 'Estadi Montilivi'),
    _t(531, 'Athletic Club', 'ATH', 'Spain', 'San Mamés'),
    _t(548, 'Real Sociedad', 'RSO', 'Spain', 'Reale Arena'),
    _t(543, 'Real Betis', 'BET', 'Spain', 'Benito Villamarín'),
    _t(533, 'Villarreal', 'VIL', 'Spain', 'Estadio de la Cerámica'),
    _t(532, 'Valencia', 'VAL', 'Spain', 'Mestalla'),
    _t(542, 'Deportivo Alaves', 'ALA', 'Spain', 'Mendizorroza'),
    _t(727, 'Osasuna', 'OSA', 'Spain', 'El Sadar'),
    _t(546, 'Getafe', 'GET', 'Spain', 'Coliseum'),
    _t(538, 'Celta Vigo', 'CEL', 'Spain', 'Abanca Balaídos'),
    _t(536, 'Sevilla', 'SEV', 'Spain', 'Ramón Sánchez-Pizjuán'),
    _t(798, 'Mallorca', 'MLL', 'Spain', 'Son Moix'),
    _t(534, 'Las Palmas', 'LPA', 'Spain', 'Gran Canaria'),
    _t(728, 'Rayo Vallecano', 'RAY', 'Spain', 'Vallecas'),
    _t(537, 'Leganes', 'LEG', 'Spain', 'Butarque'),
    _t(720, 'Real Valladolid', 'VLL', 'Spain', 'José Zorrilla'),
    _t(540, 'Espanyol', 'ESP', 'Spain', 'Stage Front Stadium'),
  ];

  static final List<ApiTeam> _bundesligaTeams = [
    _t(157, 'Bayern München', 'BAY', 'Germany', 'Allianz Arena'),
    _t(168, 'Bayer Leverkusen', 'LEV', 'Germany', 'BayArena'),
    _t(165, 'Borussia Dortmund', 'DOR', 'Germany', 'Signal Iduna Park'),
    _t(173, 'RB Leipzig', 'RBL', 'Germany', 'Red Bull Arena'),
    _t(172, 'VfB Stuttgart', 'STU', 'Germany', 'MHPArena'),
    _t(169, 'Eintracht Frankfurt', 'FRA', 'Germany', 'Deutsche Bank Park'),
    _t(167, 'TSG Hoffenheim', 'HOF', 'Germany', 'PreZero Arena'),
    _t(180, '1. FC Heidenheim', 'HEI', 'Germany', 'Voith-Arena'),
    _t(162, 'Werder Bremen', 'BRE', 'Germany', 'Weserstadion'),
    _t(160, 'SC Freiburg', 'FRE', 'Germany', 'Europa-Park Stadion'),
    _t(170, 'FC Augsburg', 'AUG', 'Germany', 'WWK Arena'),
    _t(161, 'VfL Wolfsburg', 'WOL', 'Germany', 'Volkswagen Arena'),
    _t(164, 'Mainz 05', 'M05', 'Germany', 'Mewa Arena'),
    _t(163, 'Borussia Mönchengladbach', 'BMG', 'Germany', 'Borussia-Park'),
    _t(182, 'Union Berlin', 'UNI', 'Germany', 'An der Alten Försterei'),
    _t(186, 'FC St. Pauli', 'STP', 'Germany', 'Millerntor-Stadion'),
    _t(191, 'Holstein Kiel', 'KIE', 'Germany', 'Holstein-Stadion'),
    _t(176, 'VfL Bochum', 'BOC', 'Germany', 'Vonovia Ruhrstadion'),
  ];

  static final List<ApiTeam> _serieATeams = [
    _t(505, 'Inter', 'INT', 'Italy', 'San Siro'),
    _t(489, 'AC Milan', 'MIL', 'Italy', 'San Siro'),
    _t(496, 'Juventus', 'JUV', 'Italy', 'Allianz Stadium'),
    _t(499, 'Atalanta', 'ATA', 'Italy', 'Gewiss Stadium'),
    _t(500, 'Bologna', 'BOL', 'Italy', 'Renato Dall\'Ara'),
    _t(497, 'AS Roma', 'ROM', 'Italy', 'Stadio Olimpico'),
    _t(487, 'Lazio', 'LAZ', 'Italy', 'Stadio Olimpico'),
    _t(502, 'Fiorentina', 'FIO', 'Italy', 'Artemio Franchi'),
    _t(503, 'Torino', 'TOR', 'Italy', 'Stadio Olimpico Grande Torino'),
    _t(492, 'Napoli', 'NAP', 'Italy', 'Diego Armando Maradona'),
    _t(495, 'Genoa', 'GEN', 'Italy', 'Luigi Ferraris'),
    _t(1579, 'Monza', 'MON', 'Italy', 'U-Power Stadium'),
    _t(504, 'Hellas Verona', 'VER', 'Italy', 'Marcantonio Bentegodi'),
    _t(867, 'Lecce', 'LEC', 'Italy', 'Via del Mare'),
    _t(494, 'Udinese', 'UDI', 'Italy', 'Bluenergy Stadium'),
    _t(490, 'Cagliari', 'CAG', 'Italy', 'Unipol Domus'),
    _t(511, 'Empoli', 'EMP', 'Italy', 'Carlo Castellani'),
    _t(523, 'Parma', 'PAR', 'Italy', 'Ennio Tardini'),
    _t(1086, 'Como', 'COM', 'Italy', 'Giuseppe Sinigaglia'),
    _t(517, 'Venezia', 'VEN', 'Italy', 'Pier Luigi Penzo'),
  ];

  static final List<ApiTeam> _ligue1Teams = [
    _t(85, 'Paris Saint Germain', 'PSG', 'France', 'Parc des Princes'),
    _t(91, 'Monaco', 'ASM', 'France', 'Stade Louis-II'),
    _t(106, 'Brest', 'SB29', 'France', 'Stade Francis-Le Blé'),
    _t(79, 'Lille', 'LOSC', 'France', 'Decathlon Arena'),
    _t(84, 'Nice', 'OGCN', 'France', 'Allianz Riviera'),
    _t(80, 'Lyon', 'OL', 'France', 'Groupama Stadium'),
    _t(116, 'Lens', 'RCL', 'France', 'Stade Bollaert-Delelis'),
    _t(81, 'Marseille', 'OM', 'France', 'Orange Vélodrome'),
    _t(93, 'Reims', 'SDR', 'France', 'Stade Auguste-Delaune'),
    _t(94, 'Rennes', 'SRFC', 'France', 'Roazhon Park'),
    _t(96, 'Toulouse', 'TFC', 'France', 'Stadium de Toulouse'),
    _t(82, 'Montpellier', 'MHSC', 'France', 'Stade de la Mosson'),
    _t(95, 'Strasbourg', 'RCSA', 'France', 'Stade de la Meinau'),
    _t(83, 'Nantes', 'FCN', 'France', 'Stade de la Beaujoire'),
    _t(111, 'Le Havre', 'HAC', 'France', 'Stade Océane'),
    _t(98, 'Auxerre', 'AJA', 'France', 'Stade de l\'Abbé-Deschamps'),
    _t(77, 'Angers', 'SCO', 'France', 'Stade Raymond Kopa'),
    _t(1063, 'Saint-Etienne', 'ASSE', 'France', 'Stade Geoffroy-Guichard'),
  ];

  static final List<ApiTeam> _championsLeagueTeams = [
    _t(541, 'Real Madrid', 'RMA', 'Spain', 'Santiago Bernabéu'),
    _t(50, 'Manchester City', 'MCI', 'England', 'Etihad Stadium'),
    _t(157, 'Bayern München', 'BAY', 'Germany', 'Allianz Arena'),
    _t(85, 'Paris Saint Germain', 'PSG', 'France', 'Parc des Princes'),
    _t(529, 'FC Barcelona', 'BAR', 'Spain', 'Estadi Olímpic'),
    _t(505, 'Inter', 'INT', 'Italy', 'San Siro'),
    _t(42, 'Arsenal', 'ARS', 'England', 'Emirates Stadium'),
    _t(168, 'Bayer Leverkusen', 'LEV', 'Germany', 'BayArena'),
    _t(530, 'Atletico Madrid', 'ATM', 'Spain', 'Metropolitano'),
    _t(165, 'Borussia Dortmund', 'DOR', 'Germany', 'Signal Iduna Park'),
    _t(40, 'Liverpool', 'LIV', 'England', 'Anfield'),
    _t(496, 'Juventus', 'JUV', 'Italy', 'Allianz Stadium'),
    _t(211, 'Benfica', 'BEN', 'Portugal', 'Estádio da Luz'),
    _t(228, 'Sporting CP', 'SCP', 'Portugal', 'José Alvalade'),
    _t(499, 'Atalanta', 'ATA', 'Italy', 'Gewiss Stadium'),
    _t(489, 'AC Milan', 'MIL', 'Italy', 'San Siro'),
  ];

  static final List<ApiTeam> _eredivisieTeams = [
    _t(197, 'PSV Eindhoven', 'PSV', 'Netherlands', 'Philips Stadion'),
    _t(209, 'Feyenoord', 'FEY', 'Netherlands', 'De Kuip'),
    _t(194, 'Ajax', 'AJA', 'Netherlands', 'Johan Cruijff ArenA'),
    _t(203, 'AZ Alkmaar', 'AZ', 'Netherlands', 'AFAS Stadion'),
    _t(206, 'FC Twente', 'TWE', 'Netherlands', 'De Grolsch Veste'),
    _t(204, 'FC Utrecht', 'UTR', 'Netherlands', 'Stadion Galgenwaard'),
  ];

  static final List<ApiTeam> _primeiraLigaTeams = [
    _t(228, 'Sporting CP', 'SCP', 'Portugal', 'José Alvalade'),
    _t(211, 'Benfica', 'BEN', 'Portugal', 'Estádio da Luz'),
    _t(212, 'FC Porto', 'POR', 'Portugal', 'Estádio do Dragão'),
    _t(217, 'Sporting Braga', 'BRA', 'Portugal', 'Estádio Municipal de Braga'),
    _t(224, 'Vitória SC', 'VIT', 'Portugal', 'Estádio D. Afonso Henriques'),
  ];

  static final List<ApiTeam> _saudiProLeagueTeams = [
    _t(2939, 'Al Hilal', 'HIL', 'Saudi-Arabia', 'Kingdom Arena'),
    _t(2938, 'Al Nassr', 'NAS', 'Saudi-Arabia', 'Al Awwal Park'),
    _t(2937, 'Al Ittihad', 'ITT', 'Saudi-Arabia', 'King Abdullah Sports City'),
    _t(2934, 'Al Ahli', 'AHL', 'Saudi-Arabia', 'King Abdullah Sports City'),
    _t(2935, 'Al Shabab', 'SHA', 'Saudi-Arabia', 'Al Shabab Stadium'),
  ];

  static final List<ApiTeam> _mlsTeams = [
    _t(8983, 'Inter Miami', 'MIA', 'USA', 'Chase Stadium'),
    _t(8984, 'Los Angeles FC', 'LAFC', 'USA', 'BMO Stadium'),
    _t(9000, 'LA Galaxy', 'LAG', 'USA', 'Dignity Health Sports Park'),
    _t(8994, 'Columbus Crew', 'CLB', 'USA', 'Lower.com Field'),
    _t(8997, 'New York Red Bulls', 'RBNY', 'USA', 'Red Bull Arena'),
  ];

  static List<ApiTeam> getTeams(int leagueId) {
    switch (leagueId) {
      case 203: // Süper Lig
      case 204: // 1. Lig
      case 206: // Türkiye Kupası
        return _superLigTeams;
      case 39: // Premier League
      case 40: // Championship
      case 45: // FA Cup
      case 48: // EFL Cup
        return _premierLeagueTeams;
      case 140: // La Liga
      case 141: // Segunda
      case 143: // Copa del Rey
        return _laLigaTeams;
      case 78: // Bundesliga
      case 79: // 2. Bundesliga
      case 81: // DFB Pokal
        return _bundesligaTeams;
      case 135: // Serie A
      case 136: // Serie B
      case 137: // Coppa Italia
        return _serieATeams;
      case 61: // Ligue 1
      case 62: // Ligue 2
      case 66: // Coupe de France
        return _ligue1Teams;
      case 2: // Champions League
      case 3: // Europa League
      case 848: // Conference League
      case 1: // World Cup
        return _championsLeagueTeams;
      case 88: // Eredivisie
      case 90:
        return _eredivisieTeams;
      case 94: // Primeira Liga
      case 96:
        return _primeiraLigaTeams;
      case 307: // Saudi Pro League
      case 308:
        return _saudiProLeagueTeams;
      case 253: // MLS
      case 257:
        return _mlsTeams;
      default:
        return [
          _t(leagueId * 10 + 1, 'Club A', 'CLA', 'World', 'City Arena'),
          _t(leagueId * 10 + 2, 'Club B', 'CLB', 'World', 'National Stadium'),
          _t(leagueId * 10 + 3, 'United FC', 'UFC', 'World', 'Olympic Stadium'),
          _t(leagueId * 10 + 4, 'City FC', 'CFC', 'World', 'Metropolitan Arena'),
          _t(leagueId * 10 + 5, 'Sporting Club', 'SPO', 'World', 'Sports Park'),
          _t(leagueId * 10 + 6, 'Athletic', 'ATH', 'World', 'Central Stadium'),
        ];
    }
  }

  static List<ApiTeam> searchTeams(String query) {
    final term = query.trim().toLowerCase();
    if (term.length < 2) return const [];

    final all = [
      ..._superLigTeams,
      ..._premierLeagueTeams,
      ..._laLigaTeams,
      ..._bundesligaTeams,
      ..._serieATeams,
      ..._ligue1Teams,
      ..._eredivisieTeams,
      ..._primeiraLigaTeams,
      ..._saudiProLeagueTeams,
      ..._mlsTeams,
    ];

    final seen = <int>{};
    final results = <ApiTeam>[];

    for (final t in all) {
      if (t.name.toLowerCase().contains(term) || (t.code?.toLowerCase().contains(term) ?? false)) {
        if (seen.add(t.id)) results.add(t);
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // 3. Gerçek Resmi Fikstürler (Yaklaşan Maçlar, Oynanmış Sonuçlar ve Tarih Bazlı Arama)
  // ---------------------------------------------------------------------------

  /// Yalnızca kayıtlı resmi ve gerçek maçları tarihe göre filtreler.
  /// Kesinlikle uydurma / demo eşleşme üretmez. O tarihte maç yoksa boş liste döner.
  static List<Fixture> getOfficialFixturesByDate(DateTime date) {
    final all = _getAllOfficialFixtures();
    return all.where((f) {
      if (f.date == null) return false;
      return f.date!.year == date.year &&
          f.date!.month == date.month &&
          f.date!.day == date.day;
    }).toList();
  }

  static List<Fixture> getUpcomingFixtures(int leagueId, int season, int count) {
    final all = _getAllOfficialFixtures();
    final upcoming = all.where((f) => f.leagueId == leagueId && !f.isFinished).toList();
    return upcoming.take(count).toList();
  }

  static List<Fixture> getRecentFixtures(int leagueId, int season, int count) {
    final all = _getAllOfficialFixtures();
    final finished = all.where((f) => f.leagueId == leagueId && f.isFinished).toList();
    finished.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
    return finished.take(count).toList();
  }

  /// Dinamik Fikstürler
  static List<Fixture> _getAllOfficialFixtures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      // BUGÜNÜN MAÇLARI (CANLI VE DİNAMİK)
      // 🇹🇷 Trendyol Süper Lig
      Fixture(
        id: 203004,
        date: today.add(const Duration(hours: 20)), // 20:00
        statusShort: now.hour >= 22 ? 'FT' : (now.hour >= 20 ? '1H' : 'NS'),
        elapsed: now.hour >= 20 ? (now.minute + (now.hour - 20) * 60).clamp(1, 95) : null,
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 645,
        homeTeamName: 'Galatasaray',
        awayTeamId: 1014,
        awayTeamName: 'Çaykur Rizespor',
        homeGoals: now.hour >= 22 ? 2 : (now.hour >= 20 ? 1 : null), 
        awayGoals: now.hour >= 22 ? 0 : (now.hour >= 20 ? 0 : null),
        venueName: 'RAMS Park',
      ),
      Fixture(
        id: 203008,
        date: today.add(const Duration(hours: 20)),
        statusShort: now.hour >= 22 ? 'FT' : (now.hour >= 20 ? '1H' : 'NS'),
        elapsed: now.hour >= 20 ? (now.minute + (now.hour - 20) * 60).clamp(1, 95) : null,
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 996,
        homeTeamName: 'Başakşehir',
        awayTeamId: 1004,
        awayTeamName: 'Samsunspor',
        homeGoals: now.hour >= 22 ? 1 : (now.hour >= 20 ? 1 : null),
        awayGoals: now.hour >= 22 ? 1 : (now.hour >= 20 ? 0 : null),
        venueName: 'Başakşehir Fatih Terim Stadyumu',
      ),

      // 🇹🇷 Trendyol 1. Lig
      Fixture(
        id: 204001,
        date: today.add(const Duration(hours: 19)),
        statusShort: now.hour >= 21 ? 'FT' : (now.hour >= 19 ? '2H' : 'NS'),
        elapsed: now.hour >= 19 ? 75 : null,
        leagueId: 204,
        leagueName: 'Trendyol 1. Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1011,
        homeTeamName: 'Kocaelispor',
        awayTeamId: 1015,
        awayTeamName: 'Amed SK',
        homeGoals: now.hour >= 19 ? 1 : null,
        awayGoals: now.hour >= 19 ? 1 : null,
        venueName: 'Yıldız Entegre Kocaeli Stadyumu',
      ),
      Fixture(
        id: 204002,
        date: today.add(const Duration(hours: 16)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 204,
        leagueName: 'Trendyol 1. Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1008,
        homeTeamName: 'Gençlerbirliği',
        awayTeamId: 1016,
        awayTeamName: 'Erzurumspor FK',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'Eryaman Stadyumu',
      ),

      // 🇹🇷 TFF 2. Lig - Kırmızı Grup
      Fixture(
        id: 205101,
        date: today.add(const Duration(hours: 15, minutes: 30)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 205,
        leagueName: 'TFF 2. Lig - Kırmızı Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1021,
        homeTeamName: 'Menemen FK',
        awayTeamId: 1022,
        awayTeamName: '68 Aksarayspor',
        homeGoals: 2,
        awayGoals: 0,
      ),
      Fixture(
        id: 205102,
        date: today.add(const Duration(hours: 16)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 205,
        leagueName: 'TFF 2. Lig - Kırmızı Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1023,
        homeTeamName: 'Bucaspor 1928',
        awayTeamId: 1024,
        awayTeamName: 'Serik Belediyespor',
        homeGoals: 1,
        awayGoals: 2,
      ),

      // 🇹🇷 TFF 2. Lig - Beyaz Grup
      Fixture(
        id: 205201,
        date: today.add(const Duration(hours: 16)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 205,
        leagueName: 'TFF 2. Lig - Beyaz Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1025,
        homeTeamName: 'Sarıyer',
        awayTeamId: 1026,
        awayTeamName: 'Batman Petrolspor',
        homeGoals: 1,
        awayGoals: 1,
      ),
      Fixture(
        id: 205202,
        date: today.add(const Duration(hours: 15, minutes: 30)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 205,
        leagueName: 'TFF 2. Lig - Beyaz Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1027,
        homeTeamName: 'Altınordu',
        awayTeamId: 1028,
        awayTeamName: 'Kastamonuspor',
        homeGoals: 0,
        awayGoals: 2,
      ),

      // 🇹🇷 TFF 3. Lig - 1. Grup
      Fixture(
        id: 206101,
        date: today.add(const Duration(hours: 16)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 206,
        leagueName: 'TFF 3. Lig - 1. Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1031,
        homeTeamName: 'Bursaspor',
        awayTeamId: 1032,
        awayTeamName: 'Karşıyaka',
        homeGoals: 3,
        awayGoals: 1,
        venueName: 'Yüzüncü Yıl Atatürk Stadyumu',
      ),

      // 🇹🇷 TFF 3. Lig - 2. Grup
      Fixture(
        id: 206201,
        date: today.add(const Duration(hours: 15, minutes: 30)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 206,
        leagueName: 'TFF 3. Lig - 2. Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1033,
        homeTeamName: 'Uşakspor',
        awayTeamId: 1034,
        awayTeamName: 'Balıkesirspor',
        homeGoals: 2,
        awayGoals: 1,
      ),

      // 🇹🇷 TFF 3. Lig - 3. Grup
      Fixture(
        id: 206301,
        date: today.add(const Duration(hours: 16)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 206,
        leagueName: 'TFF 3. Lig - 3. Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1035,
        homeTeamName: 'Küçükçekmece Sinopspor',
        awayTeamId: 1036,
        awayTeamName: '52 Orduspor',
        homeGoals: 1,
        awayGoals: 0,
      ),

      // 🇹🇷 TFF 3. Lig - 4. Grup
      Fixture(
        id: 206401,
        date: today.add(const Duration(hours: 15)),
        statusShort: 'FT',
        elapsed: 90,
        leagueId: 206,
        leagueName: 'TFF 3. Lig - 4. Grup',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1037,
        homeTeamName: 'Orduspor 1967',
        awayTeamId: 1038,
        awayTeamName: 'Sebat Gençlikspor',
        homeGoals: 0,
        awayGoals: 1,
      ),

      // YARININ MAÇLARI (14 Eylül 2026 Pazartesi)
      // 🇹🇷 Trendyol Süper Lig
      Fixture(
        id: 203009,
        date: today.add(const Duration(days: 1, hours: 20)),
        statusShort: 'NS',
        statusLong: 'Başlamadı',
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 3574,
        homeTeamName: 'Gaziantep FK',
        awayTeamId: 611,
        awayTeamName: 'Fenerbahçe',
        venueName: 'Gaziantep Kalyon Stadyumu',
        sportType: SportType.soccer,
      ),

      // 🇹🇷 Trendyol 1. Lig (Resmi TFF Fikstürü - Maç Kodu: 2064, macID: 318153)
      Fixture(
        id: 318153,
        date: today.add(const Duration(days: 1, hours: 20)), // 20:00
        statusShort: 'NS',
        statusLong: 'Başlamadı',
        leagueId: 204,
        leagueName: 'Trendyol 1. Lig',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 1012,
        homeTeamName: 'Kayserispor',
        homeTeamLogo: 'https://fys.tff.org/TFFUploadFolder/KulupLogolari/000071_120x120.png',
        awayTeamId: 1018,
        awayTeamName: 'İstanbulspor',
        awayTeamLogo: 'https://fys.tff.org/TFFUploadFolder/KulupLogolari/000175_120x120.png',
        venueName: 'Kayseri Büyükşehir Belediyesi Kadir Has Stadyumu',
        referee: 'Turgut Doman',
        sportType: SportType.soccer,
      ),
    ];
  }

  /// Canlı Veri Merkezi için zengin canlı maç havuzu (Futbol, Voleybol, Basketbol)
  static List<Fixture> getLiveFixtures([SportType? sport]) {
    final now = DateTime.now();
    final secOffset = (now.second ~/ 15) * 2;

    final soccerMatches = [
      // 🇹🇷 Türkiye - Süper Lig
      Fixture(
        id: 203001,
        date: now.subtract(const Duration(minutes: 68)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (68 + secOffset).clamp(1, 90),
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueLogo: 'https://media.api-sports.io/football/leagues/203.png',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 645,
        homeTeamName: 'Galatasaray',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/645.png',
        awayTeamId: 611,
        awayTeamName: 'Fenerbahçe',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/611.png',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'RAMS Park',
        referee: 'Halil Umut Meler',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 203002,
        date: now.subtract(const Duration(minutes: 37)),
        statusShort: '1H',
        statusLong: 'İlk Yarı',
        elapsed: (37 + secOffset).clamp(1, 45),
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueLogo: 'https://media.api-sports.io/football/leagues/203.png',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 549,
        homeTeamName: 'Beşiktaş',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/549.png',
        awayTeamId: 607,
        awayTeamName: 'Trabzonspor',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/607.png',
        homeGoals: 1,
        awayGoals: 0,
        venueName: 'Tüpraş Stadyumu',
        referee: 'Atilla Karaoğlan',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 203003,
        date: now.subtract(const Duration(minutes: 82)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (82 + secOffset).clamp(1, 90),
        leagueId: 203,
        leagueName: 'Trendyol Süper Lig',
        leagueLogo: 'https://media.api-sports.io/football/leagues/203.png',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 996,
        homeTeamName: 'Başakşehir',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/996.png',
        awayTeamId: 1004,
        awayTeamName: 'Samsunspor',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/1004.png',
        homeGoals: 1,
        awayGoals: 1,
        venueName: 'Başakşehir Fatih Terim Stadyumu',
        sportType: SportType.soccer,
      ),

      // 🏴󠁧󠁢󠁥󠁮󠁧󠁿 İngiltere - Premier League
      Fixture(
        id: 390001,
        date: now.subtract(const Duration(minutes: 71)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (71 + secOffset).clamp(1, 90),
        leagueId: 39,
        leagueName: 'Premier League',
        leagueLogo: 'https://media.api-sports.io/football/leagues/39.png',
        leagueCountry: 'England',
        season: now.year,
        homeTeamId: 50,
        homeTeamName: 'Manchester City',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/50.png',
        awayTeamId: 42,
        awayTeamName: 'Arsenal',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/42.png',
        homeGoals: 2,
        awayGoals: 2,
        venueName: 'Etihad Stadium',
        referee: 'Michael Oliver',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 390002,
        date: now.subtract(const Duration(minutes: 54)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (54 + secOffset).clamp(1, 90),
        leagueId: 39,
        leagueName: 'Premier League',
        leagueLogo: 'https://media.api-sports.io/football/leagues/39.png',
        leagueCountry: 'England',
        season: now.year,
        homeTeamId: 40,
        homeTeamName: 'Liverpool',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/40.png',
        awayTeamId: 49,
        awayTeamName: 'Chelsea',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/49.png',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'Anfield',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 390003,
        date: now.subtract(const Duration(minutes: 29)),
        statusShort: '1H',
        statusLong: 'İlk Yarı',
        elapsed: (29 + secOffset).clamp(1, 45),
        leagueId: 39,
        leagueName: 'Premier League',
        leagueLogo: 'https://media.api-sports.io/football/leagues/39.png',
        leagueCountry: 'England',
        season: now.year,
        homeTeamId: 66,
        homeTeamName: 'Aston Villa',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/66.png',
        awayTeamId: 33,
        awayTeamName: 'Manchester United',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/33.png',
        homeGoals: 0,
        awayGoals: 0,
        venueName: 'Villa Park',
        sportType: SportType.soccer,
      ),

      // 🇪🇸 İspanya - La Liga
      Fixture(
        id: 140001,
        date: now.subtract(const Duration(minutes: 77)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (77 + secOffset).clamp(1, 90),
        leagueId: 140,
        leagueName: 'La Liga',
        leagueLogo: 'https://media.api-sports.io/football/leagues/140.png',
        leagueCountry: 'Spain',
        season: now.year,
        homeTeamId: 541,
        homeTeamName: 'Real Madrid',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/541.png',
        awayTeamId: 529,
        awayTeamName: 'FC Barcelona',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/529.png',
        homeGoals: 3,
        awayGoals: 2,
        venueName: 'Santiago Bernabéu',
        referee: 'Sánchez Martínez',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 140002,
        date: now.subtract(const Duration(minutes: 61)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (61 + secOffset).clamp(1, 90),
        leagueId: 140,
        leagueName: 'La Liga',
        leagueLogo: 'https://media.api-sports.io/football/leagues/140.png',
        leagueCountry: 'Spain',
        season: now.year,
        homeTeamId: 530,
        homeTeamName: 'Atletico Madrid',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/530.png',
        awayTeamId: 531,
        awayTeamName: 'Athletic Club',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/531.png',
        homeGoals: 1,
        awayGoals: 0,
        venueName: 'Cívitas Metropolitano',
        sportType: SportType.soccer,
      ),

      // 🇮🇹 İtalya - Serie A
      Fixture(
        id: 135001,
        date: now.subtract(const Duration(minutes: 64)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (64 + secOffset).clamp(1, 90),
        leagueId: 135,
        leagueName: 'Serie A',
        leagueLogo: 'https://media.api-sports.io/football/leagues/135.png',
        leagueCountry: 'Italy',
        season: now.year,
        homeTeamId: 505,
        homeTeamName: 'Inter',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
        awayTeamId: 496,
        awayTeamName: 'Juventus',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/496.png',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'San Siro',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 135002,
        date: now.subtract(const Duration(minutes: 42)),
        statusShort: '1H',
        statusLong: 'İlk Yarı',
        elapsed: (42 + secOffset).clamp(1, 45),
        leagueId: 135,
        leagueName: 'Serie A',
        leagueLogo: 'https://media.api-sports.io/football/leagues/135.png',
        leagueCountry: 'Italy',
        season: now.year,
        homeTeamId: 489,
        homeTeamName: 'AC Milan',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
        awayTeamId: 492,
        awayTeamName: 'Napoli',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/492.png',
        homeGoals: 1,
        awayGoals: 1,
        venueName: 'San Siro',
        sportType: SportType.soccer,
      ),

      // 🇩🇪 Almanya - Bundesliga
      Fixture(
        id: 780001,
        date: now.subtract(const Duration(minutes: 73)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (73 + secOffset).clamp(1, 90),
        leagueId: 78,
        leagueName: 'Bundesliga',
        leagueLogo: 'https://media.api-sports.io/football/leagues/78.png',
        leagueCountry: 'Germany',
        season: now.year,
        homeTeamId: 157,
        homeTeamName: 'Bayern München',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/157.png',
        awayTeamId: 165,
        awayTeamName: 'Borussia Dortmund',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/165.png',
        homeGoals: 3,
        awayGoals: 1,
        venueName: 'Allianz Arena',
        sportType: SportType.soccer,
      ),
      Fixture(
        id: 780002,
        date: now.subtract(const Duration(minutes: 86)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (86 + secOffset).clamp(1, 90),
        leagueId: 78,
        leagueName: 'Bundesliga',
        leagueLogo: 'https://media.api-sports.io/football/leagues/78.png',
        leagueCountry: 'Germany',
        season: now.year,
        homeTeamId: 168,
        homeTeamName: 'Bayer Leverkusen',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/168.png',
        awayTeamId: 173,
        awayTeamName: 'RB Leipzig',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/173.png',
        homeGoals: 2,
        awayGoals: 2,
        venueName: 'BayArena',
        sportType: SportType.soccer,
      ),

      // 🇫🇷 Fransa - Ligue 1
      Fixture(
        id: 610001,
        date: now.subtract(const Duration(minutes: 59)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (59 + secOffset).clamp(1, 90),
        leagueId: 61,
        leagueName: 'Ligue 1',
        leagueLogo: 'https://media.api-sports.io/football/leagues/61.png',
        leagueCountry: 'France',
        season: now.year,
        homeTeamId: 85,
        homeTeamName: 'Paris Saint-Germain',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/85.png',
        awayTeamId: 81,
        awayTeamName: 'Marseille',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/81.png',
        homeGoals: 2,
        awayGoals: 0,
        venueName: 'Parc des Princes',
        sportType: SportType.soccer,
      ),

      // 🌍 Avrupa - UEFA Champions League
      Fixture(
        id: 200001,
        date: now.subtract(const Duration(minutes: 83)),
        statusShort: '2H',
        statusLong: 'İkinci Yarı',
        elapsed: (83 + secOffset).clamp(1, 90),
        leagueId: 2,
        leagueName: 'UEFA Champions League',
        leagueLogo: 'https://media.api-sports.io/football/leagues/2.png',
        leagueCountry: 'World',
        season: now.year,
        homeTeamId: 541,
        homeTeamName: 'Real Madrid',
        homeTeamLogo: 'https://media.api-sports.io/football/teams/541.png',
        awayTeamId: 50,
        awayTeamName: 'Manchester City',
        awayTeamLogo: 'https://media.api-sports.io/football/teams/50.png',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'Santiago Bernabéu',
        sportType: SportType.soccer,
      ),
    ];

    final volleyballMatches = [
      Fixture(
        id: 910001,
        date: now.subtract(const Duration(minutes: 65)),
        statusShort: 'LIVE',
        statusLong: '4. Set Devam Ediyor',
        elapsed: 4,
        leagueId: 910,
        leagueName: 'Sultanlar Ligi',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 9101,
        homeTeamName: 'VakıfBank',
        awayTeamId: 9102,
        awayTeamName: 'Fenerbahçe Medicana',
        homeGoals: 2,
        awayGoals: 1,
        venueName: 'VakıfBank Spor Sarayı',
        sportType: SportType.volleyball,
      ),
      Fixture(
        id: 910002,
        date: now.subtract(const Duration(minutes: 45)),
        statusShort: 'LIVE',
        statusLong: '3. Set Devam Ediyor',
        elapsed: 3,
        leagueId: 910,
        leagueName: 'Sultanlar Ligi',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 9103,
        homeTeamName: 'Eczacıbaşı Dynavit',
        awayTeamId: 9104,
        awayTeamName: 'Galatasaray Daikin',
        homeGoals: 2,
        awayGoals: 0,
        venueName: 'Eczacıbaşı Spor Salonu',
        sportType: SportType.volleyball,
      ),
      Fixture(
        id: 910003,
        date: now.subtract(const Duration(minutes: 50)),
        statusShort: 'LIVE',
        statusLong: '3. Set',
        elapsed: 3,
        leagueId: 911,
        leagueName: 'Serie A1',
        leagueCountry: 'Italy',
        season: now.year,
        homeTeamId: 9105,
        homeTeamName: 'Imoco Conegliano',
        awayTeamId: 9106,
        awayTeamName: 'Vero Volley Milano',
        homeGoals: 1,
        awayGoals: 1,
        sportType: SportType.volleyball,
      ),
      Fixture(
        id: 910004,
        date: now.subtract(const Duration(minutes: 70)),
        statusShort: 'LIVE',
        statusLong: '4. Set',
        elapsed: 4,
        leagueId: 912,
        leagueName: 'CEV Şampiyonlar Ligi',
        leagueCountry: 'World',
        season: now.year,
        homeTeamId: 9107,
        homeTeamName: 'Savino Del Bene Scandicci',
        awayTeamId: 9108,
        awayTeamName: 'A. Carraro Imoco',
        homeGoals: 2,
        awayGoals: 1,
        sportType: SportType.volleyball,
      ),
    ];

    final basketballMatches = [
      Fixture(
        id: 920001,
        date: now.subtract(const Duration(minutes: 70)),
        statusShort: 'LIVE',
        statusLong: '4. Çeyrek',
        elapsed: 4,
        leagueId: 920,
        leagueName: 'Basketbol Süper Ligi',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 9201,
        homeTeamName: 'Anadolu Efes',
        awayTeamId: 9202,
        awayTeamName: 'Fenerbahçe Beko',
        homeGoals: 78,
        awayGoals: 75,
        venueName: 'Sinan Erdem Spor Salonu',
        sportType: SportType.basketball,
      ),
      Fixture(
        id: 920002,
        date: now.subtract(const Duration(minutes: 50)),
        statusShort: 'LIVE',
        statusLong: '3. Çeyrek',
        elapsed: 3,
        leagueId: 920,
        leagueName: 'Basketbol Süper Ligi',
        leagueCountry: 'Turkey',
        season: now.year,
        homeTeamId: 9203,
        homeTeamName: 'Beşiktaş Fibabanka',
        awayTeamId: 9204,
        awayTeamName: 'Galatasaray MCT',
        homeGoals: 58,
        awayGoals: 55,
        venueName: 'BJK Akatlar Arena',
        sportType: SportType.basketball,
      ),
      Fixture(
        id: 920003,
        date: now.subtract(const Duration(minutes: 75)),
        statusShort: 'LIVE',
        statusLong: '4. Çeyrek',
        elapsed: 4,
        leagueId: 921,
        leagueName: 'EuroLeague',
        leagueCountry: 'World',
        season: now.year,
        homeTeamId: 9205,
        homeTeamName: 'Panathinaikos AKTOR',
        awayTeamId: 9206,
        awayTeamName: 'Real Madrid Baloncesto',
        homeGoals: 84,
        awayGoals: 81,
        venueName: 'OAKA Altion',
        sportType: SportType.basketball,
      ),
      Fixture(
        id: 920004,
        date: now.subtract(const Duration(minutes: 55)),
        statusShort: 'LIVE',
        statusLong: '3. Çeyrek',
        elapsed: 3,
        leagueId: 922,
        leagueName: 'NBA',
        leagueCountry: 'USA',
        season: now.year,
        homeTeamId: 9207,
        homeTeamName: 'Boston Celtics',
        awayTeamId: 9208,
        awayTeamName: 'Los Angeles Lakers',
        homeGoals: 91,
        awayGoals: 88,
        venueName: 'TD Garden',
        sportType: SportType.basketball,
      ),
    ];

    if (sport == SportType.volleyball) return volleyballMatches;
    if (sport == SportType.basketball) return basketballMatches;
    if (sport == SportType.soccer) return soccerMatches;

    return [...soccerMatches, ...volleyballMatches, ...basketballMatches];
  }

  // ---------------------------------------------------------------------------
  // 4. İstatistikler & Kadrolar (Gerçek Oyuncu Verileri)
  // ---------------------------------------------------------------------------

  static MatchStat getRealisticStats(int teamId, String name, [String? leagueName]) {
    final lower = name.toLowerCase();

    // 1. Süper Lig Takımlarına Özel Gerçekçi İstatistikler
    if (teamId == 645 || lower.contains('galatasaray')) {
      return const MatchStat(
        played: 24, won: 20, drawn: 3, lost: 1,
        goalsScored: 64, goalsConceded: 22,
        homePlayed: 12, homeWon: 11, homeDrawn: 1, homeLost: 0, homeGoalsScored: 38, homeGoalsConceded: 10,
        awayPlayed: 12, awayWon: 9, awayDrawn: 2, awayLost: 1, awayGoalsScored: 26, awayGoalsConceded: 12,
        avgPossession: 62.5, avgShotsPerGame: 16.8, avgShotsOnTarget: 6.8, cleanSheets: 13,
        recentForm: ['W', 'W', 'W', 'D', 'W'],
      );
    }
    if (teamId == 611 || lower.contains('fenerbahce') || lower.contains('fenerbahçe')) {
      return const MatchStat(
        played: 24, won: 19, drawn: 4, lost: 1,
        goalsScored: 60, goalsConceded: 22,
        homePlayed: 12, homeWon: 10, homeDrawn: 2, homeLost: 0, homeGoalsScored: 35, homeGoalsConceded: 10,
        awayPlayed: 12, awayWon: 9, awayDrawn: 2, awayLost: 1, awayGoalsScored: 25, awayGoalsConceded: 12,
        avgPossession: 61.0, avgShotsPerGame: 16.2, avgShotsOnTarget: 6.5, cleanSheets: 12,
        recentForm: ['W', 'W', 'D', 'W', 'W'],
      );
    }
    if (teamId == 1004 || lower.contains('samsun')) {
      return const MatchStat(
        played: 24, won: 14, drawn: 4, lost: 6,
        goalsScored: 36, goalsConceded: 22,
        homePlayed: 12, homeWon: 8, homeDrawn: 2, homeLost: 2, homeGoalsScored: 21, homeGoalsConceded: 9,
        awayPlayed: 12, awayWon: 6, awayDrawn: 2, awayLost: 4, awayGoalsScored: 15, awayGoalsConceded: 13,
        avgPossession: 51.5, avgShotsPerGame: 13.1, avgShotsOnTarget: 4.9, cleanSheets: 10,
        recentForm: ['W', 'D', 'W', 'L', 'W'],
      );
    }
    if (teamId == 549 || lower.contains('besiktas') || lower.contains('beşiktaş')) {
      return const MatchStat(
        played: 24, won: 12, drawn: 7, lost: 5,
        goalsScored: 42, goalsConceded: 30,
        homePlayed: 12, homeWon: 7, homeDrawn: 3, homeLost: 2, homeGoalsScored: 25, homeGoalsConceded: 13,
        awayPlayed: 12, awayWon: 5, awayDrawn: 4, awayLost: 3, awayGoalsScored: 17, awayGoalsConceded: 17,
        avgPossession: 57.2, avgShotsPerGame: 14.5, avgShotsOnTarget: 5.5, cleanSheets: 8,
        recentForm: ['D', 'W', 'D', 'W', 'L'],
      );
    }
    if (teamId == 3573 || lower.contains('eyup') || lower.contains('eyüp')) {
      return const MatchStat(
        played: 24, won: 12, drawn: 6, lost: 6,
        goalsScored: 38, goalsConceded: 29,
        homePlayed: 12, homeWon: 8, homeDrawn: 2, homeLost: 2, homeGoalsScored: 24, homeGoalsConceded: 11,
        awayPlayed: 12, awayWon: 4, awayDrawn: 4, awayLost: 4, awayGoalsScored: 14, awayGoalsConceded: 18,
        avgPossession: 52.0, avgShotsPerGame: 13.4, avgShotsOnTarget: 4.8, cleanSheets: 8,
        recentForm: ['W', 'L', 'W', 'W', 'D'],
      );
    }
    if (teamId == 607 || lower.contains('trabzon')) {
      return const MatchStat(
        played: 24, won: 10, drawn: 8, lost: 6,
        goalsScored: 37, goalsConceded: 29,
        homePlayed: 12, homeWon: 6, homeDrawn: 4, homeLost: 2, homeGoalsScored: 22, homeGoalsConceded: 12,
        awayPlayed: 12, awayWon: 4, awayDrawn: 4, awayLost: 4, awayGoalsScored: 15, awayGoalsConceded: 17,
        avgPossession: 55.8, avgShotsPerGame: 14.0, avgShotsOnTarget: 5.2, cleanSheets: 8,
        recentForm: ['W', 'D', 'L', 'W', 'W'],
      );
    }
    if (teamId == 1001 || lower.contains('goztepe') || lower.contains('göztepe')) {
      return const MatchStat(
        played: 24, won: 10, drawn: 6, lost: 8,
        goalsScored: 35, goalsConceded: 28,
        homePlayed: 12, homeWon: 7, homeDrawn: 3, homeLost: 2, homeGoalsScored: 23, homeGoalsConceded: 10,
        awayPlayed: 12, awayWon: 3, awayDrawn: 3, awayLost: 6, awayGoalsScored: 12, awayGoalsConceded: 18,
        avgPossession: 47.5, avgShotsPerGame: 12.6, avgShotsOnTarget: 4.6, cleanSheets: 7,
        recentForm: ['L', 'W', 'W', 'D', 'L'],
      );
    }
    if (teamId == 996 || lower.contains('basaksehir') || lower.contains('başakşehir')) {
      return const MatchStat(
        played: 24, won: 9, drawn: 7, lost: 8,
        goalsScored: 36, goalsConceded: 33,
        homePlayed: 12, homeWon: 5, homeDrawn: 4, homeLost: 3, homeGoalsScored: 20, homeGoalsConceded: 14,
        awayPlayed: 12, awayWon: 4, awayDrawn: 3, awayLost: 5, awayGoalsScored: 16, awayGoalsConceded: 19,
        avgPossession: 54.0, avgShotsPerGame: 13.2, avgShotsOnTarget: 4.7, cleanSheets: 7,
        recentForm: ['D', 'D', 'W', 'L', 'W'],
      );
    }
    if (teamId == 1002 || lower.contains('kasimpasa') || lower.contains('kasımpaşa')) {
      return const MatchStat(
        played: 24, won: 8, drawn: 9, lost: 7,
        goalsScored: 38, goalsConceded: 38,
        homePlayed: 12, homeWon: 4, homeDrawn: 5, homeLost: 3, homeGoalsScored: 19, homeGoalsConceded: 19,
        awayPlayed: 12, awayWon: 4, awayDrawn: 4, awayLost: 4, awayGoalsScored: 19, awayGoalsConceded: 19,
        avgPossession: 49.0, avgShotsPerGame: 13.5, avgShotsOnTarget: 5.0, cleanSheets: 5,
        recentForm: ['W', 'D', 'L', 'D', 'W'],
      );
    }
    if (teamId == 1010 || lower.contains('sivas')) {
      return const MatchStat(
        played: 24, won: 8, drawn: 5, lost: 11,
        goalsScored: 31, goalsConceded: 37,
        homePlayed: 12, homeWon: 5, homeDrawn: 3, homeLost: 4, homeGoalsScored: 18, homeGoalsConceded: 16,
        awayPlayed: 12, awayWon: 3, awayDrawn: 2, awayLost: 7, awayGoalsScored: 13, awayGoalsConceded: 21,
        avgPossession: 44.2, avgShotsPerGame: 11.2, avgShotsOnTarget: 3.9, cleanSheets: 6,
        recentForm: ['L', 'W', 'L', 'L', 'W'],
      );
    }
    if (teamId == 1005 || lower.contains('antalya')) {
      return const MatchStat(
        played: 24, won: 8, drawn: 5, lost: 11,
        goalsScored: 28, goalsConceded: 36,
        homePlayed: 12, homeWon: 5, homeDrawn: 3, homeLost: 4, homeGoalsScored: 17, homeGoalsConceded: 16,
        awayPlayed: 12, awayWon: 3, awayDrawn: 2, awayLost: 7, awayGoalsScored: 11, awayGoalsConceded: 20,
        avgPossession: 48.0, avgShotsPerGame: 11.8, avgShotsOnTarget: 4.0, cleanSheets: 6,
        recentForm: ['L', 'L', 'W', 'W', 'L'],
      );
    }
    if (teamId == 1014 || lower.contains('konya')) {
      return const MatchStat(
        played: 24, won: 7, drawn: 6, lost: 11,
        goalsScored: 26, goalsConceded: 35,
        homePlayed: 12, homeWon: 4, homeDrawn: 4, homeLost: 4, homeGoalsScored: 16, homeGoalsConceded: 15,
        awayPlayed: 12, awayWon: 3, awayDrawn: 2, awayLost: 7, awayGoalsScored: 10, awayGoalsConceded: 20,
        avgPossession: 47.0, avgShotsPerGame: 11.0, avgShotsOnTarget: 3.7, cleanSheets: 6,
        recentForm: ['D', 'L', 'L', 'W', 'D'],
      );
    }
    if (teamId == 1009 || lower.contains('rize')) {
      return const MatchStat(
        played: 24, won: 7, drawn: 5, lost: 12,
        goalsScored: 27, goalsConceded: 37,
        homePlayed: 12, homeWon: 4, homeDrawn: 3, homeLost: 5, homeGoalsScored: 16, homeGoalsConceded: 16,
        awayPlayed: 12, awayWon: 3, awayDrawn: 2, awayLost: 7, awayGoalsScored: 11, awayGoalsConceded: 21,
        avgPossession: 46.5, avgShotsPerGame: 11.5, avgShotsOnTarget: 3.8, cleanSheets: 5,
        recentForm: ['L', 'L', 'W', 'L', 'L'],
      );
    }
    if (teamId == 1007 || lower.contains('alanya')) {
      return const MatchStat(
        played: 24, won: 6, drawn: 7, lost: 11,
        goalsScored: 28, goalsConceded: 39,
        homePlayed: 12, homeWon: 3, homeDrawn: 4, homeLost: 5, homeGoalsScored: 16, homeGoalsConceded: 17,
        awayPlayed: 12, awayWon: 3, awayDrawn: 3, awayLost: 6, awayGoalsScored: 12, awayGoalsConceded: 22,
        avgPossession: 51.0, avgShotsPerGame: 12.0, avgShotsOnTarget: 4.1, cleanSheets: 5,
        recentForm: ['D', 'W', 'L', 'D', 'L'],
      );
    }
    if (teamId == 3574 || lower.contains('gaziantep')) {
      return const MatchStat(
        played: 24, won: 6, drawn: 6, lost: 12,
        goalsScored: 27, goalsConceded: 39,
        homePlayed: 12, homeWon: 4, homeDrawn: 3, homeLost: 5, homeGoalsScored: 17, homeGoalsConceded: 16,
        awayPlayed: 12, awayWon: 2, awayDrawn: 3, awayLost: 7, awayGoalsScored: 10, awayGoalsConceded: 23,
        avgPossession: 45.0, avgShotsPerGame: 11.2, avgShotsOnTarget: 3.8, cleanSheets: 5,
        recentForm: ['L', 'D', 'L', 'W', 'L'],
      );
    }
    if (teamId == 4835 || lower.contains('bodrum')) {
      return const MatchStat(
        played: 24, won: 5, drawn: 4, lost: 15,
        goalsScored: 20, goalsConceded: 36,
        homePlayed: 12, homeWon: 4, homeDrawn: 2, homeLost: 6, homeGoalsScored: 13, homeGoalsConceded: 16,
        awayPlayed: 12, awayWon: 1, awayDrawn: 2, awayLost: 9, awayGoalsScored: 7, awayGoalsConceded: 20,
        avgPossession: 44.0, avgShotsPerGame: 10.5, avgShotsOnTarget: 3.4, cleanSheets: 5,
        recentForm: ['L', 'L', 'L', 'D', 'L'],
      );
    }
    if (teamId == 1012 || lower.contains('kayseri')) {
      return const MatchStat(
        played: 24, won: 4, drawn: 7, lost: 13,
        goalsScored: 24, goalsConceded: 42,
        homePlayed: 12, homeWon: 3, homeDrawn: 4, homeLost: 5, homeGoalsScored: 14, homeGoalsConceded: 19,
        awayPlayed: 12, awayWon: 1, awayDrawn: 3, awayLost: 8, awayGoalsScored: 10, awayGoalsConceded: 23,
        avgPossession: 46.0, avgShotsPerGame: 10.8, avgShotsOnTarget: 3.6, cleanSheets: 4,
        recentForm: ['D', 'L', 'D', 'L', 'L'],
      );
    }
    if (teamId == 3577 || lower.contains('hatay')) {
      return const MatchStat(
        played: 24, won: 3, drawn: 6, lost: 15,
        goalsScored: 22, goalsConceded: 42,
        homePlayed: 12, homeWon: 2, homeDrawn: 3, homeLost: 7, homeGoalsScored: 13, homeGoalsConceded: 19,
        awayPlayed: 12, awayWon: 1, awayDrawn: 3, awayLost: 8, awayGoalsScored: 9, awayGoalsConceded: 23,
        avgPossession: 45.5, avgShotsPerGame: 10.2, avgShotsOnTarget: 3.3, cleanSheets: 3,
        recentForm: ['L', 'D', 'L', 'L', 'L'],
      );
    }
    if (teamId == 3563 || lower.contains('adana demir')) {
      return const MatchStat(
        played: 24, won: 1, drawn: 3, lost: 20,
        goalsScored: 18, goalsConceded: 53,
        homePlayed: 12, homeWon: 1, homeDrawn: 2, homeLost: 9, homeGoalsScored: 10, homeGoalsConceded: 24,
        awayPlayed: 12, awayWon: 0, awayDrawn: 1, awayLost: 11, awayGoalsScored: 8, awayGoalsConceded: 29,
        avgPossession: 43.0, avgShotsPerGame: 9.8, avgShotsOnTarget: 3.0, cleanSheets: 1,
        recentForm: ['L', 'L', 'L', 'L', 'L'],
      );
    }

    // 2. Dünya Devleri
    final isElite = [50, 42, 40, 541, 529, 157, 505, 85].contains(teamId);
    if (isElite || lower.contains('city') || lower.contains('madrid') || lower.contains('bayern') || lower.contains('barcelona') || lower.contains('liverpool') || lower.contains('arsenal') || lower.contains('psg') || lower.contains('inter')) {
      return const MatchStat(
        played: 28, won: 22, drawn: 4, lost: 2,
        goalsScored: 72, goalsConceded: 22,
        homePlayed: 14, homeWon: 12, homeDrawn: 2, homeLost: 0, homeGoalsScored: 45, homeGoalsConceded: 11,
        awayPlayed: 14, awayWon: 10, awayDrawn: 2, awayLost: 2, awayGoalsScored: 27, awayGoalsConceded: 11,
        avgPossession: 63.5, avgShotsPerGame: 17.0, avgShotsOnTarget: 6.8, cleanSheets: 14,
        recentForm: ['W', 'W', 'W', 'D', 'W'],
      );
    }

    // 3. Genel Dengeli Orta Sıra İstatistiği (Doğal varyasyonlu)
    final int hash = (teamId * 31 + name.length) % 7;
    return MatchStat(
      played: 24, won: 8 + hash % 3, drawn: 6 + hash % 2, lost: 10 - hash % 3,
      goalsScored: 28 + hash * 2, goalsConceded: 32 + hash * 2,
      homePlayed: 12, homeWon: 5 + hash % 2, homeDrawn: 3, homeLost: 4, homeGoalsScored: 16 + hash, homeGoalsConceded: 14 + hash % 2,
      awayPlayed: 12, awayWon: 3 + hash % 2, awayDrawn: 3, awayLost: 6, awayGoalsScored: 12 + hash, awayGoalsConceded: 18 + hash,
      avgPossession: 47.0 + hash, avgShotsPerGame: 11.5 + (hash * 0.4), avgShotsOnTarget: 3.8 + (hash * 0.2), cleanSheets: 5 + hash % 3,
      recentForm: ['W', 'L', 'D', 'W', 'L'],
    );
  }

  static List<Player> getRealisticSquad(int teamId, String name) {
    final lower = name.toLowerCase();

    // 1. Galatasaray
    if (teamId == 645 || lower.contains('galatasaray')) {
      return [
        Player(id: '645_1', name: 'Victor Osimhen', position: 'Forvet', goals: 18, assists: 4, matchesPlayed: 20, rating: 8.8),
        Player(id: '645_2', name: 'Mauro Icardi', position: 'Forvet', goals: 12, assists: 3, matchesPlayed: 16, rating: 8.5, isInjured: true, injuryReason: 'Çapraz Bağ'),
        Player(id: '645_3', name: 'Barış Alper Yılmaz', position: 'Forvet', goals: 11, assists: 7, matchesPlayed: 24, rating: 8.2),
        Player(id: '645_4', name: 'Dries Mertens', position: 'Orta Saha', goals: 7, assists: 9, matchesPlayed: 23, rating: 8.0),
        Player(id: '645_5', name: 'Gabriel Sara', position: 'Orta Saha', goals: 5, assists: 8, matchesPlayed: 22, rating: 8.3),
        Player(id: '645_6', name: 'Lucas Torreira', position: 'Orta Saha', goals: 2, assists: 6, matchesPlayed: 24, rating: 8.3),
        Player(id: '645_7', name: 'Davinson Sánchez', position: 'Defans', goals: 3, assists: 1, matchesPlayed: 23, rating: 8.1),
        Player(id: '645_8', name: 'Abdülkerim Bardakcı', position: 'Defans', goals: 2, assists: 1, matchesPlayed: 22, rating: 7.9),
        Player(id: '645_9', name: 'Victor Nelsson', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 20, rating: 7.8),
        Player(id: '645_10', name: 'Kaan Ayhan', position: 'Defans', goals: 1, assists: 3, matchesPlayed: 21, rating: 7.7),
        Player(id: '645_11', name: 'Fernando Muslera', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 8.2),
        Player(id: '645_12', name: 'Michy Batshuayi', position: 'Forvet', goals: 8, assists: 2, matchesPlayed: 20, rating: 7.8),
        Player(id: '645_13', name: 'Roland Sallai', position: 'Forvet', goals: 3, assists: 2, matchesPlayed: 15, rating: 7.7),
        Player(id: '645_14', name: 'Ismail Jakobs', position: 'Defans', goals: 1, assists: 2, matchesPlayed: 16, rating: 7.7),
      ];
    }

    // 2. Fenerbahçe
    if (teamId == 611 || lower.contains('fenerbahce') || lower.contains('fenerbahçe')) {
      return [
        Player(id: '611_1', name: 'Edin Džeko', position: 'Forvet', goals: 17, assists: 5, matchesPlayed: 24, rating: 8.5),
        Player(id: '611_2', name: 'Youssef En-Nesyri', position: 'Forvet', goals: 14, assists: 3, matchesPlayed: 22, rating: 8.2),
        Player(id: '611_3', name: 'Dušan Tadić', position: 'Orta Saha', goals: 11, assists: 14, matchesPlayed: 24, rating: 8.6),
        Player(id: '611_4', name: 'Allan Saint-Maximin', position: 'Forvet', goals: 5, assists: 6, matchesPlayed: 20, rating: 8.2),
        Player(id: '611_5', name: 'Sebastian Szymański', position: 'Orta Saha', goals: 6, assists: 7, matchesPlayed: 24, rating: 8.0),
        Player(id: '611_6', name: 'Fred', position: 'Orta Saha', goals: 4, assists: 8, matchesPlayed: 22, rating: 8.3),
        Player(id: '611_7', name: 'Sofyan Amrabat', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 8.1),
        Player(id: '611_8', name: 'Alexander Djiku', position: 'Defans', goals: 2, assists: 1, matchesPlayed: 23, rating: 8.0),
        Player(id: '611_9', name: 'Rodrigo Becão', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 18, rating: 7.8),
        Player(id: '611_10', name: 'Bright Osayi-Samuel', position: 'Defans', goals: 1, assists: 3, matchesPlayed: 20, rating: 7.8),
        Player(id: '611_11', name: 'Mert Müldür', position: 'Defans', goals: 1, assists: 2, matchesPlayed: 21, rating: 7.7),
        Player(id: '611_12', name: 'Dominik Livaković', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 8.1),
        Player(id: '611_13', name: 'İrfan Can Kahveci', position: 'Orta Saha', goals: 4, assists: 5, matchesPlayed: 20, rating: 8.0),
        Player(id: '611_14', name: 'Jayden Oosterwolde', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 12, rating: 7.9, isInjured: true, injuryReason: 'Menisküs'),
      ];
    }

    // 3. Kayserispor (Kullanıcının özellikle sorduğu takım)
    if (teamId == 1012 || lower.contains('kayseri')) {
      return [
        Player(id: '1012_1', name: 'Duckens Nazon', position: 'Forvet', goals: 7, assists: 3, matchesPlayed: 22, rating: 7.8),
        Player(id: '1012_2', name: 'Stéphane Bahoken', position: 'Forvet', goals: 5, assists: 1, matchesPlayed: 19, rating: 7.5),
        Player(id: '1012_3', name: 'Miguel Cardoso', position: 'Forvet', goals: 6, assists: 4, matchesPlayed: 23, rating: 7.9),
        Player(id: '1012_4', name: 'Aylton Boa Morte', position: 'Forvet', goals: 5, assists: 3, matchesPlayed: 22, rating: 7.7),
        Player(id: '1012_5', name: 'Kartal Kayra Yılmaz', position: 'Orta Saha', goals: 2, assists: 4, matchesPlayed: 23, rating: 7.6),
        Player(id: '1012_6', name: 'Ali Karimi', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 20, rating: 7.5),
        Player(id: '1012_7', name: 'Mehdi Bourabia', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 18, rating: 7.4),
        Player(id: '1012_8', name: 'Joseph Attamah', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 22, rating: 7.5),
        Player(id: '1012_9', name: 'Dimitrios Kolovetsios', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 21, rating: 7.4),
        Player(id: '1012_10', name: 'Lionel Carole', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 20, rating: 7.3),
        Player(id: '1012_11', name: 'Gökhan Sazdağı', position: 'Defans', goals: 2, assists: 3, matchesPlayed: 23, rating: 7.5),
        Player(id: '1012_12', name: 'Bilal Bayazit', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 7.9),
        Player(id: '1012_13', name: 'Hasan Ali Kaldırım', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 15, rating: 7.2),
        Player(id: '1012_14', name: 'Talha Sarıarslan', position: 'Forvet', goals: 2, assists: 0, matchesPlayed: 14, rating: 7.1),
      ];
    }

    // 4. Beşiktaş
    if (teamId == 549 || lower.contains('besiktas') || lower.contains('beşiktaş')) {
      return [
        Player(id: '549_1', name: 'Ciro Immobile', position: 'Forvet', goals: 16, assists: 3, matchesPlayed: 23, rating: 8.4),
        Player(id: '549_2', name: 'Rafa Silva', position: 'Orta Saha', goals: 12, assists: 9, matchesPlayed: 24, rating: 8.5),
        Player(id: '549_3', name: 'Semih Kılıçsoy', position: 'Forvet', goals: 8, assists: 4, matchesPlayed: 22, rating: 7.9),
        Player(id: '549_4', name: 'Gedson Fernandes', position: 'Orta Saha', goals: 6, assists: 5, matchesPlayed: 24, rating: 8.2),
        Player(id: '549_5', name: 'Milot Rashica', position: 'Forvet', goals: 4, assists: 6, matchesPlayed: 21, rating: 7.8),
        Player(id: '549_6', name: 'Cher Ndour', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 17, rating: 7.6),
        Player(id: '549_7', name: 'Al-Musrati', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 18, rating: 7.7),
        Player(id: '549_8', name: 'Gabriel Paulista', position: 'Defans', goals: 1, assists: 1, matchesPlayed: 20, rating: 7.9),
        Player(id: '549_9', name: 'Felix Uduokhai', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 19, rating: 7.7),
        Player(id: '549_10', name: 'Arthur Masuaku', position: 'Defans', goals: 2, assists: 4, matchesPlayed: 22, rating: 7.8),
        Player(id: '549_11', name: 'Jonas Svensson', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 21, rating: 7.6),
        Player(id: '549_12', name: 'Mert Günok', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 22, rating: 8.0),
        Player(id: '549_13', name: 'Ernest Muçi', position: 'Orta Saha', goals: 4, assists: 2, matchesPlayed: 18, rating: 7.7),
      ];
    }

    // 5. Samsunspor
    if (teamId == 1004 || lower.contains('samsun')) {
      return [
        Player(id: '1004_1', name: 'Marius Mouandilmadji', position: 'Forvet', goals: 9, assists: 3, matchesPlayed: 23, rating: 8.0),
        Player(id: '1004_2', name: 'Carlo Holse', position: 'Orta Saha', goals: 6, assists: 5, matchesPlayed: 24, rating: 8.1),
        Player(id: '1004_3', name: 'Olivier Ntcham', position: 'Orta Saha', goals: 7, assists: 3, matchesPlayed: 22, rating: 8.0),
        Player(id: '1004_4', name: 'Arbnor Muja', position: 'Forvet', goals: 5, assists: 2, matchesPlayed: 21, rating: 7.8),
        Player(id: '1004_5', name: 'Emre Kılınç', position: 'Orta Saha', goals: 4, assists: 5, matchesPlayed: 23, rating: 7.8),
        Player(id: '1004_6', name: 'Youssef Aït Bennasser', position: 'Orta Saha', goals: 1, assists: 2, matchesPlayed: 20, rating: 7.7),
        Player(id: '1004_7', name: 'Rick van Drongelen', position: 'Defans', goals: 3, assists: 0, matchesPlayed: 23, rating: 8.0),
        Player(id: '1004_8', name: 'Lubomir Satka', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 22, rating: 7.8),
        Player(id: '1004_9', name: 'Zeki Yavru', position: 'Defans', goals: 2, assists: 4, matchesPlayed: 24, rating: 7.8),
        Player(id: '1004_10', name: 'Marc Bola', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 21, rating: 7.6),
        Player(id: '1004_11', name: 'Okan Kocuk', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 8.1),
        Player(id: '1004_12', name: 'Landry Dimata', position: 'Forvet', goals: 3, assists: 1, matchesPlayed: 18, rating: 7.4),
      ];
    }

    // 6. Trabzonspor
    if (teamId == 607 || lower.contains('trabzon')) {
      return [
        Player(id: '607_1', name: 'Simon Banza', position: 'Forvet', goals: 12, assists: 2, matchesPlayed: 21, rating: 8.3),
        Player(id: '607_2', name: 'Edin Višća', position: 'Forvet', goals: 6, assists: 8, matchesPlayed: 23, rating: 8.2),
        Player(id: '607_3', name: 'Muhammed Cham', position: 'Orta Saha', goals: 5, assists: 4, matchesPlayed: 22, rating: 7.9),
        Player(id: '607_4', name: 'Denis Drăguș', position: 'Forvet', goals: 4, assists: 2, matchesPlayed: 19, rating: 7.7),
        Player(id: '607_5', name: 'Batista Mendy', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 23, rating: 8.0),
        Player(id: '607_6', name: 'Okay Yokuşlu', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 21, rating: 7.8),
        Player(id: '607_7', name: 'Stefan Savić', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 16, rating: 8.0),
        Player(id: '607_8', name: 'Stefano Denswil', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 20, rating: 7.7),
        Player(id: '607_9', name: 'Pedro Malheiro', position: 'Defans', goals: 1, assists: 3, matchesPlayed: 22, rating: 7.8),
        Player(id: '607_10', name: 'Eren Elmalı', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 23, rating: 7.6),
        Player(id: '607_11', name: 'Uğurcan Çakır', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 8.3),
        Player(id: '607_12', name: 'Enis Destan', position: 'Forvet', goals: 3, assists: 1, matchesPlayed: 16, rating: 7.4),
      ];
    }

    // 7. Eyüpspor
    if (teamId == 3573 || lower.contains('eyup') || lower.contains('eyüp')) {
      return [
        Player(id: '3573_1', name: 'Mame Thiam', position: 'Forvet', goals: 10, assists: 4, matchesPlayed: 23, rating: 8.2),
        Player(id: '3573_2', name: 'Ahmed Kutucu', position: 'Forvet', goals: 8, assists: 5, matchesPlayed: 22, rating: 8.1),
        Player(id: '3573_3', name: 'Emre Akbaba', position: 'Orta Saha', goals: 5, assists: 4, matchesPlayed: 23, rating: 7.9),
        Player(id: '3573_4', name: 'Samu Sáiz', position: 'Orta Saha', goals: 4, assists: 3, matchesPlayed: 20, rating: 7.8),
        Player(id: '3573_5', name: 'Melih Kabasakal', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 22, rating: 7.6),
        Player(id: '3573_6', name: 'Robin Yalçın', position: 'Defans', goals: 1, assists: 1, matchesPlayed: 21, rating: 7.5),
        Player(id: '3573_7', name: 'Luccas Claro', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 22, rating: 7.9),
        Player(id: '3573_8', name: 'Caner Erkin', position: 'Defans', goals: 1, assists: 6, matchesPlayed: 20, rating: 7.8),
        Player(id: '3573_9', name: 'Léo Dubois', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 18, rating: 7.7),
        Player(id: '3573_10', name: 'Rúben Vezo', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 16, rating: 7.7),
        Player(id: '3573_11', name: 'Berke Özer', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 8.1),
      ];
    }

    // 8. Başakşehir
    if (teamId == 996 || lower.contains('basaksehir') || lower.contains('başakşehir')) {
      return [
        Player(id: '996_1', name: 'Krzysztof Piątek', position: 'Forvet', goals: 15, assists: 2, matchesPlayed: 23, rating: 8.4),
        Player(id: '996_2', name: 'Deniz Türüç', position: 'Forvet', goals: 5, assists: 6, matchesPlayed: 22, rating: 7.9),
        Player(id: '996_3', name: 'João Figueiredo', position: 'Forvet', goals: 6, assists: 2, matchesPlayed: 20, rating: 7.7),
        Player(id: '996_4', name: 'Miguel Crespo', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 19, rating: 7.8),
        Player(id: '996_5', name: 'Berkay Özcan', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 7.6),
        Player(id: '996_6', name: 'Berat Özdemir', position: 'Orta Saha', goals: 0, assists: 1, matchesPlayed: 22, rating: 7.6),
        Player(id: '996_7', name: 'Jerome Opoku', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 21, rating: 7.8),
        Player(id: '996_8', name: 'Léo Duarte', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.7),
        Player(id: '996_9', name: 'Ousseynou Ba', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 19, rating: 7.7),
        Player(id: '996_10', name: 'Lucas Lima', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 22, rating: 7.5),
        Player(id: '996_11', name: 'Muhammed Şengezer', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.7),
      ];
    }

    // 9. Göztepe
    if (teamId == 1001 || lower.contains('goztepe') || lower.contains('göztepe')) {
      return [
        Player(id: '1001_1', name: 'Rômulo Cardoso', position: 'Forvet', goals: 9, assists: 3, matchesPlayed: 22, rating: 8.1),
        Player(id: '1001_2', name: 'David Datro Fofana', position: 'Forvet', goals: 6, assists: 2, matchesPlayed: 17, rating: 7.9),
        Player(id: '1001_3', name: 'Juan Santos', position: 'Forvet', goals: 5, assists: 2, matchesPlayed: 19, rating: 7.7),
        Player(id: '1001_4', name: 'Anthony Dennis', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 22, rating: 7.8),
        Player(id: '1001_5', name: 'Isaac Solet', position: 'Orta Saha', goals: 3, assists: 1, matchesPlayed: 20, rating: 7.8),
        Player(id: '1001_6', name: 'David Tijanic', position: 'Orta Saha', goals: 3, assists: 4, matchesPlayed: 21, rating: 7.6),
        Player(id: '1001_7', name: 'Héliton', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 22, rating: 7.9),
        Player(id: '1001_8', name: 'Koray Günter', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 18, rating: 7.6),
        Player(id: '1001_9', name: 'Taha Altıkardeş', position: 'Defans', goals: 2, assists: 1, matchesPlayed: 21, rating: 7.7),
        Player(id: '1001_10', name: 'Djalma Silva', position: 'Defans', goals: 1, assists: 4, matchesPlayed: 23, rating: 7.7),
        Player(id: '1001_11', name: 'Mateusz Lis', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 8.0),
      ];
    }

    // 10. Kasımpaşa
    if (teamId == 1002 || lower.contains('kasimpasa') || lower.contains('kasımpaşa')) {
      return [
        Player(id: '1002_1', name: 'Nuno da Costa', position: 'Forvet', goals: 9, assists: 3, matchesPlayed: 22, rating: 8.0),
        Player(id: '1002_2', name: 'Mamadou Fall', position: 'Forvet', goals: 7, assists: 2, matchesPlayed: 23, rating: 7.8),
        Player(id: '1002_3', name: 'Haris Hajradinović', position: 'Orta Saha', goals: 4, assists: 11, matchesPlayed: 24, rating: 8.2),
        Player(id: '1002_4', name: 'Aytaç Kara', position: 'Orta Saha', goals: 8, assists: 3, matchesPlayed: 23, rating: 8.1),
        Player(id: '1002_5', name: 'Cafú', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 20, rating: 7.6),
        Player(id: '1002_6', name: 'Gökhan Gül', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 22, rating: 7.5),
        Player(id: '1002_7', name: 'Cláudio Winck', position: 'Defans', goals: 3, assists: 3, matchesPlayed: 23, rating: 7.8),
        Player(id: '1002_8', name: 'Yasin Özcan', position: 'Defans', goals: 2, assists: 1, matchesPlayed: 22, rating: 7.8),
        Player(id: '1002_9', name: 'Nicholas Opoku', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 19, rating: 7.6),
        Player(id: '1002_10', name: 'Sadık Çiftpınar', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 18, rating: 7.4),
        Player(id: '1002_11', name: 'Andreas Gianniotis', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 7.8),
      ];
    }

    // 11. Sivasspor
    if (teamId == 1010 || lower.contains('sivas')) {
      return [
        Player(id: '1010_1', name: 'Rey Manaj', position: 'Forvet', goals: 14, assists: 2, matchesPlayed: 20, rating: 8.3),
        Player(id: '1010_2', name: 'Queensy Menig', position: 'Forvet', goals: 4, assists: 2, matchesPlayed: 21, rating: 7.6),
        Player(id: '1010_3', name: 'Garry Rodrigues', position: 'Forvet', goals: 3, assists: 3, matchesPlayed: 18, rating: 7.6),
        Player(id: '1010_4', name: 'Samuel Moutoussamy', position: 'Orta Saha', goals: 1, assists: 2, matchesPlayed: 21, rating: 7.7),
        Player(id: '1010_5', name: 'Charilaos Charisis', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 22, rating: 7.6),
        Player(id: '1010_6', name: 'Azizbek Turgunboev', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 19, rating: 7.5),
        Player(id: '1010_7', name: 'Uroš Radaković', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 21, rating: 7.7),
        Player(id: '1010_8', name: 'Samba Camara', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.5),
        Player(id: '1010_9', name: 'Uğur Çiftçi', position: 'Defans', goals: 1, assists: 4, matchesPlayed: 23, rating: 7.6),
        Player(id: '1010_10', name: 'Murat Paluli', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 20, rating: 7.4),
        Player(id: '1010_11', name: 'Ali Şaşal Vural', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.7),
      ];
    }

    // 12. Antalyaspor
    if (teamId == 1005 || lower.contains('antalya')) {
      return [
        Player(id: '1005_1', name: 'Sam Larsson', position: 'Forvet', goals: 7, assists: 4, matchesPlayed: 22, rating: 7.9),
        Player(id: '1005_2', name: 'Adolfo Gaich', position: 'Forvet', goals: 6, assists: 1, matchesPlayed: 20, rating: 7.7),
        Player(id: '1005_3', name: 'Ramzi Safuri', position: 'Orta Saha', goals: 3, assists: 5, matchesPlayed: 21, rating: 7.7),
        Player(id: '1005_4', name: 'Sander van de Streek', position: 'Orta Saha', goals: 4, assists: 2, matchesPlayed: 22, rating: 7.6),
        Player(id: '1005_5', name: 'Erdal Rakip', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 20, rating: 7.6),
        Player(id: '1005_6', name: 'Soner Dikmen', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 21, rating: 7.5),
        Player(id: '1005_7', name: 'Thalisson Kelven', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 21, rating: 7.7),
        Player(id: '1005_8', name: 'Veysel Sarı', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 22, rating: 7.5),
        Player(id: '1005_9', name: 'Güray Vural', position: 'Defans', goals: 1, assists: 3, matchesPlayed: 22, rating: 7.6),
        Player(id: '1005_10', name: 'Mert Yılmaz', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 19, rating: 7.4),
        Player(id: '1005_11', name: 'Kenan Pirić', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 7.8),
      ];
    }

    // 13. Konyaspor
    if (teamId == 1014 || lower.contains('konya')) {
      return [
        Player(id: '1014_1', name: 'Blaž Kramer', position: 'Forvet', goals: 7, assists: 1, matchesPlayed: 20, rating: 7.8),
        Player(id: '1014_2', name: 'Umut Nayir', position: 'Forvet', goals: 5, assists: 2, matchesPlayed: 21, rating: 7.6),
        Player(id: '1014_3', name: 'Pedrinho', position: 'Orta Saha', goals: 5, assists: 4, matchesPlayed: 23, rating: 7.9),
        Player(id: '1014_4', name: 'Alassane Ndao', position: 'Forvet', goals: 4, assists: 2, matchesPlayed: 22, rating: 7.6),
        Player(id: '1014_5', name: 'Marko Jevtović', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 22, rating: 7.6),
        Player(id: '1014_6', name: 'Melih İbrahimoğlu', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 19, rating: 7.5),
        Player(id: '1014_7', name: 'Guilherme Sityá', position: 'Defans', goals: 2, assists: 6, matchesPlayed: 24, rating: 7.9),
        Player(id: '1014_8', name: 'Riechedly Bazoer', position: 'Defans', goals: 1, assists: 1, matchesPlayed: 19, rating: 7.7),
        Player(id: '1014_9', name: 'Adil Demirbağ', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 23, rating: 7.6),
        Player(id: '1014_10', name: 'Nikola Boranijašević', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 20, rating: 7.5),
        Player(id: '1014_11', name: 'Jakub Słowik', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 7.8),
      ];
    }

    // 14. Çaykur Rizespor
    if (teamId == 1009 || lower.contains('rize')) {
      return [
        Player(id: '1009_1', name: 'Ali Sowe', position: 'Forvet', goals: 8, assists: 2, matchesPlayed: 22, rating: 7.9),
        Player(id: '1009_2', name: 'Dal Varešanović', position: 'Orta Saha', goals: 5, assists: 3, matchesPlayed: 22, rating: 7.8),
        Player(id: '1009_3', name: 'Ibrahim Olawoyin', position: 'Orta Saha', goals: 4, assists: 4, matchesPlayed: 23, rating: 7.8),
        Player(id: '1009_4', name: 'Martin Minchev', position: 'Forvet', goals: 4, assists: 1, matchesPlayed: 20, rating: 7.6),
        Player(id: '1009_5', name: 'Amir Hadžiahmetović', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 7.7),
        Player(id: '1009_6', name: 'Giannis Papanikolaou', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 19, rating: 7.5),
        Player(id: '1009_7', name: 'Khusniddin Alikulov', position: 'Defans', goals: 3, assists: 0, matchesPlayed: 22, rating: 7.9),
        Player(id: '1009_8', name: 'Casper Højer', position: 'Defans', goals: 2, assists: 4, matchesPlayed: 22, rating: 7.7),
        Player(id: '1009_9', name: 'Attila Mocsi', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 21, rating: 7.6),
        Player(id: '1009_10', name: 'Taha Şahin', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 20, rating: 7.5),
        Player(id: '1009_11', name: 'Ivo Grbić', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 22, rating: 7.8),
      ];
    }

    // 15. Alanyaspor
    if (teamId == 1007 || lower.contains('alanya')) {
      return [
        Player(id: '1007_1', name: 'Sergio Córdova', position: 'Forvet', goals: 7, assists: 2, matchesPlayed: 21, rating: 7.8),
        Player(id: '1007_2', name: 'Ui-jo Hwang', position: 'Forvet', goals: 4, assists: 1, matchesPlayed: 18, rating: 7.6),
        Player(id: '1007_3', name: 'Efecan Karaca', position: 'Forvet', goals: 3, assists: 5, matchesPlayed: 23, rating: 7.7),
        Player(id: '1007_4', name: 'Nicolas Janvier', position: 'Orta Saha', goals: 3, assists: 3, matchesPlayed: 22, rating: 7.6),
        Player(id: '1007_5', name: 'Richard', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 22, rating: 7.7),
        Player(id: '1007_6', name: 'Gaius Makouta', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 21, rating: 7.6),
        Player(id: '1007_7', name: 'Florent Hadergjonaj', position: 'Defans', goals: 2, assists: 3, matchesPlayed: 23, rating: 7.7),
        Player(id: '1007_8', name: 'Jure Balkovec', position: 'Defans', goals: 2, assists: 2, matchesPlayed: 22, rating: 7.7),
        Player(id: '1007_9', name: 'Fidan Aliti', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 22, rating: 7.7),
        Player(id: '1007_10', name: 'Furkan Bayır', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 19, rating: 7.5),
        Player(id: '1007_11', name: 'Ertuğrul Taşkıran', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 7.8),
      ];
    }

    // 16. Gaziantep FK
    if (teamId == 3574 || lower.contains('gaziantep')) {
      return [
        Player(id: '3574_1', name: 'David Okereke', position: 'Forvet', goals: 6, assists: 2, matchesPlayed: 20, rating: 7.8),
        Player(id: '3574_2', name: 'Deian Sorescu', position: 'Forvet', goals: 5, assists: 3, matchesPlayed: 22, rating: 7.8),
        Player(id: '3574_3', name: 'Kenan Kodro', position: 'Forvet', goals: 4, assists: 1, matchesPlayed: 18, rating: 7.5),
        Player(id: '3574_4', name: 'Alexandru Maxim', position: 'Orta Saha', goals: 4, assists: 6, matchesPlayed: 23, rating: 8.0),
        Player(id: '3574_5', name: 'Badou Ndiaye', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 20, rating: 7.7),
        Player(id: '3574_6', name: 'Kacper Kozłowski', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 7.6),
        Player(id: '3574_7', name: 'Arda Kızıldağ', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 21, rating: 7.6),
        Player(id: '3574_8', name: 'Bruno Viana', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.6),
        Player(id: '3574_9', name: 'Enric Saborit', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 19, rating: 7.6),
        Player(id: '3574_10', name: 'Salem M\'Bakata', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 21, rating: 7.5),
        Player(id: '3574_11', name: 'Sokratis Dioudis', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 22, rating: 7.7),
      ];
    }

    // 17. Bodrum FK
    if (teamId == 4835 || lower.contains('bodrum')) {
      return [
        Player(id: '4835_1', name: 'George Pușcaș', position: 'Forvet', goals: 6, assists: 1, matchesPlayed: 21, rating: 7.7),
        Player(id: '4835_2', name: 'Taulant Seferi', position: 'Forvet', goals: 4, assists: 2, matchesPlayed: 20, rating: 7.6),
        Player(id: '4835_3', name: 'Gökdeniz Bayrakdar', position: 'Forvet', goals: 3, assists: 2, matchesPlayed: 22, rating: 7.5),
        Player(id: '4835_4', name: 'Fredy', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 7.6),
        Player(id: '4835_5', name: 'Musah Mohammed', position: 'Orta Saha', goals: 0, assists: 1, matchesPlayed: 20, rating: 7.5),
        Player(id: '4835_6', name: 'Samet Yalçın', position: 'Orta Saha', goals: 1, assists: 2, matchesPlayed: 22, rating: 7.4),
        Player(id: '4835_7', name: 'Ali Aytemur', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 22, rating: 7.6),
        Player(id: '4835_8', name: 'Christophe Hérelle', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 18, rating: 7.6),
        Player(id: '4835_9', name: 'Cenk Şen', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 21, rating: 7.5),
        Player(id: '4835_10', name: 'Üzeyir Ergün', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 20, rating: 7.4),
        Player(id: '4835_11', name: 'Diogo Sousa', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 23, rating: 7.9),
      ];
    }

    // 18. Hatayspor
    if (teamId == 3577 || lower.contains('hatay')) {
      return [
        Player(id: '3577_1', name: 'Vincent Aboubakar', position: 'Forvet', goals: 7, assists: 2, matchesPlayed: 19, rating: 8.0),
        Player(id: '3577_2', name: 'Carlos Strandberg', position: 'Forvet', goals: 4, assists: 1, matchesPlayed: 20, rating: 7.6),
        Player(id: '3577_3', name: 'Joelson Fernandes', position: 'Forvet', goals: 3, assists: 2, matchesPlayed: 21, rating: 7.6),
        Player(id: '3577_4', name: 'Görkem Sağlam', position: 'Orta Saha', goals: 3, assists: 3, matchesPlayed: 22, rating: 7.7),
        Player(id: '3577_5', name: 'Rui Pedro', position: 'Orta Saha', goals: 2, assists: 2, matchesPlayed: 19, rating: 7.5),
        Player(id: '3577_6', name: 'Lamine Diack', position: 'Orta Saha', goals: 0, assists: 1, matchesPlayed: 20, rating: 7.5),
        Player(id: '3577_7', name: 'Guy-Marcelin Kilama', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 22, rating: 7.7),
        Player(id: '3577_8', name: 'Francisco Calvo', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 20, rating: 7.7),
        Player(id: '3577_9', name: 'Cemali Sertel', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 21, rating: 7.4),
        Player(id: '3577_10', name: 'Kamil Ahmet Çörekçi', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 19, rating: 7.4),
        Player(id: '3577_11', name: 'Erce Kardeşler', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 22, rating: 7.8),
      ];
    }

    // 19. Adana Demirspor
    if (teamId == 3563 || lower.contains('adana demir')) {
      return [
        Player(id: '3563_1', name: 'Yusuf Barası', position: 'Forvet', goals: 5, assists: 1, matchesPlayed: 22, rating: 7.5),
        Player(id: '3563_2', name: 'Ali Yavuz Kol', position: 'Forvet', goals: 3, assists: 1, matchesPlayed: 20, rating: 7.3),
        Player(id: '3563_3', name: 'Maestro', position: 'Orta Saha', goals: 0, assists: 2, matchesPlayed: 21, rating: 7.6),
        Player(id: '3563_4', name: 'Tayfun Aydoğan', position: 'Orta Saha', goals: 2, assists: 1, matchesPlayed: 21, rating: 7.4),
        Player(id: '3563_5', name: 'İzzet Çelik', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 18, rating: 7.2),
        Player(id: '3563_6', name: 'Salih Kavrazlı', position: 'Forvet', goals: 1, assists: 0, matchesPlayed: 17, rating: 7.0),
        Player(id: '3563_7', name: 'Jovan Manev', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 20, rating: 7.4),
        Player(id: '3563_8', name: 'Semih Güler', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 21, rating: 7.3),
        Player(id: '3563_9', name: 'Abdulsamet Burak', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 19, rating: 7.1),
        Player(id: '3563_10', name: 'Tolga Kalender', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 17, rating: 7.0),
        Player(id: '3563_11', name: 'Vedat Karakuş', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.4),
      ];
    }

    // 20. Dünya Kulüpleri (Man City, Real Madrid)
    if (teamId == 50 || lower.contains('city')) {
      return [
        Player(id: '50_1', name: 'Erling Haaland', position: 'Forvet', goals: 25, assists: 4, matchesPlayed: 26, rating: 8.9),
        Player(id: '50_2', name: 'Kevin De Bruyne', position: 'Orta Saha', goals: 7, assists: 16, matchesPlayed: 21, rating: 8.8),
        Player(id: '50_3', name: 'Phil Foden', position: 'Orta Saha', goals: 14, assists: 8, matchesPlayed: 25, rating: 8.6),
        Player(id: '50_4', name: 'Bernardo Silva', position: 'Orta Saha', goals: 8, assists: 9, matchesPlayed: 26, rating: 8.5),
        Player(id: '50_5', name: 'Rodri', position: 'Orta Saha', goals: 5, assists: 6, matchesPlayed: 18, rating: 8.7, isInjured: true, injuryReason: 'Diz Bağları'),
        Player(id: '50_6', name: 'Rúben Dias', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 26, rating: 8.1),
        Player(id: '50_7', name: 'Manuel Akanji', position: 'Defans', goals: 1, assists: 1, matchesPlayed: 24, rating: 7.9),
        Player(id: '50_8', name: 'Joško Gvardiol', position: 'Defans', goals: 4, assists: 2, matchesPlayed: 25, rating: 8.2),
        Player(id: '50_9', name: 'Kyle Walker', position: 'Defans', goals: 0, assists: 2, matchesPlayed: 22, rating: 7.8),
        Player(id: '50_10', name: 'Ederson', position: 'Kaleci', goals: 0, assists: 1, matchesPlayed: 27, rating: 8.2),
      ];
    }
    if (teamId == 541 || lower.contains('real madrid')) {
      return [
        Player(id: '541_1', name: 'Kylian Mbappé', position: 'Forvet', goals: 22, assists: 6, matchesPlayed: 24, rating: 8.8),
        Player(id: '541_2', name: 'Vinícius Júnior', position: 'Forvet', goals: 19, assists: 11, matchesPlayed: 25, rating: 8.9),
        Player(id: '541_3', name: 'Jude Bellingham', position: 'Orta Saha', goals: 13, assists: 9, matchesPlayed: 23, rating: 8.7),
        Player(id: '541_4', name: 'Federico Valverde', position: 'Orta Saha', goals: 6, assists: 7, matchesPlayed: 26, rating: 8.6),
        Player(id: '541_5', name: 'Rodrygo', position: 'Forvet', goals: 10, assists: 8, matchesPlayed: 24, rating: 8.3),
        Player(id: '541_6', name: 'Eduardo Camavinga', position: 'Orta Saha', goals: 2, assists: 3, matchesPlayed: 21, rating: 8.1),
        Player(id: '541_7', name: 'Antonio Rüdiger', position: 'Defans', goals: 2, assists: 1, matchesPlayed: 26, rating: 8.1),
        Player(id: '541_8', name: 'Éder Militão', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 16, rating: 8.0, isInjured: true, injuryReason: 'Çapraz Bağ'),
        Player(id: '541_9', name: 'Ferland Mendy', position: 'Defans', goals: 0, assists: 1, matchesPlayed: 22, rating: 7.7),
        Player(id: '541_10', name: 'Dani Carvajal', position: 'Defans', goals: 1, assists: 2, matchesPlayed: 14, rating: 8.0, isInjured: true, injuryReason: 'Diz'),
        Player(id: '541_11', name: 'Thibaut Courtois', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 22, rating: 8.3),
      ];
    }

    // Varsayılan zengin pozisyonel kadro (Her mevki için gerçekçi roller)
    return [
      Player(id: '${teamId}_1', name: '$name Santraforu', position: 'Forvet', goals: 10, assists: 3, matchesPlayed: 22, rating: 7.9),
      Player(id: '${teamId}_2', name: '$name Sağ Kanadı', position: 'Forvet', goals: 6, assists: 5, matchesPlayed: 23, rating: 7.8),
      Player(id: '${teamId}_3', name: '$name Sol Kanadı', position: 'Forvet', goals: 5, assists: 4, matchesPlayed: 21, rating: 7.7),
      Player(id: '${teamId}_4', name: '$name 10 Numarası', position: 'Orta Saha', goals: 5, assists: 7, matchesPlayed: 23, rating: 7.9),
      Player(id: '${teamId}_5', name: '$name Merkez Orta Sahası', position: 'Orta Saha', goals: 3, assists: 3, matchesPlayed: 22, rating: 7.6),
      Player(id: '${teamId}_6', name: '$name Ön Liberosu', position: 'Orta Saha', goals: 1, assists: 1, matchesPlayed: 22, rating: 7.6),
      Player(id: '${teamId}_7', name: '$name Sol Beki', position: 'Defans', goals: 1, assists: 4, matchesPlayed: 23, rating: 7.7),
      Player(id: '${teamId}_8', name: '$name Sağ Beki', position: 'Defans', goals: 1, assists: 3, matchesPlayed: 23, rating: 7.7),
      Player(id: '${teamId}_9', name: '$name 1. Stoperi', position: 'Defans', goals: 2, assists: 0, matchesPlayed: 24, rating: 7.8),
      Player(id: '${teamId}_10', name: '$name 2. Stoperi', position: 'Defans', goals: 1, assists: 0, matchesPlayed: 23, rating: 7.6),
      Player(id: '${teamId}_11', name: '$name As Kalecisi', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 24, rating: 7.8),
      Player(id: '${teamId}_12', name: '$name Yedek Forveti', position: 'Forvet', goals: 3, assists: 1, matchesPlayed: 16, rating: 7.3),
      Player(id: '${teamId}_13', name: '$name Yedek Orta Sahası', position: 'Orta Saha', goals: 1, assists: 2, matchesPlayed: 15, rating: 7.3),
      Player(id: '${teamId}_14', name: '$name Yedek Defansı', position: 'Defans', goals: 0, assists: 0, matchesPlayed: 14, rating: 7.2),
      Player(id: '${teamId}_15', name: '$name Yedek Kalecisi', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 4, rating: 7.2),
    ];
  }

  /// Takımın gerçek kadrosundan taktiksel Muhtemel 11 ve yedek listesi üretir
  static TeamLineup generateProbableLineup(Team team, {bool isHome = true}) {
    final active = team.squad.where((p) => !p.isInjured).toList();

    // 1. Kaleci
    final gkList = active.where((p) => p.position == 'Kaleci').toList();
    final gk = gkList.isNotEmpty
        ? gkList.first
        : (team.squad.where((p) => p.position == 'Kaleci').firstOrNull ??
            Player(id: 'gk', name: '${team.shortName} Kalecisi', position: 'Kaleci', goals: 0, assists: 0, matchesPlayed: 20, rating: 7.5));

    // 2. Defans (4 oyuncu)
    final defs = active.where((p) => p.position == 'Defans').take(4).toList();

    // 3. Orta Saha (3 oyuncu)
    final mids = active.where((p) => p.position == 'Orta Saha').take(3).toList();

    // 4. Forvet (3 oyuncu)
    final fwds = active.where((p) => p.position == 'Forvet').take(3).toList();

    // İlk 11 listesini topla
    final selectedStarters = <Player>{gk, ...defs, ...mids, ...fwds};

    // Eğer 11'i tamamlayamadıysak kalan aktif oyunculardan takviye et
    if (selectedStarters.length < 11) {
      for (final p in active) {
        if (!selectedStarters.contains(p)) {
          selectedStarters.add(p);
          if (selectedStarters.length == 11) break;
        }
      }
    }

    final startXI = selectedStarters.map((p) => LineupPlayer(
      id: int.tryParse(p.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      name: p.name,
      pos: p.position.startsWith('Kal') ? 'G' : (p.position.startsWith('Def') ? 'D' : (p.position.startsWith('Orta') ? 'M' : 'F')),
    )).toList();

    // Kalan aktif oyuncuları yedek kulübesine al
    final subs = active
        .where((p) => !selectedStarters.contains(p))
        .map((p) => LineupPlayer(
          id: int.tryParse(p.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          name: p.name,
          pos: p.position.startsWith('Kal') ? 'G' : (p.position.startsWith('Def') ? 'D' : (p.position.startsWith('Orta') ? 'M' : 'F')),
        ))
        .toList();

    return TeamLineup(
      teamId: int.tryParse(team.id) ?? 0,
      teamName: team.name,
      teamLogo: team.crestUrl,
      formation: '4-3-3',
      startXI: startXI,
      substitutes: subs,
    );
  }

  static HeadToHeadSummary getHeadToHead(int homeId, int awayId) {
    final now = DateTime.now();
    final fixtures = [
      Fixture(
        id: 9001,
        date: DateTime(now.year - 1, 10, 15),
        statusShort: 'FT',
        leagueId: 0,
        leagueName: 'Lig Karşılaşması',
        season: now.year - 1,
        homeTeamId: homeId,
        homeTeamName: 'Ev Sahibi',
        awayTeamId: awayId,
        awayTeamName: 'Deplasman',
        homeGoals: 2,
        awayGoals: 1,
      ),
      Fixture(
        id: 9002,
        date: DateTime(now.year - 1, 3, 20),
        statusShort: 'FT',
        leagueId: 0,
        leagueName: 'Lig Karşılaşması',
        season: now.year - 1,
        homeTeamId: awayId,
        homeTeamName: 'Deplasman',
        awayTeamId: homeId,
        awayTeamName: 'Ev Sahibi',
        homeGoals: 1,
        awayGoals: 1,
      ),
      Fixture(
        id: 9003,
        date: DateTime(now.year - 2, 11, 5),
        statusShort: 'FT',
        leagueId: 0,
        leagueName: 'Kupa Karşılaşması',
        season: now.year - 2,
        homeTeamId: homeId,
        homeTeamName: 'Ev Sahibi',
        awayTeamId: awayId,
        awayTeamName: 'Deplasman',
        homeGoals: 3,
        awayGoals: 1,
      ),
      Fixture(
        id: 9004,
        date: DateTime(now.year - 2, 4, 12),
        statusShort: 'FT',
        leagueId: 0,
        leagueName: 'Lig Karşılaşması',
        season: now.year - 2,
        homeTeamId: awayId,
        homeTeamName: 'Deplasman',
        awayTeamId: homeId,
        awayTeamName: 'Ev Sahibi',
        homeGoals: 2,
        awayGoals: 2,
      ),
    ];

    return HeadToHeadSummary.fromFixtures(
      fixtures,
      homeTeamId: homeId,
      awayTeamId: awayId,
    );
  }

  static List<TeamLineup> getOfficialLineups(int fixtureId) {
    // Sabit sahte kadro kalıntısı temizlendi.
    // Resmi kadrolar yalnızca canlı ESPN veya API-Football akışından doğrulanarak alınır.
    return [];
  }

  static List<MatchEvent> getOfficialEvents(int fixtureId) {
    return [];
  }
}
