import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/cache/cache_manager.dart';
import '../models/weather_pitch_condition.dart';

/// Canlı Stadyum Hava Durumu Bilgisi (Open-Meteo API)
class LiveWeatherData {
  final double temperature; // °C
  final double windSpeed; // km/s
  final int weatherCode;
  final String conditionLabel;
  final double goalMultiplier; // Ağır yağış ve rüzgarda gol beklentisi düşüşü
  final double foulMultiplier; // Kaygan zeminde faul ve kart artışı

  const LiveWeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.conditionLabel,
    required this.goalMultiplier,
    required this.foulMultiplier,
  });

  bool get isRainy => weatherCode >= 51 && weatherCode <= 67 || weatherCode >= 80 && weatherCode <= 82;
  bool get isSnowy => weatherCode >= 71 && weatherCode <= 77 || weatherCode >= 85 && weatherCode <= 86;
  bool get isWindy => windSpeed >= 28.0;

  WeatherCondition get toWeatherCondition {
    if (isSnowy) return WeatherCondition.snowy;
    if (isRainy) return WeatherCondition.rainy;
    if (isWindy) return WeatherCondition.windy;
    return WeatherCondition.clear;
  }

  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '🌤️';
    if (weatherCode <= 48) return '☁️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌦️';
    if (weatherCode <= 86) return '🌨️';
    if (weatherCode <= 99) return '⛈️';
    return '🌡️';
  }

  static const LiveWeatherData standardIdeal = LiveWeatherData(
    temperature: 20.0,
    windSpeed: 10.0,
    weatherCode: 0,
    conditionLabel: 'Açık / İdeal Koşul',
    goalMultiplier: 1.0,
    foulMultiplier: 1.0,
  );
}

/// Open-Meteo Tamamen Ücretsiz & Anahtarsız Canlı Hava Durumu Servisi
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Şehir ve Stadyum adlarına göre koordinat eşleme
  static final Map<String, (double lat, double lng)> _venueCoordinates = {
    'istanbul': (41.0082, 28.9784),
    'rams park': (41.1032, 28.9912),
    'şükrü saracoğlu': (40.9877, 29.0369),
    'ülker': (40.9877, 29.0369),
    'tüpraş': (41.0394, 29.0019),
    'beşiktaş park': (41.0394, 29.0019),
    'ankara': (39.9334, 32.8597),
    'eryaman': (39.9723, 32.6248),
    'izmir': (38.4237, 27.1428),
    'trabzon': (41.0027, 39.7168),
    'papara park': (40.9984, 39.6738),
    'konya': (37.8746, 32.4932),
    'samsun': (41.2867, 36.33),
    'gaziantep': (37.0662, 37.3833),
    'alanya': (36.5438, 31.9998),
    'diyarbakır': (37.9144, 40.2306),
    'erzurum': (39.9043, 41.2679),
    'sivas': (39.7505, 37.0150),
    'rize': (41.0255, 40.5177),
    'london': (51.5074, -0.1278),
    'madrid': (40.4168, -3.7038),
    'barcelona': (41.3851, 2.1734),
    'münchen': (48.1351, 11.5820),
    'milano': (45.4642, 9.1900),
    'paris': (48.8566, 2.3522),
  };

  /// Stadyum veya şehir adına göre anlık gerçek hava durumunu çeker
  static Future<LiveWeatherData> getLiveWeather(String? venueOrCity) async {
    if (venueOrCity == null || venueOrCity.trim().isEmpty) {
      return LiveWeatherData.standardIdeal;
    }

    final query = venueOrCity.toLowerCase().trim();
    (double lat, double lng)? coords;

    for (final entry in _venueCoordinates.entries) {
      if (query.contains(entry.key)) {
        coords = entry.value;
        break;
      }
    }

    // Varsayılan koordinat (İstanbul)
    coords ??= (41.0082, 28.9784);

    final cacheKey = 'weather_${coords.$1.toStringAsFixed(2)}_${coords.$2.toStringAsFixed(2)}';
    final cached = CacheManager.get(cacheKey, ttl: const Duration(hours: 1));
    if (cached is Map<String, dynamic>) {
      return _parseWeatherData(cached);
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=${coords.$1}&longitude=${coords.$2}&current_weather=true',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await CacheManager.put(cacheKey, data);
        return _parseWeatherData(data);
      }
    } catch (_) {
      // Ağ veya zaman aşımında güvenli varsayılan değer
    }

    return LiveWeatherData.standardIdeal;
  }

  static LiveWeatherData _parseWeatherData(Map<String, dynamic> data) {
    try {
      final current = data['current_weather'] as Map<String, dynamic>?;
      if (current == null) return LiveWeatherData.standardIdeal;

      final temp = (current['temperature'] as num?)?.toDouble() ?? 20.0;
      final wind = (current['windspeed'] as num?)?.toDouble() ?? 10.0;
      final code = (current['weathercode'] as num?)?.toInt() ?? 0;

      String label;
      double goalMul = 1.0;
      double foulMul = 1.0;

      if (code == 0) {
        label = 'Açık / Güneşli ($temp°C)';
      } else if (code <= 3) {
        label = 'Parçalı Bulutlu ($temp°C)';
      } else if (code >= 51 && code <= 67) {
        label = 'Yağmurlu ($temp°C, ${wind.toInt()} km/s)';
        goalMul = 0.93; // Ağır zeminde gol zorlaşır
        foulMul = 1.12; // Kayma ve kart artar
      } else if (code >= 71 && code <= 77) {
        label = 'Karlı / Ağır Zemin ($temp°C)';
        goalMul = 0.85;
        foulMul = 1.25;
      } else if (code >= 95) {
        label = 'Fırtınalı / Şiddetli Yağış ($temp°C)';
        goalMul = 0.82;
        foulMul = 1.30;
      } else {
        label = 'Bulutlu ($temp°C, ${wind.toInt()} km/s)';
      }

      if (wind >= 30.0) {
        goalMul *= 0.92;
        label += ' (Şiddetli Rüzgar)';
      }

      return LiveWeatherData(
        temperature: temp,
        windSpeed: wind,
        weatherCode: code,
        conditionLabel: label,
        goalMultiplier: (goalMul * 100).round() / 100,
        foulMultiplier: (foulMul * 100).round() / 100,
      );
    } catch (_) {
      return LiveWeatherData.standardIdeal;
    }
  }
}
