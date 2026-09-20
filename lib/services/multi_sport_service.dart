import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/cache/cache_manager.dart';
import '../models/fixture.dart';
import '../models/sport_type.dart';
import 'football_offline_repository.dart';
import 'real_sports_live_service.dart';

/// Çoklu Spor API Servisi (Futbol, Voleybol, Basketbol)
class MultiSportService {
  final String apiKey;

  MultiSportService({required this.apiKey});

  bool get hasKey => apiKey.trim().isNotEmpty;

  Map<String, String> get _headers => {
        'x-apisports-key': apiKey.trim(),
      };

  /// Spor dalına göre baz URL
  String _baseUrlForSport(SportType sport) {
    switch (sport) {
      case SportType.soccer:
        return 'https://v3.football.api-sports.io';
      case SportType.volleyball:
        return 'https://v1.volleyball.api-sports.io';
      case SportType.basketball:
        return 'https://v1.basketball.api-sports.io';
      case SportType.tennis:
        return 'https://v3.football.api-sports.io'; // Tenis için fallback
    }
  }

  /// Belirli bir spor dalı ve tarihteki tüm maçları canlı çeker
  Future<List<Fixture>> getMatchesByDate({
    required SportType sport,
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    // 1. Futbol için öncelikle gerçek ESPN Live servisini sorgula (tüm ligler, ücretsiz & kotasız)
    if (sport == SportType.soccer) {
      try {
        final realFixtures = await RealSportsLiveService.getLiveFixtures(date: date);
        if (realFixtures.isNotEmpty) {
          return realFixtures;
        }
      } catch (e) {
        debugPrint('Gerçek fikstür çekme hatası (MultiSportService): $e');
      }
    }

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (!hasKey) {
      if (sport == SportType.soccer) {
        return FootballOfflineRepository.getOfficialFixturesByDate(date);
      }
      return const [];
    }

    final cacheKey = 'sport_${sport.name}_$dateStr';
    if (!forceRefresh) {
      final cached = CacheManager.get(cacheKey, ttl: const Duration(minutes: 30));
      if (cached is List) {
        return _parseSportResponse(sport, cached);
      }
    }

    try {
      final baseUrl = _baseUrlForSport(sport);
      final endpoint = sport == SportType.soccer ? '/fixtures' : '/games';
      final uri = Uri.parse('$baseUrl$endpoint?date=$dateStr&timezone=Europe/Istanbul');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final responseList = body['response'] as List? ?? [];

        await CacheManager.put(cacheKey, responseList);
        final list = _parseSportResponse(sport, responseList);

        if (list.isNotEmpty) {
          list.sort((a, b) => (a.date ?? DateTime(2100)).compareTo(b.date ?? DateTime(2100)));
          return list;
        }
      }
    } catch (_) {
      // Hata durumunda çevrimdışı yedeğe başvur
    }

    if (sport == SportType.soccer) {
      return FootballOfflineRepository.getOfficialFixturesByDate(date);
    }
    return const [];
  }

  List<Fixture> _parseSportResponse(SportType sport, List responseList) {
    final result = <Fixture>[];
    for (final item in responseList) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        if (sport == SportType.soccer) {
          result.add(Fixture.fromApiFootball(map));
        } else if (sport == SportType.volleyball) {
          result.add(Fixture.fromVolleyballApi(map));
        } else if (sport == SportType.basketball) {
          result.add(Fixture.fromBasketballApi(map));
        }
      }
    }
    return result;
  }
}
