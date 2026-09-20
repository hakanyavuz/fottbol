import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Spor veri kaynakları için dinamik yapılandırma modeli
class ProviderConfig {
  final String name;
  final bool enabled;
  final String primaryUrl;
  final List<String> mirrors;
  final String healthTestEndpoint;
  final Map<String, String> headers;

  const ProviderConfig({
    required this.name,
    required this.enabled,
    required this.primaryUrl,
    required this.mirrors,
    required this.healthTestEndpoint,
    required this.headers,
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as Map? ?? {};
    final headers = <String, String>{};
    rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());

    final rawMirrors = json['mirrors'] as List? ?? [];
    final mirrors = rawMirrors.map((e) => e.toString()).toList();

    return ProviderConfig(
      name: (json['name'] ?? 'Bilinmeyen Kaynak').toString(),
      enabled: json['enabled'] == true,
      primaryUrl: (json['primary_url'] ?? '').toString(),
      mirrors: mirrors,
      healthTestEndpoint: (json['health_test_endpoint'] ?? '').toString(),
      headers: headers,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'enabled': enabled,
    'primary_url': primaryUrl,
    'mirrors': mirrors,
    'health_test_endpoint': healthTestEndpoint,
    'headers': headers,
  };
}

/// GitHub Remote Config Servisi
///
/// Spor veri sitelerinin linkleri değiştiğinde veya yeni ayna (mirror)
/// adresleri eklendiğinde istemciyi yeniden derlemeye gerek kalmadan
/// çalışma zamanında (runtime) konfigürasyonu günceller.
class RemoteConfigService {
  static const String _remoteConfigUrl =
      'https://raw.githubusercontent.com/hakanyavuz/fottbol/main/config/sources_config.json';
  static const String _prefKeyCachedConfig = 'fottbol_cached_sources_config';
  static const String _prefKeyLastFetched = 'fottbol_sources_config_last_fetched';

  static Map<String, ProviderConfig> _providers = _defaultProviders;
  static bool _isInitialized = false;

  static Map<String, ProviderConfig> get providers => _providers;
  static bool get isInitialized => _isInitialized;

  /// Belirli bir sağlayıcının konfigürasyonunu getirir
  static ProviderConfig getProvider(String key) {
    return _providers[key] ?? _defaultProviders[key] ?? ProviderConfig(
      name: key,
      enabled: true,
      primaryUrl: '',
      mirrors: const [],
      healthTestEndpoint: '',
      headers: const {},
    );
  }

  /// Uzaktan yapılandırmayı başlatır ve önbellekten/GitHub'dan yükler
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Önce yerel önbellekteki ayarları yükle (anında açılış)
    final cachedJson = prefs.getString(_prefKeyCachedConfig);
    if (cachedJson != null) {
      try {
        _applyJsonConfig(jsonDecode(cachedJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Önbellekteki remote config okunamadı: $e');
      }
    }

    _isInitialized = true;

    // 2. Arka planda GitHub üzerinden en güncel dosyayı çek
    _fetchRemoteConfigSilently(prefs);
  }

  static Future<void> _fetchRemoteConfigSilently(SharedPreferences prefs) async {
    try {
      final response = await http.get(
        Uri.parse(_remoteConfigUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _applyJsonConfig(data);
        await prefs.setString(_prefKeyCachedConfig, response.body);
        await prefs.setString(_prefKeyLastFetched, DateTime.now().toIso8601String());
        debugPrint('GitHub Remote Config başarıyla güncellendi.');
      }
    } catch (e) {
      debugPrint('GitHub Remote Config çekilemedi (yerel yedek devrede): $e');
    }
  }

  static void _applyJsonConfig(Map<String, dynamic> data) {
    final providersJson = data['providers'] as Map? ?? {};
    final map = <String, ProviderConfig>{};
    providersJson.forEach((k, v) {
      if (v is Map) {
        map[k.toString()] = ProviderConfig.fromJson(Map<String, dynamic>.from(v));
      }
    });
    if (map.isNotEmpty) {
      _providers = map;
    }
  }

  /// Varsayılan yerel konfigürasyon (Çevrimdışı veya ilk kurulum güvencesi)
  static final Map<String, ProviderConfig> _defaultProviders = {
    'espn': const ProviderConfig(
      name: 'ESPN Live Soccer',
      enabled: true,
      primaryUrl: 'https://site.api.espn.com/apis/site/v2/sports/soccer',
      mirrors: ['https://site.web.api.espn.com/apis/site/v2/sports/soccer'],
      healthTestEndpoint: '/tur.1/scoreboard?dates=20260920',
      headers: {'Accept': 'application/json'},
    ),
    'sofascore': const ProviderConfig(
      name: 'Sofascore Intelligence',
      enabled: true,
      primaryUrl: 'https://api.sofascore.com/api/v1',
      mirrors: [
        'https://api-v1.sofascore.app/api/v1',
        'https://m.sofascore.com/api/v1',
      ],
      healthTestEndpoint: '/sport/football/scheduled-events/2026-09-20',
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        'Referer': 'https://www.sofascore.com/',
        'Accept': 'application/json',
      },
    ),
    'club_elo': const ProviderConfig(
      name: 'Club Elo Global Rankings',
      enabled: true,
      primaryUrl: 'http://api.clubelo.com',
      mirrors: ['https://api.clubelo.com'],
      healthTestEndpoint: '/2026-09-20',
      headers: {'Accept': '*/*'},
    ),
  };
}
