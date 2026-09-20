/// Takım isimlerini farklı veri kaynakları (ESPN, API-Football, yerel veri) arasında
/// güvenle eşleştirmek için yardımcı sınıf.
class TeamNameMatcher {
  /// Türkçe ve yabancı karakterleri temizleyip normalize eder
  static String normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Ortak kelimeleri ve kulüp unvanlarını temizler
  static final Set<String> _ignoredTokens = {
    'fk',
    'sk',
    'spor',
    'sporu',
    'kulubu',
    'kulubü',
    'as',
    'jk',
    'fc',
    'cf',
    'sc',
    'ac',
    'afc',
    'sportif',
    'faaliyetleri',
    'holding',
    'belediyesi',
    'belediye',
    'buyuksehir',
    'büyükşehir',
  };

  /// Ayırt edici zıt anahtar kelimeler (biri varsa diğeriyle asla eşleşemez)
  static final List<Set<String>> _conflictingTokens = [
    {'demir', 'demirspor'}, // Adana Demir vs Adanaspor
    {'city', 'united'}, // Man City vs Man United
    {'madrid', 'sociedad', 'betis'}, // Real Madrid vs Real Sociedad
    {'inter', 'milan'}, // Inter vs Milan
    {'kayseri', 'erciyes'}, // Kayserispor vs Erciyes
  ];

  static List<String> _extractCoreTokens(String name) {
    final norm = normalize(name);
    if (norm.isEmpty) return [];
    return norm
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_ignoredTokens.contains(t))
        .toList();
  }

  /// İki takım isminin aynı takıma ait olup olmadığını sıkı kurallarla doğrular
  static bool matches(String a, String b) {
    final normA = normalize(a);
    final normB = normalize(b);
    if (normA.isEmpty || normB.isEmpty) return false;

    // Tam birebir eşleşme
    if (normA == normB) return true;

    final tokensA = _extractCoreTokens(a);
    final tokensB = _extractCoreTokens(b);

    if (tokensA.isEmpty || tokensB.isEmpty) return false;

    // Zıtlık kontrolü: Farklı iki kulüp birbirinin alt kümesi olamaz
    for (final conflictGroup in _conflictingTokens) {
      final hasA = tokensA.any((t) => conflictGroup.contains(t));
      final hasB = tokensB.any((t) => conflictGroup.contains(t));
      if (hasA != hasB) {
        // Biri Adana Demir, diğeri salt Adana ise çakışma engellenir
        if (tokensA.contains('adana') && tokensB.contains('adana')) {
          return false;
        }
      }
    }

    // Adana Demirspor vs Adanaspor kontrolü
    final isDemirA = normA.contains('demir');
    final isDemirB = normB.contains('demir');
    if (isDemirA != isDemirB && (normA.contains('adana') || normB.contains('adana'))) {
      return false;
    }

    // Kayseri Erciyes vs Kayserispor kontrolü
    final isErciyesA = normA.contains('erciyes');
    final isErciyesB = normB.contains('erciyes');
    if (isErciyesA != isErciyesB) {
      return false;
    }

    // Real Madrid vs Real Sociedad kontrolü
    if (tokensA.contains('real') && tokensB.contains('real')) {
      final isMadridA = tokensA.contains('madrid');
      final isMadridB = tokensB.contains('madrid');
      if (isMadridA != isMadridB) return false;
      final isSociedadA = tokensA.contains('sociedad');
      final isSociedadB = tokensB.contains('sociedad');
      if (isSociedadA != isSociedadB) return false;
    }

    // Manchester City vs Manchester United kontrolü
    if (tokensA.contains('manchester') && tokensB.contains('manchester')) {
      final isCityA = tokensA.contains('city');
      final isCityB = tokensB.contains('city');
      if (isCityA != isCityB) return false;
      final isUnitedA = tokensA.contains('united');
      final isUnitedB = tokensB.contains('united');
      if (isUnitedA != isUnitedB) return false;
    }

    // Temizlenmiş ana token kontrolü
    final joinedA = tokensA.join('');
    final joinedB = tokensB.join('');
    if (joinedA == joinedB) return true;

    // Özel takma adlar (ESPN -> Yerel)
    if (_matchesSpecialAliases(joinedA, joinedB)) return true;

    // En az 4 karakterli kök kontrolü
    if (joinedA.length >= 4 && joinedB.length >= 4) {
      // Birbirini kapsama (örn: "istanbulbasaksehir" ve "basaksehir")
      if (joinedA.contains(joinedB) || joinedB.contains(joinedA)) {
        return true;
      }
    }

    // Token kesişimi: Ana kelimelerin çoğu uyuşuyor mu?
    int commonTokens = 0;
    for (final tA in tokensA) {
      if (tA.length < 3) continue;
      for (final tB in tokensB) {
        if (tB.length < 3) continue;
        if (tA == tB || tA.startsWith(tB) || tB.startsWith(tA)) {
          commonTokens++;
          break;
        }
      }
    }

    if (commonTokens > 0 && commonTokens >= (tokensA.length > tokensB.length ? tokensB.length : tokensA.length)) {
      return true;
    }

    return false;
  }

  static bool _matchesSpecialAliases(String a, String b) {
    bool pair(String x, String y) => (a.contains(x) && b.contains(y)) || (a.contains(y) && b.contains(x));

    if (pair('fenerbahce', 'fenerbahce')) return true;
    if (pair('galatasaray', 'galatasaray')) return true;
    if (pair('besiktas', 'besiktas')) return true;
    if (pair('trabzon', 'trabzon')) return true;
    if (pair('kayseri', 'kayseri')) return true;
    if (pair('samsun', 'samsun')) return true;
    if (pair('eyup', 'eyup')) return true;
    if (pair('goztepe', 'goztepe')) return true;
    if (pair('basaksehir', 'basaksehir')) return true;
    if (pair('kasimpasa', 'kasimpasa')) return true;
    if (pair('sivas', 'sivas')) return true;
    if (pair('antalya', 'antalya')) return true;
    if (pair('konya', 'konya')) return true;
    if (pair('rize', 'rize')) return true;
    if (pair('alanya', 'alanya')) return true;
    if (pair('gaziantep', 'gaziantep')) return true;
    if (pair('bodrum', 'bodrum')) return true;
    if (pair('hatay', 'hatay')) return true;
    if (pair('kocaeli', 'kocaeli')) return true;
    if (pair('amed', 'amed')) return true;

    return false;
  }
}
