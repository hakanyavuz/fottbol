import 'package:flutter/material.dart';

/// API kotası aşıldığında veya önbellek fallback'i kullanıldığında gösterilen uyarı banner'ı
class QuotaWarningBanner extends StatelessWidget {
  final String message;
  final bool isUsingCache;
  final VoidCallback? onRetry;

  const QuotaWarningBanner({
    super.key,
    required this.message,
    this.isUsingCache = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Kota Bilgilendirmesi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUsingCache
                      ? '$message (12 saatlik yerel önbellekteki veriler gösteriliyor).'
                      : message,
                  style: const TextStyle(fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: Colors.amber),
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
