import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_version.dart';

/// GitHub Sürüm Bilgisi Modeli
class ReleaseInfo {
  final int id;
  final String tagName;
  final String title;
  final String changelog;
  final DateTime publishedAt;
  final String? windowsZipUrl;
  final String? androidApkUrl;
  final String? iosIpaUrl;
  final String? htmlUrl;

  ReleaseInfo({
    required this.id,
    required this.tagName,
    required this.title,
    required this.changelog,
    required this.publishedAt,
    this.windowsZipUrl,
    this.androidApkUrl,
    this.iosIpaUrl,
    this.htmlUrl,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    String? winUrl;
    String? apkUrl;
    String? ipaUrl;

    final assets = json['assets'] as List? ?? [];
    for (final asset in assets) {
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final url = (asset['browser_download_url'] ?? '').toString();

      if (name.endsWith('.zip') || name.contains('windows')) {
        winUrl = url;
      } else if (name.endsWith('.apk')) {
        apkUrl = url;
      } else if (name.endsWith('.ipa')) {
        ipaUrl = url;
      }
    }

    return ReleaseInfo(
      id: json['id'] ?? 0,
      tagName: json['tag_name'] ?? 'latest',
      title: json['name'] ?? 'FOTTBOL Güncellemesi',
      changelog: json['body'] ?? 'Performans ve tahmin motoru iyileştirmeleri.',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      windowsZipUrl: winUrl,
      androidApkUrl: apkUrl,
      iosIpaUrl: ipaUrl,
      htmlUrl: json['html_url']?.toString(),
    );
  }
}

/// Güncelleme Kontrol Çıktısı
class UpdateCheckResult {
  final bool hasUpdate;
  final ReleaseInfo? release;
  final String currentVersion;
  final String latestVersion;
  final String message;

  UpdateCheckResult({
    required this.hasUpdate,
    this.release,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
  });
}

/// GitHub Doğrudan Otomatik Güncelleme Servisi
class GitHubUpdateService {
  static const String repoOwner = 'hakanyavuz';
  static const String repoName = 'fottbol';
  static const String _prefKeyInstalledVersion = 'fottbol_installed_version';
  static const String _prefKeyInstalledReleaseDate = 'fottbol_installed_release_date';
  static const String _prefKeyInstalledReleaseId = 'fottbol_installed_release_id';

  /// GitHub Releases API üzerinden sürüm karşılaştırması yapar
  static Future<UpdateCheckResult> checkForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final String currentVersion = prefs.getString(_prefKeyInstalledVersion) ?? AppVersion.version;
    final String? installedDateStr = prefs.getString(_prefKeyInstalledReleaseDate);
    final int? installedReleaseId = prefs.getInt(_prefKeyInstalledReleaseId);

    final DateTime installedDate = installedDateStr != null
        ? (DateTime.tryParse(installedDateStr) ?? AppVersion.buildDate)
        : AppVersion.buildDate;

    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          message: 'GitHub sunucusuna erişilemedi (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body);
      final release = ReleaseInfo.fromJson(data);

      // Sürüm ve tarih karşılaştırması:
      // 1. Tag sürüm numarası mevcut sürümden büyük mü? (örn: v1.0.2 > 1.0.1)
      String remoteVersionStr = release.tagName;
      if (remoteVersionStr.toLowerCase() == 'latest' || !remoteVersionStr.contains(RegExp(r'\d'))) {
        final match = RegExp(r'v?(\d+\.\d+(\.\d+)?)').firstMatch(release.title) ??
            RegExp(r'v?(\d+\.\d+(\.\d+)?)').firstMatch(release.changelog);
        if (match != null) {
          remoteVersionStr = match.group(0)!;
        }
      }

      final versionComparison = AppVersion.compareVersions(remoteVersionStr, currentVersion);

      // 2. Yayınlanma tarihi cihazdaki tarihten yeni mi? (UTC bazlı)
      final isNewerByDate = release.publishedAt.toUtc().isAfter(installedDate.toUtc());

      // 3. Release ID farklı/yeni mi?
      final isNewerReleaseId = installedReleaseId != null && release.id != installedReleaseId;

      final bool isTrulyNewer = versionComparison > 0 ||
          (versionComparison == 0 && (isNewerByDate || isNewerReleaseId));

      final displayVersion = remoteVersionStr.isNotEmpty && remoteVersionStr != 'latest'
          ? remoteVersionStr
          : release.tagName;

      if (isTrulyNewer) {
        return UpdateCheckResult(
          hasUpdate: true,
          release: release,
          currentVersion: currentVersion,
          latestVersion: displayVersion,
          message: 'Yeni bir FOTTBOL güncellemesi mevcut ($displayVersion).',
        );
      } else {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: displayVersion,
          message: 'Uygulamanız en son sürümde ($currentVersion). Yeni bir güncelleme bulunmuyor.',
        );
      }
    } catch (e) {
      debugPrint('GitHub güncelleme kontrol hatası: $e');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        message: 'Güncelleme kontrolü sırasında bağlantı hatası: $e',
      );
    }
  }

  /// Güncellemenin başarıyla uygulandığını kaydeder
  static Future<void> markUpdateApplied(ReleaseInfo release) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyInstalledVersion, release.tagName);
    await prefs.setString(_prefKeyInstalledReleaseDate, release.publishedAt.toIso8601String());
    await prefs.setInt(_prefKeyInstalledReleaseId, release.id);
  }

  /// Windows uygulamasını doğrudan GitHub'dan indirir ve kendisini güncelleyip yeniden başlatır
  static Future<bool> performWindowsAutoUpdate(
    ReleaseInfo release, {
    void Function(double progress, String status)? onProgress,
  }) async {
    if (kIsWeb || !Platform.isWindows) return false;
    final downloadUrl = release.windowsZipUrl;
    if (downloadUrl == null) return false;

    try {
      onProgress?.call(0.1, 'İndirme bağlantısı kuruluyor...');
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) return false;

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = Directory.systemTemp.path;
      final zipFilePath = '$tempDir\\fottbol_update.zip';
      final zipFile = File(zipFilePath);
      final sink = zipFile.openWrite();

      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          final p = 0.1 + (receivedBytes / totalBytes) * 0.7;
          onProgress?.call(p, 'İndiriliyor: %${(p * 100).toInt()}');
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      onProgress?.call(0.85, 'Güncelleme betiği hazırlanıyor...');

      final currentExePath = Platform.resolvedExecutable;
      final appDir = File(currentExePath).parent.path;
      final exeName = File(currentExePath).uri.pathSegments.last;
      final updaterBatPath = '$tempDir\\fottbol_self_updater.bat';

      final batContent = '''
@echo off
echo FOTTBOL guncelleniyor, lutfen bekleyin...
timeout /t 2 /nobreak > nul
taskkill /f /im "$exeName" >nul 2>&1
timeout /t 1 /nobreak > nul
tar -xf "$zipFilePath" -C "$appDir"
del /f /q "$zipFilePath"
start "" "$currentExePath"
del /f /q "%~f0"
''';

      await File(updaterBatPath).writeAsString(batContent);
      await markUpdateApplied(release);

      onProgress?.call(1.0, 'Uygulama yeniden başlatılıyor...');

      // Güncelleyici betiğini bağımsız süreç olarak çalıştır
      await Process.start('cmd.exe', ['/c', updaterBatPath], mode: ProcessStartMode.detached);

      // Mevcut uygulamadan çıkış yap (betik yeni dosyaları açabilsin)
      exit(0);
    } catch (e) {
      debugPrint('Windows otomatik güncelleme hatası: $e');
      return false;
    }
  }
}
