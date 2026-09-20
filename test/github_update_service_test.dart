import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/services/github_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('GitHubUpdateService & ReleaseInfo Model Testleri', () {
    test('ReleaseInfo JSON ayrıştırma Windows, Android ve iOS varlıklarını doğru tespit eder', () {
      final json = {
        'tag_name': 'v1.0.5',
        'name': 'FOTTBOL v1.0.5 Güncellemesi',
        'body': 'Kadro ve xG Poisson motoru güncellemeleri.',
        'published_at': '2026-09-20T18:00:00Z',
        'assets': [
          {
            'name': 'FOTTBOL_Windows_x64.zip',
            'browser_download_url': 'https://github.com/hakanyavuz/fottbol/releases/download/v1.0.5/FOTTBOL_Windows_x64.zip',
          },
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/hakanyavuz/fottbol/releases/download/v1.0.5/app-release.apk',
          },
          {
            'name': 'FOTTBOL_iOS_unsigned.ipa',
            'browser_download_url': 'https://github.com/hakanyavuz/fottbol/releases/download/v1.0.5/FOTTBOL_iOS_unsigned.ipa',
          },
        ],
      };

      final release = ReleaseInfo.fromJson(json);

      expect(release.tagName, equals('v1.0.5'));
      expect(release.title, equals('FOTTBOL v1.0.5 Güncellemesi'));
      expect(release.windowsZipUrl, contains('FOTTBOL_Windows_x64.zip'));
      expect(release.androidApkUrl, contains('app-release.apk'));
      expect(release.iosIpaUrl, contains('FOTTBOL_iOS_unsigned.ipa'));
      expect(release.changelog, contains('Kadro ve xG'));
    });

    test('Uygulanan güncelleme tarihi SharedPreferences üzerine kaydedilir', () async {
      final testDate = DateTime.parse('2026-09-20T18:30:00Z');
      await GitHubUpdateService.markUpdateApplied(testDate);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('fottbol_last_release_date');
      expect(saved, equals(testDate.toIso8601String()));
    });
  });
}
