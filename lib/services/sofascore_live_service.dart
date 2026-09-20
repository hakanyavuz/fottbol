import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/utils/team_name_matcher.dart';
import '../models/odds_comparison.dart';
import 'health_check_service.dart';
import 'remote_config_service.dart';

/// Sofascore Canlı İstatistik ve Gerçek xG Modeli
class LiveMatchStats {
  final double? homeXg;
  final double? awayXg;
  final int? homeShots;
  final int? awayShots;
  final int? homeShotsOnTarget;
  final int? awayShotsOnTarget;
  final int? homePossession;
  final int? awayPossession;
  final int? homeCorners;
  final int? awayCorners;

  const LiveMatchStats({
    this.homeXg,
    this.awayXg,
    this.homeShots,
    this.awayShots,
    this.homeShotsOnTarget,
    this.awayShotsOnTarget,
    this.homePossession,
    this.awayPossession,
    this.homeCorners,
    this.awayCorners,
  });

  bool get hasXg => homeXg != null && awayXg != null;
}

/// Kotasız ve Ücretsiz Sofascore Canlı Oran ve xG Servisi
class SofascoreLiveService {
  static final Map<String, int> _eventIdCache = {};

  static Map<String, String> get _headers {
    final cfg = RemoteConfigService.getProvider('sofascore');
    return cfg.headers;
  }

  static String get _baseUrl => HealthCheckService.getActiveUrl('sofascore');

  /// Seçili tarihteki maçlar arasından takımlara uyan Sofascore event ID'sini bulur
  static Future<int?> findEventId({
    required String homeTeam,
    required String awayTeam,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T').first;
    final cacheKey = '$dateStr:${homeTeam.toLowerCase()}:${awayTeam.toLowerCase()}';

    if (_eventIdCache.containsKey(cacheKey)) {
      return _eventIdCache[cacheKey];
    }

    try {
      final uri = Uri.parse('$_baseUrl/sport/football/scheduled-events/$dateStr');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final events = data['events'] as List? ?? [];

        for (final ev in events) {
          if (ev is Map) {
            final hName = (ev['homeTeam']?['name'] ?? '').toString();
            final aName = (ev['awayTeam']?['name'] ?? '').toString();
            final evId = (ev['id'] as num?)?.toInt();

            if (evId != null &&
                TeamNameMatcher.matches(hName, homeTeam) &&
                TeamNameMatcher.matches(aName, awayTeam)) {
              _eventIdCache[cacheKey] = evId;
              return evId;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Sofascore event bulma hatası: $e');
    }

    return null;
  }

  /// Bir maçın canlı/açılış gerçek piyasa bahis oranlarını kotasız çeker
  static Future<BookmakerOdds?> getLiveOddsForMatch({
    required String homeTeam,
    required String awayTeam,
    DateTime? date,
  }) async {
    final eventId = await findEventId(homeTeam: homeTeam, awayTeam: awayTeam, date: date);
    if (eventId == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/event/$eventId/odds/1/all');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final markets = data['markets'] as List? ?? [];

        double? homeOdd;
        double? drawOdd;
        double? awayOdd;
        double? over25;
        double? under25;

        for (final m in markets) {
          if (m is Map) {
            final marketName = (m['marketName'] ?? '').toString().toLowerCase();
            final choices = m['choices'] as List? ?? [];

            // 1X2 Maç Sonucu
            if (marketName == 'full time' || marketName == '1x2' || marketName.contains('match result')) {
              for (final c in choices) {
                if (c is Map) {
                  final name = (c['name'] ?? '').toString().toLowerCase();
                  final frac = (c['fractionalValue'] ?? '').toString();
                  final decimal = _parseFractionalOrDecimal(c['initialFractionalValue'] ?? frac, c['change']);
                  if (name == '1' || name == 'home') homeOdd = decimal;
                  if (name == 'x' || name == 'draw') drawOdd = decimal;
                  if (name == '2' || name == 'away') awayOdd = decimal;
                }
              }
            }

            // 2.5 Alt / Üst
            if (marketName.contains('total') || marketName.contains('over/under 2.5')) {
              for (final c in choices) {
                if (c is Map) {
                  final name = (c['name'] ?? '').toString().toLowerCase();
                  final decimal = _parseFractionalOrDecimal(c['fractionalValue'], c['change']);
                  if (name.contains('over') || name.contains('üst')) over25 = decimal;
                  if (name.contains('under') || name.contains('alt')) under25 = decimal;
                }
              }
            }
          }
        }

        if (homeOdd != null && drawOdd != null && awayOdd != null) {
          return BookmakerOdds(
            bookmakerName: 'Piyasa (Sofascore Live Odds)',
            homeOdd: homeOdd,
            drawOdd: drawOdd,
            awayOdd: awayOdd,
            over25Odd: over25,
            under25Odd: under25,
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Sofascore oran çekme hatası: $e');
    }

    return null;
  }

  /// Maçın canlı xG ve şut istatistiklerini çeker
  static Future<LiveMatchStats?> getLiveStatsForMatch({
    required String homeTeam,
    required String awayTeam,
    DateTime? date,
  }) async {
    final eventId = await findEventId(homeTeam: homeTeam, awayTeam: awayTeam, date: date);
    if (eventId == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/event/$eventId/statistics');
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final statistics = data['statistics'] as List? ?? [];
        if (statistics.isEmpty) return null;

        final allPeriods = statistics.firstWhere(
          (s) => s['period'] == 'ALL',
          orElse: () => statistics.first,
        );

        final groups = allPeriods['groups'] as List? ?? [];
        double? hXg;
        double? aXg;
        int? hShots, aShots, hTarget, aTarget, hPoss, aPoss, hCorn, aCorn;

        for (final g in groups) {
          final items = g['statisticsItems'] as List? ?? [];
          for (final it in items) {
            final name = (it['name'] ?? '').toString().toLowerCase();
            final hVal = it['home'];
            final aVal = it['away'];

            if (name == 'expected goals' || name == 'xg') {
              hXg = double.tryParse(hVal.toString());
              aXg = double.tryParse(aVal.toString());
            } else if (name == 'total shots' || name == 'shots') {
              hShots = int.tryParse(hVal.toString());
              aShots = int.tryParse(aVal.toString());
            } else if (name == 'shots on target') {
              hTarget = int.tryParse(hVal.toString());
              aTarget = int.tryParse(aVal.toString());
            } else if (name == 'ball possession') {
              hPoss = int.tryParse(hVal.toString().replaceAll('%', ''));
              aPoss = int.tryParse(aVal.toString().replaceAll('%', ''));
            } else if (name == 'corner kicks') {
              hCorn = int.tryParse(hVal.toString());
              aCorn = int.tryParse(aVal.toString());
            }
          }
        }

        return LiveMatchStats(
          homeXg: hXg,
          awayXg: aXg,
          homeShots: hShots,
          awayShots: aShots,
          homeShotsOnTarget: hTarget,
          awayShotsOnTarget: aTarget,
          homePossession: hPoss,
          awayPossession: aPoss,
          homeCorners: hCorn,
          awayCorners: aCorn,
        );
      }
    } catch (e) {
      debugPrint('Sofascore istatistik çekme hatası: $e');
    }

    return null;
  }

  static double _parseFractionalOrDecimal(dynamic val, dynamic change) {
    if (val == null) return 2.0;
    final str = val.toString().trim();
    if (str.contains('/')) {
      final parts = str.split('/');
      final num = double.tryParse(parts[0]) ?? 1.0;
      final den = double.tryParse(parts[1]) ?? 1.0;
      return (1.0 + (num / den)).clamp(1.05, 50.0);
    }
    return (double.tryParse(str) ?? 2.0).clamp(1.05, 50.0);
  }
}
