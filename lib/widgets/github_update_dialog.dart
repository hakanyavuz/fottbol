import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

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
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(isWindows ? 'Şimdi Otomatik Güncelle' : 'Tamam'),
            onPressed: isWindows ? _startUpdate : () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}
