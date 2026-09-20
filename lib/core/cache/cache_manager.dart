import 'package:hive_flutter/hive_flutter.dart';

/// Hive tabanlı 12 saatlik TTL (Time-To-Live) süreli önbellek yöneticisi
class CacheManager {
  static const String _boxName = 'football_api_cache';
  static const Duration defaultTtl = Duration(hours: 12);
  static Box? _box;

  /// Hive başlatma ve kutuyu açma
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// Açık önbellek kutusu; Hive başlatılmamışsa (test ortamı veya açılış hatası)
  /// null döner ve önbellek sessizce devre dışı kalır — veri yüklemesi engellenmez.
  static Box? get _safeBox {
    if (_box != null && _box!.isOpen) return _box;
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      return _box;
    }
    return null;
  }

  /// Hive iç içe map'leri `Map<dynamic, dynamic>` olarak geri döndürür.
  /// JSON ayrıştırıcıları `Map<String, dynamic>` beklediği için okunan veri
  /// derinlemesine normalize edilir (aksi halde önbellekten okumada tip hatası olur).
  static dynamic normalize(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), normalize(val)));
    }
    if (value is List) {
      return value.map(normalize).toList();
    }
    return value;
  }

  /// Veriyi geçerli zaman damgasıyla kaydeder
  static Future<void> put(String key, dynamic data) async {
    final payload = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _safeBox?.put(key, payload);
  }

  /// 12 saatlik süre dolmamışsa veriyi getirir, dolmuşsa null döner
  static dynamic get(String key, {Duration ttl = defaultTtl}) {
    final entry = _safeBox?.get(key);
    if (entry == null || entry is! Map) return null;

    final int? timestamp = (entry['timestamp'] as num?)?.toInt();
    if (timestamp == null) return null;

    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (age > ttl) {
      return null; // Süresi dolmuş
    }

    return normalize(entry['data']);
  }

  /// Süresi dolmuş olsa bile eski veriyi getirir (Kota aşımı veya çevrimdışı fallback)
  static dynamic getStale(String key) {
    final entry = _safeBox?.get(key);
    if (entry == null || entry is! Map) return null;
    return normalize(entry['data']);
  }

  /// Önbellekte geçerli bir veri var mı?
  static bool hasValidCache(String key, {Duration ttl = defaultTtl}) {
    return get(key, ttl: ttl) != null;
  }

  /// Önbellekte (eski de olsa) herhangi bir veri var mı?
  static bool hasAnyCache(String key) {
    return _safeBox?.containsKey(key) ?? false;
  }

  /// Belirli bir anahtarı siler
  static Future<void> remove(String key) async {
    await _safeBox?.delete(key);
  }

  /// Çok eski kayıtları temizler (kutunun sınırsız büyümesini engeller).
  ///
  /// TTL'i dolmuş kayıtlar çevrimdışı / kota aşımı senaryosunda `getStale` ile
  /// hâlâ kullanıldığı için burada çok daha uzun bir saklama süresi uygulanır.
  static Future<void> purgeExpired({
    Duration retention = const Duration(days: 30),
  }) async {
    final box = _safeBox;
    if (box == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <dynamic>[];

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry is! Map) continue;
      final timestamp = (entry['timestamp'] as num?)?.toInt();
      if (timestamp == null || now - timestamp > retention.inMilliseconds) {
        expiredKeys.add(key);
      }
    }

    await box.deleteAll(expiredKeys);
  }

  /// Tüm önbelleği temizler
  static Future<void> clearAll() async {
    await _safeBox?.clear();
  }
}
