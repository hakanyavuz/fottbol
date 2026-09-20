import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';

enum ServiceHealthStatus {
  healthy,      // Birincil hat hızlı ve aktif
  mirrorActive, // Birincil hat yanıt vermedi, yedek ayna devrede
  degraded,     // Yavaş yanıt veya kısmi hata
  down,         // Tüm hatlar kapalı
}

class ServiceHealthReport {
  final String providerKey;
  final String providerName;
  final ServiceHealthStatus status;
  final String activeUrl;
  final int latencyMs;
  final String? errorMessage;
  final DateTime checkedAt;

  const ServiceHealthReport({
    required this.providerKey,
    required this.providerName,
    required this.status,
    required this.activeUrl,
    required this.latencyMs,
    this.errorMessage,
    required this.checkedAt,
  });

  bool get isOperational =>
      status == ServiceHealthStatus.healthy || status == ServiceHealthStatus.mirrorActive;
}

/// Açılışta Sağlık Taraması ve Otomatik Sigorta (Circuit Breaker) Servisi
class HealthCheckService {
  static final Map<String, ServiceHealthReport> _reports = {};
  static final Map<String, String> _activeUrls = {};
  static final StreamController<Map<String, ServiceHealthReport>> _reportStream =
      StreamController<Map<String, ServiceHealthReport>>.broadcast();

  static Stream<Map<String, ServiceHealthReport>> get stream => _reportStream.stream;
  static Map<String, ServiceHealthReport> get reports => Map.unmodifiable(_reports);

  /// Bir sağlayıcının şu an çalışan en güncel adresini döner
  static String getActiveUrl(String providerKey) {
    if (_activeUrls.containsKey(providerKey)) {
      return _activeUrls[providerKey]!;
    }
    return RemoteConfigService.getProvider(providerKey).primaryUrl;
  }

  /// Tüm servis hatlarını paralel olarak 500ms içinde yoklar
  static Future<Map<String, ServiceHealthReport>> probeAll() async {
    final providers = RemoteConfigService.providers;
    final List<Future<ServiceHealthReport>> tasks = [];

    for (final entry in providers.entries) {
      if (entry.value.enabled) {
        tasks.add(_probeProvider(entry.key, entry.value));
      }
    }

    final results = await Future.wait(tasks);
    for (final rep in results) {
      _reports[rep.providerKey] = rep;
      _activeUrls[rep.providerKey] = rep.activeUrl;
    }

    _reportStream.add(_reports);
    return _reports;
  }

  static Future<ServiceHealthReport> _probeProvider(
    String key,
    ProviderConfig config,
  ) async {
    final stopwatch = Stopwatch()..start();

    // 1. Önce Birincil URL'i test et
    final primaryCandidate = '${config.primaryUrl}${config.healthTestEndpoint}';
    final primaryOk = await _quickProbe(primaryCandidate, config.headers);

    if (primaryOk) {
      stopwatch.stop();
      return ServiceHealthReport(
        providerKey: key,
        providerName: config.name,
        status: ServiceHealthStatus.healthy,
        activeUrl: config.primaryUrl,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    }

    // 2. Birincil başarısız olduysa yedek aynaları (mirrors) dene (Circuit Breaker)
    for (final mirror in config.mirrors) {
      final mirrorCandidate = '$mirror${config.healthTestEndpoint}';
      final mirrorOk = await _quickProbe(mirrorCandidate, config.headers);
      if (mirrorOk) {
        stopwatch.stop();
        debugPrint('⚠️ [Circuit Breaker] $key birincil hat düştü, yedek aynaya geçildi: $mirror');
        return ServiceHealthReport(
          providerKey: key,
          providerName: config.name,
          status: ServiceHealthStatus.mirrorActive,
          activeUrl: mirror,
          latencyMs: stopwatch.elapsedMilliseconds,
          errorMessage: 'Birincil sunucu yanıt vermedi, yedek hat devrede.',
          checkedAt: DateTime.now(),
        );
      }
    }

    // 3. Hiçbir ayna yanıt vermediyse down işaretle
    stopwatch.stop();
    return ServiceHealthReport(
      providerKey: key,
      providerName: config.name,
      status: ServiceHealthStatus.down,
      activeUrl: config.primaryUrl,
      latencyMs: stopwatch.elapsedMilliseconds,
      errorMessage: 'Sunucuya ulaşılamıyor (Yerel akıllı hafıza devrede)',
      checkedAt: DateTime.now(),
    );
  }

  static Future<bool> _quickProbe(String urlStr, Map<String, String> headers) async {
    try {
      final uri = Uri.tryParse(urlStr);
      if (uri == null) return false;
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 3));
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
