import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// GitHub Sürüm ve Güncelleme Bilgisi Modeli
class ReleaseInfo {
  final String tagName;
  final String title;
  final String changelog;
  final DateTime publishedAt;
  final String? windowsZipUrl;
  final String? androidApkUrl;
  final String? iosIpaUrl;

  ReleaseInfo({
    required this.tagName,
    required this.title,
    required this.changelog,
    required this.publishedAt,
    this.windowsZipUrl,
    this.androidApkUrl,
    this.iosIpaUrl,
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
      tagName: json['tag_name'] ?? 'latest',
      title: json['name'] ?? 'FOTTBOL Güncellemesi',
      changelog: json['body'] ?? 'Performans ve tahmin motoru iyileştirmeleri.',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      windowsZipUrl: winUrl,
      androidApkUrl: apkUrl,
      iosIpaUrl: ipaUrl,
    );
  }
}

/// GitHub Doğrudan Otomatik Güncelleme Servisi
class GitHubUpdateService {
  static const String repoOwner = 'hakanyavuz';
  static const String repoName = 'fottbol';
  static const String _prefKeyLastReleaseDate = 'fottbol_last_release_date';

  /// GitHub Releases API üzerinden en güncel sürümü kontrol eder
  static Future<ReleaseInfo?> checkForUpdates({bool isManual = false}) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final release = ReleaseInfo.fromJson(data);

      final prefs = await SharedPreferences.getInstance();
      final lastDateStr = prefs.getString(_prefKeyLastReleaseDate);

      if (isManual) {
        return release;
      }

      if (lastDateStr == null) {
        // İlk kullanım, mevcut tarihi kaydet
        await prefs.setString(_prefKeyLastReleaseDate, release.publishedAt.toIso8601String());
        return null;
      }

      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null && release.publishedAt.isAfter(lastDate)) {
        return release;
      }

      return null;
    } catch (e) {
      debugPrint('GitHub güncelleme kontrol hatası: $e');
      return null;
    }
  }

  /// Güncellemenin başarıyla uygulandığını kaydeder
  static Future<void> markUpdateApplied(DateTime publishedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastReleaseDate, publishedAt.toIso8601String());
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
      final updaterBatPath = '$tempDir\\fottbol_self_updater.bat';

      final batContent = '''
@echo off
echo FOTTBOL guncelleniyor, lutfen bekleyin...
timeout /t 2 /nobreak > nul
tar -xf "$zipFilePath" -C "$appDir"
del /f /q "$zipFilePath"
start "" "$currentExePath"
del /f /q "%~f0"
''';

      await File(updaterBatPath).writeAsString(batContent);
      await markUpdateApplied(release.publishedAt);

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
