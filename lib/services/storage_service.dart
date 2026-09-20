import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/prediction_result.dart';
import '../models/coupon_slip.dart';

/// SharedPreferences ile tahmin geçmişi ve kullanıcı ayarlarını yönetir
class StorageService {
  static const String _keyPredictions = 'saved_predictions';
  static const String _keySavedCoupons = 'saved_coupons';
  static const String _keyApiFootballKey = 'api_football_key';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyIsDarkMode = 'is_dark_mode';

  /// Tahmini yerel hafızaya kaydeder (aynı id varsa kopya oluşturmaz, günceller)
  static Future<void> savePrediction(PredictionResult prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keyPredictions) ?? [];

    // Aynı tahminin (örn. AI analizi yenilendiğinde) tekrar eklenmesini önle
    list.removeWhere((item) {
      try {
        return json.decode(item)['id'] == prediction.id;
      } catch (_) {
        return false;
      }
    });

    // JSON olarak başa ekle (en yeni en üstte)
    list.insert(0, json.encode(prediction.toJson()));
    
    // Maksimum 50 tahmin sakla
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    
    await prefs.setStringList(_keyPredictions, list);
  }

  /// Mevcut bir tahmin kaydını sırasını bozmadan günceller (örn. gerçek sonuç eklendiğinde)
  static Future<void> updatePrediction(PredictionResult prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keyPredictions) ?? [];

    final index = list.indexWhere((item) {
      try {
        return json.decode(item)['id'] == prediction.id;
      } catch (_) {
        return false;
      }
    });

    if (index == -1) {
      await savePrediction(prediction);
      return;
    }

    list[index] = json.encode(prediction.toJson());
    await prefs.setStringList(_keyPredictions, list);
  }

  /// Kayıtlı geçmiş tahminleri listeler
  static Future<List<PredictionResult>> getSavedPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keyPredictions) ?? [];

    return list.map((item) {
      try {
        final data = json.decode(item);
        return PredictionResult.fromJson(data);
      } catch (_) {
        return null;
      }
    }).whereType<PredictionResult>().toList();
  }

  /// Tahmin geçmişini temizler
  static Future<void> clearPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPredictions);
  }

  /// Kuponu yerel hafızaya kaydeder
  static Future<void> saveCoupon(CouponSlip slip) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keySavedCoupons) ?? [];

    list.removeWhere((item) {
      try {
        final data = json.decode(item);
        return data['id'] == slip.id ||
               (data['title'] == slip.title &&
                data['date']?.toString().split('T').first == slip.date.toIso8601String().split('T').first);
      } catch (_) {
        return false;
      }
    });

    list.insert(0, json.encode(slip.toJson()));
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    await prefs.setStringList(_keySavedCoupons, list);
  }

  /// Kayıtlı geçmiş kuponları getirir
  static Future<List<CouponSlip>> getSavedCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keySavedCoupons) ?? [];
    final slips = <CouponSlip>[];
    for (final raw in list) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        slips.add(CouponSlip.fromJson(map));
      } catch (_) {}
    }
    return slips;
  }

  /// Tek bir kuponu siler
  static Future<void> deleteCoupon(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_keySavedCoupons) ?? [];
    list.removeWhere((item) {
      try {
        return json.decode(item)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_keySavedCoupons, list);
  }

  /// Kupon geçmişini temizler
  static Future<void> clearSavedCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedCoupons);
  }

  // API Anahtarlarını Kaydet / Getir
  static Future<void> saveApiKeys({
    String? geminiKey,
    String? apiFootballKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (geminiKey != null) await prefs.setString(_keyGeminiApiKey, geminiKey);
    if (apiFootballKey != null) await prefs.setString(_keyApiFootballKey, apiFootballKey);
  }

  /// Kayıtlı anahtarlar: 'apiFootball' (API-Football), 'gemini'
  static Future<Map<String, String>> getApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApiFootball = prefs.getString(_keyApiFootballKey)?.trim();
    final savedGemini = prefs.getString(_keyGeminiApiKey)?.trim();

    return {
      'apiFootball': (savedApiFootball != null && savedApiFootball.isNotEmpty)
          ? savedApiFootball
          : ApiConstants.defaultApiFootballKey,
      'gemini': (savedGemini != null && savedGemini.isNotEmpty)
          ? savedGemini
          : ApiConstants.defaultGeminiApiKey,
    };
  }

  // Tema Tercihi
  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, isDark);
  }

  static Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsDarkMode) ?? true; // Varsayılan Koyu Tema
  }

  // Kullanıcı Tercihleri ve Ayarları
  static const String _keyGoalAlert = 'goal_alert_enabled';
  static const String _keyRedCardAlert = 'red_card_alert_enabled';
  static const String _keyFavoriteOnlyAlerts = 'favorite_only_alerts';
  static const String _keyRefreshInterval = 'refresh_interval_seconds';
  static const String _keyRiskProfile = 'risk_profile';
  static const String _keyDefaultLeague = 'default_league';

  static Future<bool> getGoalAlertEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyGoalAlert) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveGoalAlertEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGoalAlert, enabled);
    } catch (_) {}
  }

  static Future<bool> getRedCardAlertEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRedCardAlert) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveRedCardAlertEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRedCardAlert, enabled);
    } catch (_) {}
  }

  static Future<bool> getFavoriteOnlyAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFavoriteOnlyAlerts) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveFavoriteOnlyAlerts(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFavoriteOnlyAlerts, enabled);
    } catch (_) {}
  }

  static Future<int> getRefreshIntervalSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyRefreshInterval) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  static Future<void> saveRefreshIntervalSeconds(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyRefreshInterval, seconds);
    } catch (_) {}
  }

  static Future<String> getRiskProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRiskProfile) ?? 'Dengeli';
    } catch (_) {
      return 'Dengeli';
    }
  }

  static Future<void> saveRiskProfile(String profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRiskProfile, profile);
    } catch (_) {}
  }

  static Future<String> getDefaultLeague() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDefaultLeague) ?? 'Trendyol Süper Lig';
    } catch (_) {
      return 'Trendyol Süper Lig';
    }
  }

  static Future<void> saveDefaultLeague(String league) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDefaultLeague, league);
    } catch (_) {}
  }
}
