import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/team_name_matcher.dart';
import 'health_check_service.dart';

/// Club Elo Küresel Takım Güç Endeksi Servisi
///
/// Dünya ve Türkiye kulüplerinin gerçek güç derecelerini (Elo) sağlar.
/// Bu sayede model, şampiyonluk adayı ile lig sonuncusu arasındaki
/// kalite farkını matematiksel kesinlikle hesaba katar.
class ClubEloService {
  static const String _prefKeyEloCache = 'fottbol_club_elo_cache';
  static final Map<String, double> _eloDatabase = Map.from(_bundledEloRatings);
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Servisi başlatır ve hafızadan/ağdan Elo verilerini yükler
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefKeyEloCache);
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        map.forEach((k, v) {
          if (v is num) _eloDatabase[k.toLowerCase()] = v.toDouble();
        });
      } catch (e) {
        debugPrint('Elo cache okuma hatası: $e');
      }
    }
    _isInitialized = true;

    // Arka planda api.clubelo.com üzerinden güncelleme dene
    _fetchLiveEloSilently(prefs);
  }

  /// Canlı puan durumundan hesaplanan dinamik Elo güncellemesi
  static void updateTeamElo(String teamName, double elo) {
    final clean = teamName.toLowerCase().trim();
    if (clean.isNotEmpty) {
      _eloDatabase[clean] = elo.clamp(1250.0, 2100.0);
    }
  }

  /// Bir takımın Elo puanını döner (Bulunamazsa takım kimliğine göre 1380-1610 arası ayrıştırılmış Elo üretir)
  static double getTeamElo(String teamName) {
    final clean = teamName.toLowerCase().trim();
    if (_eloDatabase.containsKey(clean)) {
      return _eloDatabase[clean]!;
    }
    for (final entry in _eloDatabase.entries) {
      if (TeamNameMatcher.matches(entry.key, clean)) {
        return entry.value;
      }
    }
    // Eşleşme yoksa her takıma aynı 1480 puanı vermek yerine deterministik güç kademesi üret
    int hash = 0;
    for (int i = 0; i < clean.length; i++) {
      hash = (hash * 31 + clean.codeUnitAt(i)) & 0x7fffffff;
    }
    return 1385.0 + (hash % 225).toDouble();
  }

  /// İki takım arasındaki Elo farkını döner (Ev Sahibi - Deplasman)
  static double calculateEloDifference(String homeTeam, String awayTeam) {
    final hElo = getTeamElo(homeTeam);
    final aElo = getTeamElo(awayTeam);
    return hElo - aElo;
  }

  /// Elo farkına dayalı beklenen galibiyet olasılığı (Standart Lojistik Formül + Ev Sahibi Avantajı)
  /// P(Home) = 1 / (1 + 10^(-(DeltaElo + 70) / 400))
  static double calculateExpectedWinProbability(double eloDiff, {bool isNeutral = false}) {
    final double homeFieldAdvantage = isNeutral ? 0.0 : 65.0; // ~65 Elo ev sahibi avantajı
    final double exponent = -(eloDiff + homeFieldAdvantage) / 400.0;
    return 1.0 / (1.0 + math.pow(10, exponent));
  }

  /// Elo farkından beklenen gol çarpanı türetir
  /// Güçlü takımın beklenen golü artar, zayıf takımınki baskılanır.
  static ({double homeMultiplier, double awayMultiplier}) calculateGoalMultipliers(double eloDiff) {
    // [-400, +400] puan aralığı lojistik skalaya bağlanır
    final double normalized = eloDiff.clamp(-450.0, 450.0);
    // 100 Elo farkı yaklaşık %18 hücum avantajına karşılık gelir
    final double homeAdj = 1.0 + (normalized / 600.0);
    final double awayAdj = 1.0 - (normalized / 600.0);

    return (
      homeMultiplier: homeAdj.clamp(0.60, 1.65),
      awayMultiplier: awayAdj.clamp(0.60, 1.65),
    );
  }

  static Future<void> _fetchLiveEloSilently(SharedPreferences prefs) async {
    try {
      final base = HealthCheckService.getActiveUrl('club_elo');
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final uri = Uri.parse('$base/$dateStr');

      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final lines = const LineSplitter().convert(res.body);
        final map = <String, double>{};

        for (final line in lines.skip(1)) {
          final parts = line.split(',');
          if (parts.length >= 5) {
            final club = parts[1].trim().toLowerCase();
            final elo = double.tryParse(parts[4].trim());
            if (elo != null) map[club] = elo;
          }
        }

        if (map.isNotEmpty) {
          _eloDatabase.addAll(map);
          await prefs.setString(_prefKeyEloCache, jsonEncode(_eloDatabase));
          debugPrint('Club Elo verisi ${map.length} kulüp için güncellendi.');
        }
      }
    } catch (e) {
      debugPrint('Club Elo canlı çekim atlandı: $e');
    }
  }

  /// Kapsamlı Dünya, Avrupa, Süper Lig ve Alt Ligler Kulüp Elo Veritabanı
  static final Map<String, double> _bundledEloRatings = {
    // Türkiye Süper Lig
    'galatasaray': 1735.0,
    'fenerbahçe': 1720.0,
    'fenerbahce': 1720.0,
    'beşiktaş': 1660.0,
    'besiktas': 1660.0,
    'trabzonspor': 1605.0,
    'başakşehir': 1565.0,
    'basaksehir': 1565.0,
    'samsunspor': 1545.0,
    'eyüpspor': 1530.0,
    'eyupspor': 1530.0,
    'göztepe': 1525.0,
    'goztepe': 1525.0,
    'kasımpaşa': 1510.0,
    'kasimpasa': 1510.0,
    'sivasspor': 1495.0,
    'çaykur rizespor': 1492.0,
    'rizespor': 1492.0,
    'alanyaspor': 1488.0,
    'antalyaspor': 1482.0,
    'konyaspor': 1475.0,
    'gaziantep fk': 1470.0,
    'gaziantep': 1470.0,
    'kayserispor': 1460.0,
    'hatayspor': 1442.0,
    'bodrum fk': 1435.0,
    'adana demirspor': 1385.0,

    // TFF 1. Lig
    'kocaelispor': 1455.0,
    'fatih karagümrük': 1450.0,
    'karagümrük': 1450.0,
    'ankaragücü': 1445.0,
    'gençlerbirliği': 1430.0,
    'genclerbirligi': 1430.0,
    'bandırmaspor': 1435.0,
    'çorum fk': 1428.0,
    'corum fk': 1428.0,
    'erzurumspor fk': 1422.0,
    'istanbulspor': 1418.0,
    'amed sk': 1425.0,
    'pendikspor': 1415.0,
    'boluspor': 1410.0,
    'sakaryaspor': 1405.0,
    'keçiörengücü': 1408.0,
    'ümraniyespor': 1402.0,
    'manisa fk': 1395.0,
    'şanlıurfaspor': 1385.0,
    'adanaspor': 1370.0,
    'yeni malatyaspor': 1310.0,

    // İngiltere Premier League & Championship
    'manchester city': 2040.0,
    'liverpool': 2005.0,
    'arsenal': 1990.0,
    'chelsea': 1895.0,
    'aston villa': 1875.0,
    'newcastle': 1860.0,
    'newcastle united': 1860.0,
    'tottenham': 1850.0,
    'tottenham hotspur': 1850.0,
    'brighton': 1835.0,
    'manchester united': 1825.0,
    'bournemouth': 1815.0,
    'fulham': 1810.0,
    'nottingham forest': 1805.0,
    'brentford': 1795.0,
    'west ham': 1785.0,
    'crystal palace': 1780.0,
    'everton': 1755.0,
    'wolves': 1745.0,
    'wolverhampton': 1745.0,
    'leicester city': 1710.0,
    'ipswich town': 1685.0,
    'southampton': 1665.0,
    'leeds united': 1740.0,
    'burnley': 1725.0,
    'sheffield united': 1715.0,
    'sunderland': 1690.0,
    'middlesbrough': 1680.0,
    'west bromwich': 1675.0,
    'norwich city': 1660.0,
    'coventry city': 1655.0,
    'watford': 1645.0,

    // İspanya La Liga
    'real madrid': 2045.0,
    'fc barcelona': 1985.0,
    'barcelona': 1985.0,
    'atletico madrid': 1915.0,
    'athletic club': 1865.0,
    'athletic bilbao': 1865.0,
    'villarreal': 1840.0,
    'real sociedad': 1830.0,
    'real betis': 1810.0,
    'girona': 1800.0,
    'osasuna': 1765.0,
    'celta vigo': 1755.0,
    'mallorca': 1750.0,
    'rayo vallecano': 1740.0,
    'sevilla': 1735.0,
    'getafe': 1725.0,
    'deportivo alaves': 1715.0,
    'alaves': 1715.0,
    'valencia': 1705.0,
    'leganes': 1685.0,
    'las palmas': 1675.0,
    'espanyol': 1670.0,
    'real valladolid': 1645.0,

    // İtalya Serie A
    'inter': 1975.0,
    'internazionale': 1975.0,
    'atalanta': 1910.0,
    'napoli': 1890.0,
    'juventus': 1880.0,
    'ac milan': 1865.0,
    'milan': 1865.0,
    'lazio': 1845.0,
    'fiorentina': 1835.0,
    'bologna': 1820.0,
    'roma': 1815.0,
    'as roma': 1815.0,
    'torino': 1765.0,
    'udinese': 1745.0,
    'genoa': 1730.0,
    'empoli': 1715.0,
    'cagliari': 1705.0,
    'parma': 1700.0,
    'como': 1695.0,
    'hellas verona': 1690.0,
    'lecce': 1680.0,
    'monza': 1670.0,
    'venezia': 1650.0,

    // Almanya Bundesliga
    'bayern münchen': 1995.0,
    'bayern munich': 1995.0,
    'bayer leverkusen': 1955.0,
    'borussia dortmund': 1890.0,
    'rb leipzig': 1875.0,
    'eintracht frankfurt': 1845.0,
    'vfb stuttgart': 1840.0,
    'stuttgart': 1840.0,
    'sc freiburg': 1795.0,
    'freiburg': 1795.0,
    'werder bremen': 1770.0,
    'mainz 05': 1765.0,
    'wolfsburg': 1760.0,
    'borussia mönchengladbach': 1750.0,
    'union berlin': 1735.0,
    'augsburg': 1725.0,
    'hoffenheim': 1715.0,
    'heidenheim': 1700.0,
    'st. pauli': 1680.0,
    'vfl bochum': 1650.0,
    'holstein kiel': 1640.0,

    // Fransa Ligue 1
    'paris saint-germain': 1935.0,
    'psg': 1935.0,
    'monaco': 1840.0,
    'as monaco': 1840.0,
    'lille': 1835.0,
    'marseille': 1825.0,
    'lyon': 1805.0,
    'nice': 1790.0,
    'lens': 1785.0,
    'brest': 1775.0,
    'rennes': 1760.0,
    'reims': 1735.0,
    'toulouse': 1730.0,
    'strasbourg': 1720.0,
    'auxerre': 1695.0,
    'nantes': 1685.0,
    'angers': 1665.0,
    'saint-etienne': 1660.0,
    'le havre': 1650.0,
    'montpellier': 1640.0,

    // Portekiz, Hollanda, İskoçya, Brezilya ve Diğerleri
    'sporting cp': 1865.0,
    'benfica': 1850.0,
    'porto': 1825.0,
    'braga': 1745.0,
    'vitoria guimaraes': 1715.0,
    'psv': 1825.0,
    'feyenoord': 1785.0,
    'ajax': 1770.0,
    'twente': 1720.0,
    'az alkmaar': 1725.0,
    'club brugge': 1765.0,
    'anderlecht': 1710.0,
    'union sg': 1745.0,
    'celtic': 1775.0,
    'rangers': 1725.0,
    'flamengo': 1790.0,
    'palmeiras': 1795.0,
    'botafogo': 1785.0,
    'river plate': 1755.0,
    'boca juniors': 1720.0,
    'al-hilal': 1780.0,
    'al-nassr': 1740.0,
    'al-ittihad': 1735.0,
  };
}

