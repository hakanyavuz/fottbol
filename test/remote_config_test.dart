import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('RemoteConfigService Testleri', () {
    test('Varsayılan sağlayıcılar ESPN, Sofascore ve Club Elo içerir', () {
      final espn = RemoteConfigService.getProvider('espn');
      final sofa = RemoteConfigService.getProvider('sofascore');
      final elo = RemoteConfigService.getProvider('club_elo');

      expect(espn.enabled, isTrue);
      expect(espn.primaryUrl, contains('espn.com'));
      expect(sofa.enabled, isTrue);
      expect(sofa.primaryUrl, contains('sofascore.com'));
      expect(sofa.headers, containsPair('Accept', 'application/json'));
      expect(elo.primaryUrl, contains('clubelo.com'));
    });

    test('Bilinmeyen sağlayıcı çağrıldığında varsayılan güvenli boş yapı döner', () {
      final unknown = RemoteConfigService.getProvider('non_existent_provider');
      expect(unknown.name, equals('non_existent_provider'));
      expect(unknown.primaryUrl, isEmpty);
      expect(unknown.mirrors, isEmpty);
    });
  });
}
