import 'package:flutter_test/flutter_test.dart';
import 'package:fottbol_prediction/core/constants/app_version.dart';
import 'package:fottbol_prediction/services/github_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('GitHubUpdateService & ReleaseInfo Model Testleri', () {
    test('ReleaseInfo JSON ayrıştırma Windows, Android ve iOS varlıklarını doğru tespit eder', () {
      final json = {
        'id': 12345,
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

      expect(release.id, equals(12345));
      expect(release.tagName, equals('v1.0.5'));
      expect(release.title, equals('FOTTBOL v1.0.5 Güncellemesi'));
      expect(release.windowsZipUrl, contains('FOTTBOL_Windows_x64.zip'));
      expect(release.androidApkUrl, contains('app-release.apk'));
      expect(release.iosIpaUrl, contains('FOTTBOL_iOS_unsigned.ipa'));
      expect(release.changelog, contains('Kadro ve xG'));
    });

    test('Uygulanan güncelleme detayları SharedPreferences üzerine kaydedilir', () async {
      final release = ReleaseInfo(
        id: 99887,
        tagName: 'v1.0.2',
        title: 'FOTTBOL 1.0.2',
        changelog: 'İyileştirmeler',
        publishedAt: DateTime.parse('2026-09-20T18:30:00Z'),
      );

      await GitHubUpdateService.markUpdateApplied(release);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fottbol_installed_version'), equals('v1.0.2'));
      expect(prefs.getString('fottbol_installed_release_date'), equals('2026-09-20T18:30:00.000Z'));
      expect(prefs.getInt('fottbol_installed_release_id'), equals(99887));
    });

    test('AppVersion.compareVersions semantik sürüm karşılaştırmasını doğru yapar', () {
      expect(AppVersion.compareVersions('v1.0.2', '1.0.1') > 0, isTrue);
      expect(AppVersion.compareVersions('1.0.1', 'v1.0.1'), equals(0));
      expect(AppVersion.compareVersions('1.0.0', '1.0.1') < 0, isTrue);
      expect(AppVersion.compareVersions('v2.0.0', 'v1.9.9') > 0, isTrue);
      expect(AppVersion.compareVersions('1.0.1.1', '1.0.1') > 0, isTrue);
    });

    test('UpdateCheckResult durumları doğru taşır', () {
      final resultNoUpdate = UpdateCheckResult(
        hasUpdate: false,
        currentVersion: '1.0.1',
        latestVersion: '1.0.1',
        message: 'Uygulamanız en son sürümde (1.0.1). Yeni bir güncelleme bulunmuyor.',
      );
      expect(resultNoUpdate.hasUpdate, isFalse);
      expect(resultNoUpdate.release, isNull);

      final mockRelease = ReleaseInfo(
        id: 1,
        tagName: 'v1.0.2',
        title: 'Yeni Sürüm',
        changelog: 'Değişiklikler',
        publishedAt: DateTime.now(),
      );
      final resultWithUpdate = UpdateCheckResult(
        hasUpdate: true,
        release: mockRelease,
        currentVersion: '1.0.1',
        latestVersion: 'v1.0.2',
        message: 'Yeni bir FOTTBOL güncellemesi mevcut (v1.0.2).',
      );
      expect(resultWithUpdate.hasUpdate, isTrue);
      expect(resultWithUpdate.release, isNotNull);
      expect(resultWithUpdate.latestVersion, equals('v1.0.2'));
    });
  });
}
