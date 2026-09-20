/// Poisson modelinin referans aldığı genel lig ortalamaları.
///
/// Hem [PoissonEngine] hem de gerçek veri çekilemediğinde devreye giren
/// [MatchStat] varsayılanları aynı sabitleri kullanır; böylece veri yokken
/// üretilen tahmin "uydurma" bir skor değil, saf lig ortalaması olur.
class LeagueConstants {
  /// Ev sahibi takımların maç başı ortalama gol sayısı
  static const double avgHomeGoals = 1.55;

  /// Deplasman takımlarının maç başı ortalama gol sayısı
  static const double avgAwayGoals = 1.20;

  /// Saha farkı gözetmeksizin maç başı ortalama gol
  static const double avgGoals = (avgHomeGoals + avgAwayGoals) / 2;

  /// Dixon-Coles düşük skor bağımlılık katsayısı (ρ).
  ///
  /// Bağımsız Poisson varsayımı 0-0 ve 1-1'i olduğundan az, 1-0 ve 0-1'i
  /// olduğundan fazla tahmin eder. Negatif ρ bu dört skoru düzeltir.
  /// Avrupa liglerinde tahmin edilen değerler genellikle -0.05 ile -0.20
  /// arasındadır (Dixon & Coles, 1997); orta bir değer kullanılır.
  static const double dixonColesRho = -0.13;

  /// Aralarındaki maçların (head-to-head) beklenen gole en fazla etkisi.
  /// Örneklem küçük ve eski maçlar içerebildiği için düşük tutulur.
  static const double maxHeadToHeadWeight = 0.15;

  /// Tam ağırlığa ulaşmak için gereken asgari karşılaşma sayısı
  static const int headToHeadFullWeightMatches = 10;

  /// Ülkelere göre desteklenen tüm lig ve kupa organizasyonları
  static const Map<String, List<String>> countryLeaguesMap = {
    'Turkey': [
      'Trendyol Süper Lig',
      'Trendyol 1. Lig',
      'TFF 2. Lig - Kırmızı Grup',
      'TFF 2. Lig - Beyaz Grup',
      'TFF 3. Lig - 1. Grup',
      'TFF 3. Lig - 2. Grup',
      'TFF 3. Lig - 3. Grup',
      'TFF 3. Lig - 4. Grup',
      'Ziraat Türkiye Kupası',
      'Turkcell Süper Kupa',
      'Bölgesel Amatör Lig (BAL)',
    ],
    'England': [
      'Premier League',
      'Championship',
      'League One',
      'League Two',
      'National League',
      'FA Cup',
      'EFL Cup (Carabao)',
    ],
    'Spain': [
      'La Liga',
      'La Liga 2 (Segunda)',
      'Primera Federación',
      'Copa del Rey',
      'Supercopa de España',
    ],
    'Italy': [
      'Serie A',
      'Serie B',
      'Serie C (Girone A)',
      'Serie C (Girone B)',
      'Serie C (Girone C)',
      'Coppa Italia',
      'Supercoppa Italiana',
    ],
    'Germany': [
      'Bundesliga',
      '2. Bundesliga',
      '3. Liga',
      'DFB-Pokal',
      'DFL-Supercup',
    ],
    'France': [
      'Ligue 1',
      'Ligue 2',
      'National 1',
      'Coupe de France',
      'Trophée des Champions',
    ],
    'Netherlands': [
      'Eredivisie',
      'Eerste Divisie',
      'KNVB Beker',
    ],
    'Portugal': [
      'Liga Portugal',
      'Liga Portugal 2',
      'Taça de Portugal',
      'Taça da Liga',
    ],
    'Brazil': [
      'Brasileirão Serie A',
      'Brasileirão Serie B',
      'Brasileirão Serie C',
      'Copa do Brasil',
    ],
    'World': [
      'UEFA Şampiyonlar Ligi',
      'UEFA Avrupa Ligi',
      'UEFA Konferans Ligi',
      'UEFA Süper Kupa',
      'UEFA Uluslar Ligi',
    ],
  };

  /// Lig isimlerini standart formata dönüştürür (çift çip oluşmasını önler)
  static String normalizeLeagueName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('süper lig') || lower.contains('super lig')) return 'Trendyol Süper Lig';
    if (lower.contains('1. lig') || lower.contains('tff 1')) return 'Trendyol 1. Lig';
    if (lower.contains('2. lig') && lower.contains('kırmızı')) return 'TFF 2. Lig - Kırmızı Grup';
    if (lower.contains('2. lig') && lower.contains('beyaz')) return 'TFF 2. Lig - Beyaz Grup';
    if (lower.contains('2. lig')) return 'TFF 2. Lig';
    if (lower.contains('3. lig') && (lower.contains('1.') || lower.contains('1. grup') || lower.contains('grup 1'))) return 'TFF 3. Lig - 1. Grup';
    if (lower.contains('3. lig') && (lower.contains('2.') || lower.contains('2. grup') || lower.contains('grup 2'))) return 'TFF 3. Lig - 2. Grup';
    if (lower.contains('3. lig') && (lower.contains('3.') || lower.contains('3. grup') || lower.contains('grup 3'))) return 'TFF 3. Lig - 3. Grup';
    if (lower.contains('3. lig') && (lower.contains('4.') || lower.contains('4. grup') || lower.contains('grup 4'))) return 'TFF 3. Lig - 4. Grup';
    if (lower.contains('3. lig')) return 'TFF 3. Lig';
    if (lower.contains('türkiye kupası') || lower.contains('turkish cup') || lower.contains('ziraat')) return 'Ziraat Türkiye Kupası';
    if (lower.contains('süper kupa') || lower.contains('super cup')) return 'Turkcell Süper Kupa';
    if (lower.contains('amatör') || lower.contains('bal')) return 'Bölgesel Amatör Lig (BAL)';
    if (lower.contains('premier league')) return 'Premier League';
    if (lower.contains('championship')) return 'Championship';
    if (lower.contains('league one')) return 'League One';
    if (lower.contains('league two')) return 'League Two';
    if (lower.contains('national league')) return 'National League';
    if (lower.contains('la liga 2') || lower.contains('segunda')) return 'La Liga 2 (Segunda)';
    if (lower.contains('la liga') || lower.contains('laliga')) return 'La Liga';
    if (lower.contains('2. bundesliga')) return '2. Bundesliga';
    if (lower.contains('3. liga')) return '3. Liga';
    if (lower.contains('bundesliga')) return 'Bundesliga';
    if (lower.contains('serie a')) return 'Serie A';
    if (lower.contains('serie b')) return 'Serie B';
    if (lower.contains('serie c')) return 'Serie C';
    if (lower.contains('ligue 1')) return 'Ligue 1';
    if (lower.contains('ligue 2')) return 'Ligue 2';
    if (lower.contains('eredivisie')) return 'Eredivisie';
    if (lower.contains('eerste')) return 'Eerste Divisie';
    if (lower.contains('liga portugal') || lower.contains('primeira')) return 'Liga Portugal';
    if (lower.contains('brasileir')) return 'Brasileirão Serie A';
    if (lower.contains('champions') || lower.contains('şampiyonlar')) return 'UEFA Şampiyonlar Ligi';
    if (lower.contains('europa league') || lower.contains('avrupa ligi')) return 'UEFA Avrupa Ligi';
    if (lower.contains('conference') || lower.contains('konferans')) return 'UEFA Konferans Ligi';
    return name;
  }

  /// İki lig isminin birbiriyle eşleşip eşleşmediğini kontrol eder
  static bool matchesLeague(String fixtureLeague, String selectedLeague) {
    if (selectedLeague == 'Tümü') return true;
    final normFix = normalizeLeagueName(fixtureLeague).toLowerCase();
    final normSel = normalizeLeagueName(selectedLeague).toLowerCase();
    if (normFix == normSel) return true;
    if (normFix.contains(normSel) || normSel.contains(normFix)) return true;

    final fl = fixtureLeague.toLowerCase();
    final sl = selectedLeague.toLowerCase();
    if (fl == sl) return true;
    if ((sl.contains('süper lig') || sl.contains('super lig')) && (fl.contains('super lig') || fl.contains('süper lig'))) return true;
    if (sl.contains('1. lig') && (fl.contains('1. lig') || fl.contains('1.lig'))) return true;
    if (sl.contains('2. lig') && (fl.contains('2. lig') || fl.contains('2.lig'))) return true;
    if (sl.contains('3. lig') && (fl.contains('3. lig') || fl.contains('3.lig'))) return true;
    if (sl.contains('türkiye kupası') && (fl.contains('cup') || fl.contains('kupa'))) return true;
    if (sl.contains('premier league') && fl.contains('premier league')) return true;
    if (sl.contains('championship') && fl.contains('championship')) return true;
    if (sl.contains('league one') && fl.contains('league one')) return true;
    if (sl.contains('league two') && fl.contains('league two')) return true;
    if (sl.contains('fa cup') && fl.contains('fa cup')) return true;
    if (sl.contains('efl') && (fl.contains('carabao') || fl.contains('league cup') || fl.contains('efl'))) return true;
    if (sl.contains('la liga 2') || sl.contains('segunda')) {
      return fl.contains('segunda') || fl.contains('la liga 2') || fl.contains('laliga 2');
    }
    if (sl.contains('la liga') && (fl.contains('laliga') || fl.contains('la liga'))) return true;
    if (sl.contains('copa del rey') && fl.contains('copa del rey')) return true;
    if (sl.contains('serie a') && fl.contains('serie a')) return true;
    if (sl.contains('serie b') && fl.contains('serie b')) return true;
    if (sl.contains('coppa italia') && fl.contains('coppa italia')) return true;
    if (sl.contains('2. bundesliga') && fl.contains('2. bundesliga')) return true;
    if (sl.contains('bundesliga') && fl.contains('bundesliga')) return true;
    if (sl.contains('dfb') && fl.contains('pokal')) return true;
    if (sl.contains('ligue 1') && fl.contains('ligue 1')) return true;
    if (sl.contains('ligue 2') && fl.contains('ligue 2')) return true;
    if (sl.contains('coupe de france') && fl.contains('coupe de france')) return true;
    if (sl.contains('eredivisie') && fl.contains('eredivisie')) return true;
    if (sl.contains('eerste divisie') && fl.contains('eerste divisie')) return true;
    if (sl.contains('liga portugal') && (fl.contains('liga portugal') || fl.contains('primeira'))) return true;
    if (sl.contains('taça') && fl.contains('taça')) return true;
    if (sl.contains('brasileirão') || sl.contains('serie a')) {
      if (sl.contains('serie a') && fl.contains('serie a')) return true;
      if (sl.contains('serie b') && fl.contains('serie b')) return true;
    }
    if (sl.contains('şampiyonlar') && (fl.contains('champions') || fl.contains('şampiyon'))) return true;
    if (sl.contains('avrupa ligi') && (fl.contains('europa') && !fl.contains('conf'))) return true;
    if (sl.contains('konferans') && fl.contains('conf')) return true;
    if (sl.contains('uluslar') && fl.contains('nations')) return true;
    return fl.contains(sl) || sl.contains(fl);
  }

  /// Ülke adlarını Türkçe/İngilizce eşleştirir
  static bool countryMatches(String fixtureCountry, String selectedCountry) {
    if (selectedCountry == 'Tümü') return true;
    final fc = fixtureCountry.toLowerCase().trim();
    final sc = selectedCountry.toLowerCase().trim();
    if (fc == sc) return true;
    if ((sc == 'turkey' || sc == 'türkiye') && (fc == 'turkey' || fc == 'türkiye')) return true;
    if ((sc == 'england' || sc == 'ingiltere') && (fc == 'england' || fc == 'ingiltere')) return true;
    if ((sc == 'spain' || sc == 'ispanya') && (fc == 'spain' || fc == 'ispanya')) return true;
    if ((sc == 'germany' || sc == 'almanya') && (fc == 'germany' || fc == 'almanya')) return true;
    if ((sc == 'italy' || sc == 'italya') && (fc == 'italy' || fc == 'italya')) return true;
    if ((sc == 'france' || sc == 'fransa') && (fc == 'france' || fc == 'fransa')) return true;
    if ((sc == 'netherlands' || sc == 'hollanda') && (fc == 'netherlands' || fc == 'hollanda')) return true;
    if ((sc == 'portugal' || sc == 'portekiz') && (fc == 'portugal' || fc == 'portekiz')) return true;
    if ((sc == 'brazil' || sc == 'brezilya') && (fc == 'brazil' || fc == 'brezilya')) return true;
    if ((sc == 'world' || sc == 'dünya' || sc == 'uluslararası') && (fc == 'world' || fc == 'uefa' || fc == 'dünya')) return true;
    return fc.contains(sc) || sc.contains(fc);
  }
}
