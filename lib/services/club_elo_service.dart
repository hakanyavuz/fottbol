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

  /// Bir takımın Elo puanını döner (Bulunamazsa lig ortalaması ~1480 varsayılır)
  static double getTeamElo(String teamName) {
    final clean = teamName.toLowerCase().trim();
    for (final entry in _eloDatabase.entries) {
      if (TeamNameMatcher.matches(entry.key, clean)) {
        return entry.value;
      }
    }
    // Eşleşme yoksa genel lig medyanı döner
    return 1480.0;
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

  /// Çevrimdışı ve temel Süper Lig & Avrupa Kulüp Elo Veritabanı
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
    'kasımpaşa': 1515.0,
    'kasimpasa': 1515.0,
    'sivasspor': 1500.0,
    'alanyaspor': 1490.0,
    'antalyaspor': 1485.0,
    'çaykur rizespor': 1495.0,
    'rizespor': 1495.0,
    'samsunspor': 1520.0,
    'göztepe': 1510.0,
    'goztepe': 1510.0,
    'gaziantep': 1470.0,
    'konyaspor': 1475.0,
    'kayserispor': 1465.0,
    'eyüpspor': 1515.0,
    'eyupspor': 1515.0,
    'bodrum fk': 1440.0,
    'hatayspor': 1445.0,
    'adana demirspor': 1410.0,

    // Avrupa Devleri (Şampiyonlar Ligi / Avrupa Ligi)
    'real madrid': 2045.0,
    'manchester city': 2040.0,
    'bayern münchen': 1990.0,
    'bayern munich': 1990.0,
    'arsenal': 1985.0,
    'liverpool': 1995.0,
    'inter': 1970.0,
    'barcelona': 1975.0,
    'bayer leverkusen': 1950.0,
    'paris saint-germain': 1930.0,
    'psg': 1930.0,
    'atletico madrid': 1910.0,
    'borussia dortmund': 1895.0,
    'juventus': 1880.0,
    'milan': 1860.0,
    'atalanta': 1875.0,
    'chelsea': 1870.0,
    'aston villa': 1865.0,
    'tottenham': 1845.0,
    'newcastle': 1830.0,
    'manchester united': 1825.0,
    'roma': 1810.0,
    'lazio': 1805.0,
    'napoli': 1840.0,
    'sporting cp': 1850.0,
    'benfica': 1840.0,
    'porto': 1815.0,
    'ajax': 1750.0,
    'feyenoord': 1770.0,
    'psv': 1810.0,
  };
}
