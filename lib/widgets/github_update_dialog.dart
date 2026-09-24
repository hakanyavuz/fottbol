import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../services/github_update_service.dart';

class GitHubUpdateDialog extends StatefulWidget {
  final ReleaseInfo release;

  const GitHubUpdateDialog({super.key, required this.release});

  static Future<void> show(BuildContext context, ReleaseInfo release) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GitHubUpdateDialog(release: release),
    );
  }

  @override
  State<GitHubUpdateDialog> createState() => _GitHubUpdateDialogState();
}

class _GitHubUpdateDialogState extends State<GitHubUpdateDialog> {
  bool _isUpdating = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startUpdate() async {
    setState(() {
      _isUpdating = true;
      _progress = 0.05;
      _statusText = 'Güncelleme başlatılıyor...';
    });

    final success = await GitHubUpdateService.performWindowsAutoUpdate(
      widget.release,
      onProgress: (p, s) {
        if (mounted) {
          setState(() {
            _progress = p;
            _statusText = s;
          });
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Güncelleme indirilirken bir sorun oluştu. Lütfen internetinizi kontrol edin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _launchExternalUrl(String url, {String? snackMessage}) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Bağlantı açılamadı');
      }
      if (mounted && snackMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            backgroundColor: AppColors.darkCard,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme bağlantısı açılamadı: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    String actionButtonLabel;
    IconData actionButtonIcon;
    VoidCallback? actionButtonCallback;

    if (isWindows) {
      actionButtonLabel = 'Şimdi Güncelle';
      actionButtonIcon = Icons.system_update_alt_rounded;
      actionButtonCallback = _startUpdate;
    } else if (isAndroid) {
      actionButtonLabel = 'APK İndir ve Kur';
      actionButtonIcon = Icons.android_rounded;
      actionButtonCallback = () {
        Navigator.of(context).pop();
        final apkUrl = widget.release.androidApkUrl ??
            widget.release.htmlUrl ??
            'https://github.com/hakanyavuz/fottbol/releases';
        _launchExternalUrl(
          apkUrl,
          snackMessage: '📥 Android APK indirmesi başlatıldı. İndirilen dosyaya dokunarak güncelleyebilirsiniz.',
        );
      };
    } else if (isIOS) {
      actionButtonLabel = 'Sürüm Sayfasına Git';
      actionButtonIcon = Icons.apple_rounded;
      actionButtonCallback = () {
        Navigator.of(context).pop();
        final pageUrl = widget.release.htmlUrl ??
            widget.release.iosIpaUrl ??
            'https://github.com/hakanyavuz/fottbol/releases';
        _launchExternalUrl(
          pageUrl,
          snackMessage: '🍎 Safari üzerinden güncelleme sayfası açılıyor.',
        );
      };
    } else {
      actionButtonLabel = 'Sürümü İncele';
      actionButtonIcon = Icons.open_in_browser_rounded;
      actionButtonCallback = () {
        Navigator.of(context).pop();
        final pageUrl = widget.release.htmlUrl ?? 'https://github.com/hakanyavuz/fottbol/releases';
        _launchExternalUrl(pageUrl);
      };
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update_alt_rounded, color: AppColors.premiumGold, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Yeni FOTTBOL Güncellemesi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Sürüm: ${widget.release.tagName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.premiumGold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.release.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.release.changelog,
                style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  isWindows
                      ? Icons.desktop_windows_rounded
                      : isAndroid
                          ? Icons.android_rounded
                          : isIOS
                              ? Icons.apple_rounded
                              : Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.premiumGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isWindows
                        ? 'Windows: Otomatik indirilip yeniden başlatılacaktır.'
                        : isAndroid
                            ? 'Android: APK indirilecek, verileriniz korunarak güncellenecektir.'
                            : isIOS
                                ? 'iOS: Safari sürüm sayfasına yönlendirileceksiniz.'
                                : 'Bulut sürüm sayfasına yönlendirileceksiniz.',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Yeni sürüm bulundu. Şimdi güncellemek istiyor musunuz?',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          if (_isUpdating) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress, color: AppColors.premiumGold),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isUpdating) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premiumGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(actionButtonIcon, size: 18),
            label: Text(actionButtonLabel),
            onPressed: actionButtonCallback,
          ),
        ],
      ],
    );
  }
}
