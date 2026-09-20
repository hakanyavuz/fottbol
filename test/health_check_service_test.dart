import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/services/health_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('HealthCheckService & Circuit Breaker Testleri', () {
    test('ServiceHealthReport operasyonel durumu doğru tespit eder', () {
      final healthy = ServiceHealthReport(
        providerKey: 'espn',
        providerName: 'ESPN',
        status: ServiceHealthStatus.healthy,
        activeUrl: 'https://site.api.espn.com',
        latencyMs: 120,
        checkedAt: DateTime.now(),
      );

      final mirror = ServiceHealthReport(
        providerKey: 'sofascore',
        providerName: 'Sofascore',
        status: ServiceHealthStatus.mirrorActive,
        activeUrl: 'https://m.sofascore.com',
        latencyMs: 340,
        checkedAt: DateTime.now(),
      );

      final down = ServiceHealthReport(
        providerKey: 'broken',
        providerName: 'Broken Source',
        status: ServiceHealthStatus.down,
        activeUrl: 'https://broken.example.com',
        latencyMs: 3000,
        checkedAt: DateTime.now(),
      );

      expect(healthy.isOperational, isTrue);
      expect(mirror.isOperational, isTrue);
      expect(down.isOperational, isFalse);
    });

    test('getActiveUrl varsayılan birincil adrese güvenle döner', () {
      final url = HealthCheckService.getActiveUrl('espn');
      expect(url, contains('espn.com'));
    });
  });
}
